# Fluidd ACE Pro 卡片中文安装教程

## 1. 适用范围

本教程适用于运行 Klipper、Moonraker、Fluidd 的 DIY 3D 打印机。安装脚本只替换
Fluidd 的静态网页目录，不修改 `printer.cfg`，也不会重启 Klipper、Moonraker
或 Nginx。

默认路径如下：

```text
Fluidd:          ~/fluidd
ACEPRO:          ~/ACEPRO
Moonraker:       ~/moonraker
moonraker.conf:  ~/printer_data/config/moonraker.conf
```

## 2. 前置条件

必须先完成 [Kobra-S1/ACEPRO](https://github.com/Kobra-S1/ACEPRO) 驱动安装，
并确认 ACE 硬件已经正常连接。选择“安装 / 更新 Fluidd ACE Pro 面板”后，
脚本会在安装前自动检测：

1. `~/ACEPRO` 驱动目录存在。
2. `~/moonraker/moonraker/components/ace_status.py` 已安装。
3. `moonraker.conf` 中存在 `[ace_status]`。
4. `http://127.0.0.1:7125/server/ace/status` 返回 HTTP 200。
5. 当前 Fluidd 版本与仓库内的定制构建版本一致。

任何一项失败，卡片安装都会停止，不会替换 Fluidd。

可以先手工验证 API：

```sh
curl http://127.0.0.1:7125/server/ace/status
```

## 3. 使用 Git 下载

打印机需要能够访问 GitHub，并已安装 Git。通过 SSH 登录打印机后执行：

```sh
cd ~
git clone --depth 1 https://github.com/Luomo520/fluidd-acepro-card.git
cd fluidd-acepro-card
```

如果仓库已经存在，使用以下命令获取更新：

```sh
cd ~/fluidd-acepro-card
git pull --ff-only
```

## 4. 使用字符菜单

运行：

```sh
bash install.sh
```

建议操作顺序：

1. 在菜单顶部确认 Fluidd、驱动和面板版本信息。
2. 选择 `1`，脚本会自动检测 ACEPRO 驱动和 API，通过后安装 Fluidd 面板。
3. 浏览器打开 Fluidd，强制刷新一次，确认左侧菜单和仪表盘出现 `ACE Pro`。
4. 如需翻译中文独立控制界面，重新运行菜单并选择 `3`。

卡片地址：

```text
http://打印机IP/#/acepro
```

驱动自带独立页面地址：

```text
http://打印机IP/ace.html
```

Moonraker 的 `7125` 端口只提供 API，不能用
`http://打印机IP:7125/ace.html` 访问静态页面。

## 5. 备份与回滚

卡片安装前，当前 Fluidd 会完整移动到：

```text
~/.fluidd-acepro-backups/original-时间戳
```

更新卡片前，当前定制版会备份为：

```text
~/.fluidd-acepro-backups/upgrade-时间戳
```

中文化前，`ace.html` 和 `ace-dashboard.js` 会备份到：

```text
~/.local/share/fluidd-acepro/chinese-backups/original-时间戳
```

脚本不会自动删除这些备份。部署或 HTTP 检查失败时会自动恢复替换前版本。

## 6. 卸载与页面还原

菜单选择 `2` 会先备份当前 ACE Pro 版 Fluidd，再恢复首次安装前的完整
Fluidd。也可以执行：

```sh
bash install.sh --uninstall
```

菜单中的“独立控制界面翻译还原”会先备份当前中文页面，再恢复最近一次
翻译前的两个文件：

```sh
bash install.sh --restore-zh
```

卡片卸载和独立页面还原互不影响。

## 7. 自定义路径

路径不同的系统可以通过环境变量指定：

```sh
FLUIDD_ROOT=/home/pi/fluidd \
ACEPRO_ROOT=/home/pi/ACEPRO \
MOONRAKER_ROOT=/home/pi/moonraker \
MOONRAKER_CONF=/home/pi/printer_data/config/moonraker.conf \
bash install.sh
```

如果 ACE 网页不在驱动默认目录，可额外设置：

```sh
ACE_WEB_ROOT=/实际/ace_status_integration/web bash install.sh --install-zh
```

## 8. 常见问题

### 浏览器仍显示旧界面

Fluidd 使用 PWA 缓存。先按 `Ctrl+F5` 强制刷新；仍未更新时，清除此站点的
缓存和 Service Worker 后重新打开。

### 更新 Fluidd 后 ACE Pro 消失

官方 Fluidd 更新会覆盖定制构建和安装标记。更新完成后重新执行：

```sh
cd ~/fluidd-acepro-card
git pull --ff-only
bash install.sh
```

菜单顶部若显示“已被 Fluidd 更新覆盖，需要重新安装”，选择 `1`。安装器会先
备份更新后的官方 Fluidd，再部署兼容构建。

### 安装完成但没有 ACE Pro 页面

运行 `bash install.sh --status`。新版安装器会检查 ACE 构建文件以及 Nginx
实际提供的入口文件。如果脚本显示安装成功但浏览器仍没有入口，请清除该站点
的缓存和 Service Worker，然后重新打开 Fluidd。

### 提示 ACE API 不可用

检查 Moonraker 日志、`[ace_status]` 配置和组件软链接，然后重启 Moonraker：

```sh
systemctl restart moonraker
curl http://127.0.0.1:7125/server/ace/status
```

### Fluidd 不在 `~/fluidd`

用 `FLUIDD_ROOT` 指定真实目录。不要把 Nginx 的 URL 写进该变量，它必须是
Linux 文件系统路径。

### 如何查看状态而不修改文件

```sh
bash install.sh --status
```

该命令只读取目录、配置和 API，不执行安装。
