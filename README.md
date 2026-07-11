# Fluidd ACE Pro 卡片

为 DIY Klipper 打印机提供原生 Fluidd ACE Pro 控制卡片，界面包含设备状态、
烘干控制、四个料槽、装载/卸载、耗材信息和无限续料。卡片优先使用
[Kobra-S1/ACEPRO](https://github.com/Kobra-S1/ACEPRO) 的 Moonraker API，
API 不可用时兼容 ACE G-Code。

## 功能

- Fluidd 仪表盘原生卡片和左侧 `ACE Pro` 页面，不是 iframe 或外部网页。
- 每 5 秒读取 `/server/ace/status`，显示真实设备和料槽状态。
- 中文字符菜单完成安装、更新、卸载、驱动检测和页面语言管理。
- 可选把驱动自带的 `ace.html` 独立控制页转换为中文。
- Fluidd 和中文页面的每次替换都会先备份，失败自动回滚。
- 保留 `config.json` 与现有 ACE 静态页面链接，不修改 Nginx、Klipper 或 Moonraker。

## 快速开始

下载 GitHub Releases 中的 `fluidd-acepro-package.tar.gz`，上传到打印机后执行：

```sh
cd ~
tar -xzf fluidd-acepro-package.tar.gz
cd fluidd-acepro-package
chmod +x install.sh uninstall.sh
./install.sh
```

终端会显示字符菜单：

```text
+----------------------------------------------------------+
|          Fluidd ACE Pro 中文管理工具                    |
+----------------------------------------------------------+
|  1. 安装 / 更新 Fluidd ACE Pro 卡片                   |
|  2. 卸载卡片并恢复原版 Fluidd                       |
|  3. 将 ace.html 独立控制页面转换为中文               |
|  4. 还原中文化前的 ace.html 控制页面                 |
|  5. 检测驱动与安装状态                               |
|  0. 退出                                              |
+----------------------------------------------------------+
```

首次使用建议先选 `5`。检测全部通过后选 `1` 安装卡片，需要中文独立页面时
再选 `3`。完整步骤和故障排查见 [中文安装教程](docs/INSTALL.zh-CN.md)。

## 非交互命令

```sh
./install.sh --status       # 检测驱动和当前安装状态
./install.sh --install      # 安装或更新卡片
./install.sh --uninstall    # 卸载卡片并恢复原版 Fluidd
./install.sh --install-zh   # 中文化 ace.html 页面
./install.sh --restore-zh   # 还原中文化前的页面
```

兼容入口 `./uninstall.sh` 等同于 `./install.sh --uninstall`。

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

