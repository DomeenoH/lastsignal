# frozen_string_literal: true

class AuthController < ApplicationController
  before_action :redirect_if_authenticated, only: [ :new, :create, :verify ]

  # GET /auth/login
  def new
  end

  # POST /auth/magic_link
  def create
    email = params[:email]&.downcase&.strip

    if email.present? && email.match?(URI::MailTo::EMAIL_REGEXP)
      unless AppConfig.allowlisted_email?(email)
        flash[:alert] = "此实例为私有部署，你的邮箱未获授权。"
        return redirect_to login_path
      end

      # Find or create user
      user = User.find_or_create_by!(email: email)

      # Generate magic link token
      token_record, raw_token = MagicLinkToken.generate_for(user, request: request)

      # Send magic link email
      AuthMailer.magic_link(user, raw_token).deliver_later

      AuditLog.log(
        action: "login_requested",
        user: user,
        metadata: {},
        request: request
      )

      AuditLog.log(
        action: "magic_link_sent",
        user: user,
        actor_type: "system",
        metadata: {},
        request: request
      )

      flash[:notice] = "请查收登录链接邮件。链接将在 #{AppConfig.magic_link_ttl_minutes} 分钟后过期。"
    else
      flash[:alert] = "请输入有效的邮箱地址。"
    end

    redirect_to login_path
  end

  # GET /auth/verify/:token
  def verify
    raw_token = params[:token]
    token = MagicLinkToken.find_and_verify(raw_token)

    if token
      unless AppConfig.allowlisted_email?(token.user.email)
        flash[:alert] = "此实例为私有部署，你的邮箱未获授权。"
        return redirect_to login_path
      end

      # Mark token as used (single-use)
      token.mark_used!

      # Create session
      session[:user_id] = token.user_id
      session[:created_at] = Time.current.to_i

      # Treat login as a check-in
      token.user.confirm_checkin!

      AuditLog.log(
        action: "login_success",
        user: token.user,
        metadata: {},
        request: request
      )

      # Check if user needs to see their recovery code
      if !token.user.recovery_code_viewed?
        # Generate a fresh code and store in session for display
        session[:show_recovery_code] = token.user.generate_recovery_code!
        redirect_to dashboard_path
      else
        flash[:notice] = "你已成功登录。"
        redirect_to dashboard_path
      end
    else
      flash[:alert] = "登录链接无效或已过期，请重新申请。"
      redirect_to login_path
    end
  end

  # DELETE /auth/logout
  def destroy
    user = current_user

    session.delete(:user_id)
    session.delete(:created_at)

    AuditLog.log(
      action: "logout",
      user: user,
      metadata: {},
      request: request
    ) if user

    flash[:notice] = "你已退出登录。"
    redirect_to login_path
  end
end
