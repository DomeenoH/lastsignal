# frozen_string_literal: true

class TrustedContactMailer < ApplicationMailer
  def ping(contact, raw_token)
    @contact = contact
    @user = contact.user
    @confirm_url = trusted_contact_url(token: raw_token)
    @app_name = AppConfig.smtp_from_name

    mail(
      to: contact.email,
      subject: "确认 #{@user.display_name_or_email} 是否平安"
    )
  end

  def ping_notice(user, contact)
    @user = user
    @contact = contact
    @app_name = AppConfig.smtp_from_name

    mail(
      to: user.email,
      subject: "可信联系人提醒已发送"
    )
  end

  def confirmation_notice(user, contact)
    @user = user
    @contact = contact
    @paused_until = contact.paused_until
    @app_name = AppConfig.smtp_from_name

    mail(
      to: user.email,
      subject: "可信联系人确认你平安"
    )
  end
end
