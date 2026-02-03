# frozen_string_literal: true

class RecipientMailer < ApplicationMailer
  def invite(recipient, raw_token)
    @recipient = recipient
    @sender = recipient.user
    @invite_url = accept_invite_url(token: raw_token)
    @expires_in_days = AppConfig.invite_token_ttl_days
    @app_name = AppConfig.smtp_from_name

    mail(
      to: recipient.email,
      subject: "来自 #{@sender.display_name_or_email} 的邀请：在 #{@app_name} 接收消息"
    )
  end

  def delivery(recipient, raw_token, available_count, delayed_message_recipients = [])
    @recipient = recipient
    @sender = recipient.user
    @delivery_url = delivery_url(token: raw_token)
    @available_count = available_count
    @delayed_message_recipients = delayed_message_recipients
    @total_count = available_count + delayed_message_recipients.count
    @app_name = AppConfig.smtp_from_name

    mail(
      to: recipient.email,
      subject: "你在 #{@app_name} 上有 #{@total_count} 条消息等待查看"
    )
  end

  # Notify the sender that a recipient has accepted their invite
  def accepted_notice(recipient)
    @recipient = recipient
    @sender = recipient.user
    @app_name = AppConfig.smtp_from_name
    @accepted_at = recipient.accepted_at

    mail(
      to: @sender.email,
      subject: "#{@recipient.display_name} 已完成设置，可以接收消息"
    )
  end
end
