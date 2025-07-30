# Xray Reality VLESS 一键部署脚本

该项目提供基于 **Docker Compose** 的一键部署脚本，用于快速搭建 **Xray (Reality + VLESS + XTLS Vision)** 代理服务。

通过此脚本，你可以快速完成：
- 自动生成 Reality 私钥、公钥
- 自动生成 UUID、ShortID
- 自动创建配置文件 `config.json`
- 自动生成 `docker-compose.yml`
- 自动启动 Xray 服务
- 自动生成 VLESS Reality 链接和二维码

---

## 🚀 使用方法

### 1️⃣ 克隆项目
```bash
git clone https://github.com/5777033/xray-reality-deploy.git
cd xray-reality-deploy

