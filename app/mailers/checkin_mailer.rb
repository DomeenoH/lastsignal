# frozen_string_literal: true

class CheckinMailer < ApplicationMailer
  def reminder(user, raw_token, attempt_number:, attempt_total:)
    @user = user
    @checkin_url = confirm_checkin_url(token: raw_token)
    @next_checkin_at = user.next_checkin_at
    @attempt_number = attempt_number
    @attempt_total = attempt_total
    @next_attempt_at = user.next_attempt_due_at
    @app_name = AppConfig.smtp_from_name

    mail(
      to: user.email,
      subject: "来自 #{@app_name} 的签到提醒"
    )
  end

  def grace_period_warning(user, raw_token, attempt_number:, attempt_total:)
    @user = user
    @attempt_number = attempt_number
    @attempt_total = attempt_total
    @next_attempt_at = user.next_attempt_due_at
    @checkin_url = confirm_checkin_url(token: raw_token)
    @login_url = login_url
    @app_name = AppConfig.smtp_from_name

    mail(
      to: user.email,
      subject: "需要确认：你错过了 #{@app_name} 签到"
    )
  end

  def cooldown_warning(user, raw_token, attempt_number:, attempt_total:)
    @user = user
    @checkin_url = confirm_checkin_url(token: raw_token)
    @attempt_number = attempt_number
    @attempt_total = attempt_total
    @delivery_due_at = user.delivery_due_at
    @app_name = AppConfig.smtp_from_name

    mail(
      to: user.email,
      subject: "紧急：你的 #{@app_name} 消息即将发送"
    )
  end

  def delivery_notice(user, recipient_emails)
    @user = user
    @delivered_at = user.delivered_at
    @recipient_emails = recipient_emails
    @app_name = AppConfig.smtp_from_name

    mail(
      to: user.email,
      subject: "你的 #{@app_name} 消息已发送给收件人"
    )
  end
end
