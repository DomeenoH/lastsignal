# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :require_authentication
  before_action :prevent_delivered_actions, only: [ :acknowledge_recovery_code, :pause, :unpause ]

  def show
    @user = current_user
    @recipients_count = current_user.recipients.accepted.count
    @messages_count = current_user.messages.count
    @has_active_messages = current_user.has_active_messages?

    # Check if we need to show the recovery code
    @show_recovery_code = session[:show_recovery_code]
  end

  # POST /dashboard/acknowledge_recovery_code
  def acknowledge_recovery_code
    current_user.mark_recovery_code_viewed!
    session.delete(:show_recovery_code)
    flash[:notice] = "应急恢复码已保存，请妥善保管！"
    redirect_to dashboard_path
  end

  # POST /dashboard/pause
  def pause
    if current_user.pause!
      AuditLog.log(
        action: "checkin_paused",
        user: current_user,
        actor_type: "user",
        request: request
      )
      flash[:notice] = "已暂停签到。在恢复之前不会发送提醒或自动发送消息。"
    else
      flash[:alert] = "当前状态无法暂停签到。"
    end
    redirect_to dashboard_path
  end

  # POST /dashboard/unpause
  def unpause
    if current_user.unpause!
      AuditLog.log(
        action: "checkin_resumed",
        user: current_user,
        actor_type: "user",
        request: request
      )
    flash[:notice] = "签到已恢复。已为你安排下一次签到。"
    else
      flash[:alert] = "当前状态无法恢复签到。"
    end
    redirect_to dashboard_path
  end
end
