# Fluidd ACE Pro 卡片

为 DIY Klipper 打印机提供原生 Fluidd ACE Pro 控制卡片，界面包含设备状态、
烘干控制、四个料槽、装载/卸载、耗材信息和无限续料。卡片优先使用
[Kobra-S1/ACEPRO](https://github.com/Kobra-S1/ACEPRO) 的 Moonraker API，
API 不可用时兼容 ACE G-Code。

## 功能

- Fluidd 仪表盘原生卡片和左侧 `ACE Pro` 页面，不是 iframe 或外部网页。
- 每 5 秒读取 `/server/ace/status`，显示真实设备和料槽状态。
- 中文字符菜单完成安装、更新、卸载和独立控制界面语言管理，安装面板前自动检测驱动。
- 可选把驱动自带的 `ace.html` 独立控制页转换为中文。
- Fluidd 和中文页面的每次替换都会先备份，失败自动回滚。
- 保留 `config.json` 与现有 ACE 静态页面链接，不修改 Nginx、Klipper 或 Moonraker。
- 检测面板是否被官方 Fluidd 更新覆盖，并验证 Nginx 实际提供的页面。

## 快速开始

通过 SSH 登录打印机，直接从 GitHub 克隆仓库：

```sh
cd ~
git clone --depth 1 https://github.com/Luomo520/fluidd-acepro-card.git
cd fluidd-acepro-card
bash install.sh
```

以后更新面板时执行：

```sh
cd ~/fluidd-acepro-card
git pull --ff-only
bash install.sh
```

终端会显示字符菜单：

```text
+----------------------------------------------------------+
|          Fluidd ACE Pro 中文管理工具                    |
+----------------------------------------------------------+
  Fluidd 版本 : v1.37.2
  驱动版本    : 已安装（未提供版本）
  面板版本    : v0.1.5
  安装状态    : 未安装
+----------------------------------------------------------+
|  1. 安装 / 更新 Fluidd ACE Pro 面板                   |
|  2. 卸载卡片并恢复原版 Fluidd                       |
|  3. 独立控制界面翻译                                 |
|  4. 独立控制界面翻译还原                             |
|  5. 忽略 ACE API 检测并安装面板                      |
|  0. 退出                                              |
+----------------------------------------------------------+
```

选择 `1` 后，脚本会先检测 ACEPRO 驱动、Moonraker 组件、配置和 API，全部
通过后才安装面板。API 因代理或启动时序返回非 200 时，可选择 `5` 忽略 API
检测并安装；该路径仍会备份当前 Fluidd，再次运行脚本选择 `2` 即可还原。
需要翻译中文独立控制界面时再选 `3`。完整步骤和故障排查见
[中文安装教程](docs/INSTALL.zh-CN.md)。

官方 Fluidd 更新会覆盖定制网页文件。更新 Fluidd 后再次执行 `git pull` 和
`bash install.sh`，选择 `1` 即可基于当前兼容版本重新安装。

## 非交互命令

```sh
bash install.sh --status       # 检测驱动和当前安装状态
bash install.sh --install      # 安装或更新卡片
bash install.sh --install-force # 忽略 ACE API 检测并安装
bash install.sh --uninstall    # 卸载卡片并恢复原版 Fluidd
bash install.sh --install-zh   # 中文化 ace.html 页面
bash install.sh --restore-zh   # 还原中文化前的页面
```

兼容入口 `bash uninstall.sh` 等同于 `bash install.sh --uninstall`。

## 源码

`source-overlay/` 包含相对于 Fluidd `v1.37.2` 的全部新增和修改文件。
在 Fluidd 源码根目录覆盖这些文件后运行：

```sh
corepack enable
pnpm install
pnpm lint
pnpm type-check
pnpm build
```

本项目基于 Fluidd，采用 GPL-3.0 许可证。Kobra-S1/ACEPRO 的驱动及其许可
由对应上游项目维护。
