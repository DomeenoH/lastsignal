# <img src="https://lastsignal.app/logo-mark.svg" alt="失联告警 · LastSignal" width="50" height="50" align="absmiddle" /> 失联告警 · LastSignal

[![Ruby](https://img.shields.io/badge/Ruby-3.4-red.svg)](https://www.ruby-lang.org/) [![Rails](https://img.shields.io/badge/Rails-8-red.svg)](https://rubyonrails.org/) [![Database](https://img.shields.io/badge/Database-SQLite-blue.svg)](https://www.sqlite.org/) [![Crypto](https://img.shields.io/badge/Crypto-libsodium-black.svg)](https://libsodium.gitbook.io/doc/) [![Deploy](https://img.shields.io/badge/Deploy-Kamal-success.svg)](https://kamal-deploy.org/) [![License: BSL 1.1](https://img.shields.io/badge/License-BSL%201.1-blue.svg)](https://mariadb.com/bsl11/)

失联告警 · LastSignal 是一个可自托管、以邮件为核心的“遗嘱式触发”服务。你可以为关心的人撰写加密消息。如果你停止响应签到邮件，失联告警 · LastSignal 会自动投递这些消息。

官网：[lastsignal.app](https://lastsignal.app)

## 📬 邮件优先流程（快速概览）

1) 系统通过邮件定期提醒你签到。
2) 若错过签到，会按固定间隔发送提醒。
3) 最后一次提醒会触发可信联系人提醒（如已配置）。
4) 若仍无响应，系统将通过邮件投递消息。

## 🔒 安全模型

- **端到端加密** - 服务器永远无法看到明文消息
- **零知识架构** - 连运营者也无法读取你的数据
- **现代密码学** - Argon2id (256MB) + XChaCha20-Poly1305 + X25519
- **可审计** - 你可以自行审计代码

**⚠️ 重要：必须使用强口令**

失联告警 · LastSignal 使用 **服务器生成的 KDF 盐**（与收件人公钥一起存储）。这是一个有意的架构权衡，用于支持从口令进行确定性密钥再生成，但会引入特定风险：
**如果攻击者获得数据库访问权**（如服务器被攻破、数据泄露、恶意运营者或执法请求），他们可获得盐并对收件人口令进行**离线暴力破解**，且不受速率限制。

