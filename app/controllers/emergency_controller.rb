# frozen_string_literal: true

class EmergencyController < ApplicationController
  # Public endpoint - no authentication required
  # This controller uses the public layout by default

  layout "public"

  # GET /emergency
  # Shows the emergency stop form
  def show
  end

  # POST /emergency
  # Validates email + recovery code and stops delivery
  def confirm
    email = params[:email]&.downcase&.strip
    recovery_code = params[:recovery_code]

    if email.blank? || recovery_code.blank?
      flash.now[:alert] = "请输入邮箱地址和恢复码。"
      return render :show, status: :unprocessable_entity
    end

    user = User.find_by(email: email)

    # Constant-time failure to prevent user enumeration
    unless user
      # Simulate work to prevent timing attacks
      Digest::SHA256.hexdigest(recovery_code.to_s)
      sleep(rand(0.1..0.3))
      flash.now[:alert] = "邮箱或恢复码无效。"
      return render :show, status: :unprocessable_entity
    end

    new_recovery_code = user.use_recovery_code!(recovery_code)

    if new_recovery_code
      # Log the emergency stop
      AuditLog.log(
        action: "emergency_stop",
        user: user,
        actor_type: "user",
        request: request,
        metadata: { state_before: user.state_before_last_save }
      )

      render :success
    else
      flash.now[:alert] = "邮箱或恢复码无效。"
      render :show, status: :unprocessable_entity
    end
  end
end
