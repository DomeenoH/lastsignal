# frozen_string_literal: true

class TrustedContactsController < ApplicationController
  layout "public"

  # GET /trusted_contact/:token
  def show
    @trusted_contact = TrustedContact.find_by_token(params[:token])

    if @trusted_contact.nil?
      AuditLog.log(
        action: "trusted_contact_token_invalid",
        actor_type: "trusted_contact",
        metadata: { reason: "not_found" },
        request: request
      )
      flash[:alert] = "可信联系人链接无效或已过期。"
      redirect_to login_path
      return
    end

    @user = @trusted_contact.user
  end

  # POST /trusted_contact/:token/confirm
  def confirm
    trusted_contact = TrustedContact.find_by_token(params[:token])

    if trusted_contact.nil?
      AuditLog.log(
        action: "trusted_contact_token_invalid",
        actor_type: "trusted_contact",
        metadata: { reason: "not_found" },
        request: request
      )
      flash[:alert] = "可信联系人链接无效或已过期。"
      redirect_to login_path
      return
    end

    trusted_contact.confirm!

    AuditLog.log(
      action: "trusted_contact_pause_set",
      user: trusted_contact.user,
      actor_type: "trusted_contact",
      metadata: { trusted_contact_id: trusted_contact.id, paused_until: trusted_contact.paused_until&.iso8601 },
      request: request
    )

    AuditLog.log(
      action: "trusted_contact_confirmed",
      user: trusted_contact.user,
      actor_type: "trusted_contact",
      metadata: { trusted_contact_id: trusted_contact.id, paused_until: trusted_contact.paused_until&.iso8601 },
      request: request
    )

    TrustedContactMailer.confirmation_notice(trusted_contact.user, trusted_contact).deliver_later

    AuditLog.log(
      action: "trusted_contact_confirmation_notice_sent",
      user: trusted_contact.user,
      actor_type: "system",
      metadata: { trusted_contact_id: trusted_contact.id }
    )
    @trusted_contact = trusted_contact
    @user = trusted_contact.user
    render :success
  end
end