**[完整安全文档 →](https://lastsignal.app/security)**

## ⏱️ 默认时间设置（天）

所有时间设置可在“账户设置”中按用户配置。

| 设置 | 默认值 |
| --- | --- |
| 签到间隔 | 30 天 |
| 提醒次数 | 3（包含首次提醒） |
| 提醒间隔 | 7 天 |
| 可信联系人暂停 | 15 天 |

示例时间线：

| 事件 | 日期 | 状态 |
| --- | --- | --- |
| 上次签到 | 4月1日 | 🟢 活跃 |
| 提醒 #1 | 5月1日 | 🟢 活跃 |
| 提醒 #2 | 5月8日 | 🟡 宽限期 |
| 提醒 #3（最终 + 可信联系人提醒） | 5月15日 | 🟠 冷却期 |
| 投递（若无响应） | 5月22日 | 🔴 已投递 |

若可信联系人在 5月16日确认：

| 事件 | 日期 | 状态 |
| --- | --- | --- |
| 投递暂停至 | 5月31日 | 🟠 冷却期（暂停） |
| 新的可信联系人提醒 | 5月31日 | 🟠 冷却期 |
| 若用户签到或可信联系人再次确认则投递 | 6月7日 | 🔴 已投递 |

**收件人级别延迟**：你还可以为每位收件人设置延迟（天）。这会延后投递后收件人可解密的时间——适合分批开放或时间敏感的信息。

## 🧪 开发

本项目会启动本地开发栈，并通过 [letter_opener](https://github.com/ryanb/letter_opener) 在浏览器中打开邮件。

### 环境要求

- Ruby 3.4+
- SQLite 3（sqlite3 gem >= 2.1）
- Node.js（用于 Tailwind）

Ubuntu 新环境示例：

```bash
apt-get update && apt-get install -y \
  git \
  ruby \
  bundler \
  libyaml-dev
```

### 启动开发栈

```bash
git clone https://github.com/giovantenne/lastsignal.git
cd lastsignal
bundle install
cp .env.example .env
bin/setup
bin/dev
```

然后打开 http://localhost:3000 并请求一个登录链接。 
邮件将通过 `letter_opener` 自动在浏览器中打开。

### Docker（使用 Mailhog 快速试用）

如果你不想本地安装 Ruby，可以使用包含 [Mailhog](https://github.com/mailhog/MailHog) 的开发 compose 栈：

```bash
docker compose -f docker-compose.dev.yml up --build
```

然后打开：

- 应用：http://localhost:3000
- Mailhog 收件箱：http://localhost:8025

### E2EE 演示流程（开发 / Docker）

用于快速测试完整的签到 → 投递流程，无需等待数天。

前置条件：

1) 启动开发栈。
2) 登录、添加收件人、使用口令接受邀请，并为该收件人创建消息。
   若没有与已接受收件人关联的消息，将不会触发签到。

开发命令：

```bash
bin/rails demo:checkins:status EMAIL=you@example.com
bin/rails demo:checkins:advance EMAIL=you@example.com
bin/rails demo:checkins:advance_days EMAIL=you@example.com DAYS=7
bin/rails demo:checkins:deliver EMAIL=you@example.com
```

Docker 命令：

```bash
docker compose -f docker-compose.dev.yml exec app bin/rails demo:checkins:status EMAIL=you@example.com
docker compose -f docker-compose.dev.yml exec app bin/rails demo:checkins:advance EMAIL=you@example.com
docker compose -f docker-compose.dev.yml exec app bin/rails demo:checkins:advance_days EMAIL=you@example.com DAYS=7
docker compose -f docker-compose.dev.yml exec app bin/rails demo:checkins:deliver EMAIL=you@example.com
```

说明：

- 每次 `advance` 会发送序列中的下一封邮件（提醒 → 宽限 → 冷却 → 投递）。
- `advance_days` 用于模拟时间流逝 N 天并运行签到任务。
- 直接投递：`bin/rails demo:checkins:deliver EMAIL=you@example.com`
- 邮件会在 letter_opener（开发）或 Mailhog（Docker）中打开。
- 演示工具仅在 development/test 下运行。

### 测试

```bash
# 全量测试
bin/test

# 指定测试
bin/test spec/models/user_spec.rb
bin/test spec/jobs/process_checkins_job_spec.rb
bin/test spec/requests/auth_spec.rb
```

## 🚀 生产环境部署（Kamal）

你只需要 Docker、SSH 访问权限，以及可靠的 SMTP 服务提供商。

Kamal 文档：https://kamal-deploy.org

### 1) 准备服务器

- 准备一台 Linux 主机（推荐 Ubuntu 22.04+）
- 安装 Docker 并开放 80/443 端口
- 将 DNS 指向服务器 IP（A/AAAA 记录）

### 2) 配置环境

复制模板并填写必要值：

```bash
cp .env.production.example .env.production
```

必须设置：

- `KAMAL_*`（镜像、镜像仓库、服务器、域名）
- `APP_BASE_URL` 和 `APP_HOST`
- `SMTP_*`（邮件服务商凭据）
- `ALLOWED_EMAILS`（可选私有实例白名单）

若没有 master key，可执行：

```bash
bin/rails credentials:edit
```

### 3) 部署

```bash
bin/kamal setup
bin/kamal deploy
```

### 4) 准备数据库

```bash
bin/kamal app exec --interactive --reuse "bin/rails db:prepare"
bin/kamal app exec --interactive --reuse "bin/rails db:prepare DATABASE=cache"
bin/kamal app exec --interactive --reuse "bin/rails db:prepare DATABASE=queue"
```

### 5) 验证

```bash
bin/kamal logs
```

健康检查：`https://YOUR_DOMAIN/up`

## 📮 邮件送达清单

邮件投递对失联告警 · LastSignal 至关重要。如果 SMTP 配置错误，消息可能无法送达。

大多数事务邮件服务商（如 Postmark、SendGrid 等）会引导你完成配置并提供所需 DNS 记录与细节。

- **SPF**：授权 SMTP 服务商代表你的域名发信
- **DKIM**：启用 DKIM 签名并添加 DNS 记录
- **DMARC**：先从 `p=none` 开始，再逐步收紧到 `quarantine` 或 `reject`
- **发件地址**：使用你控制的域名（与 `SMTP_FROM_EMAIL` 一致）

## 💾 存储备份

默认部署会将 SQLite 数据库与 Active Storage 文件存储在 Docker 卷 `lastsignal_storage` 中。请定期备份。

备份：

```bash
docker run --rm -v lastsignal_storage:/data -v "$PWD":/backup alpine \
  sh -c "cd /data && tar -czf /backup/lastsignal_storage.tgz ."
```

恢复：

```bash
docker run --rm -v lastsignal_storage:/data -v "$PWD":/backup alpine \
  sh -c "cd /data && tar -xzf /backup/lastsignal_storage.tgz"
```

## ⚙️ 默认设置

时间、限流与加密默认值位于 `config/initializers/app_config.rb`。

## 🤝 贡献

欢迎贡献！请先开 issue 讨论变更。

## 📄 许可证

本项目采用 Business Source License 1.1（BSL 1.1）。商业使用和以托管服务形式提供该软件需事先获得书面许可。到 2031-01-23 许可证将变更为 MIT。

详情见 [LICENSE](LICENSE)。

## ⚠️ 免责声明

失联告警 · LastSignal 按“现状”提供，不提供任何明示或暗示担保。作者仅提供源代码，不代表你托管、运营或监控服务器。所有邮件投递均由你自托管的实例和所选 SMTP 服务商完成。

使用本项目即表示你对配置、安全、备份、内容、收件人、合规义务以及任何投递或未投递后果承担全部责任。作者不对任何损害、数据丢失、错过或过早投递、滥用或其他结果承担责任，无论原因是漏洞、配置错误、第三方故障或运营失误。

失联告警 · LastSignal 不能替代遗嘱、信托、授权委托书或任何其他法律文书。它不具备法律效力，也不应被用来转移权利、财产或义务。如需法律确定性，请咨询合格律师并使用适当的法律文件。

## 🧡 捐赠

如果你觉得 **失联告警 · LastSignal** 有帮助并希望支持其开发，可以通过比特币捐赠：

`bc1qt6z0e5ttcjx0cnwjdl8mua2srt0lamah5lnnvm`

如果你想支持本次中文汉化工作，也可以捐赠给汉化者：

`bc1q7tk4y8dsm0yy89xrc3vph9u8n324dnz7kj8t8q`

捐赠将用于持续维护、安全审计和项目长期发展。谢谢支持 🙏
