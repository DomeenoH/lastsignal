# frozen_string_literal: true

require "csv"

class AuditLogCsv
  HEADER = [ "时间戳", "操作", "元数据" ].freeze
  ACTION_LABELS = {
    "login_requested" => "请求登录",
    "login_success" => "登录成功",
    "logout" => "退出登录",
    "recipient_invited" => "邀请收件人",
    "recipient_accepted" => "收件人已接受",
    "message_created" => "创建消息",
    "message_updated" => "更新消息",
    "message_deleted" => "删除消息",
    "state_to_grace" => "进入提醒阶段",
    "state_to_cooldown" => "进入最终提醒",
    "state_to_delivered" => "进入发送完成",
    "checkin_confirmed" => "签到确认",
    "checkin_paused" => "暂停签到",
    "checkin_resumed" => "恢复签到",
    "checkin_reminder_sent" => "发送签到提醒",
    "grace_warning_sent" => "发送提醒",
    "cooldown_warning_sent" => "发送最终提醒",
    "delivery_notice_sent" => "发送通知",
    "emergency_stop" => "紧急停止",
    "delivery_link_opened" => "打开阅读链接",
    "trusted_contact_ping_sent" => "发送可信联系人提醒",
    "trusted_contact_ping_notice_sent" => "发送可信联系人提醒通知",
    "trusted_contact_pause_set" => "设置可信联系人暂停",
    "trusted_contact_confirmed" => "可信联系人已确认",
    "trusted_contact_confirmation_notice_sent" => "发送可信联系人确认通知",
    "trusted_contact_token_invalid" => "可信联系人令牌无效",
    "magic_link_sent" => "发送登录链接",
    "recipient_invite_sent" => "发送收件人邀请",
    "recipient_delivery_sent" => "发送收件人消息",
    "message_decrypted" => "消息已查看",
    "account_updated" => "账户已更新",
    "account_deleted" => "账户已删除",
    "checkin_resumed_for_messages" => "因消息恢复签到",
    "checkin_token_invalid" => "签到令牌无效",
    "delivery_token_invalid" => "阅读链接无效",
    "invite_token_invalid" => "邀请令牌无效"
  }.freeze

  def initialize(audit_logs)
    @audit_logs = audit_logs
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      csv << HEADER
      @audit_logs.find_each do |log|
        csv << [
          log.created_at&.iso8601,
          ACTION_LABELS[log.action] || log.action,
          log.metadata.presence || ""
        ]
      end
    end
  end
end
