#!/bin/sh
set -eu

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PAYLOAD="$PACKAGE_DIR/dist"
ZH_PAYLOAD="$PACKAGE_DIR/ace-page-zh"
FLUIDD_ROOT=${FLUIDD_ROOT:-"$HOME/fluidd"}
ACEPRO_ROOT=${ACEPRO_ROOT:-"$HOME/ACEPRO"}
ACE_WEB_ROOT=${ACE_WEB_ROOT:-"$ACEPRO_ROOT/ace_status_integration/web"}
MOONRAKER_ROOT=${MOONRAKER_ROOT:-"$HOME/moonraker"}
MOONRAKER_CONF=${MOONRAKER_CONF:-"$HOME/printer_data/config/moonraker.conf"}
STATE_DIR=${ACEPRO_STATE_DIR:-"$HOME/.local/share/fluidd-acepro"}
TARGET_PARENT=$(dirname -- "$FLUIDD_ROOT")
TARGET_NAME=$(basename -- "$FLUIDD_ROOT")
BACKUP_DIR="$TARGET_PARENT/.fluidd-acepro-backups"
ACTIVE_FILE="$STATE_DIR/active_backup"
ZH_ACTIVE_FILE="$STATE_DIR/active_chinese_backup"
MARKER="$FLUIDD_ROOT/.fluidd-acepro-installed"

line() {
  printf '%s\n' '+----------------------------------------------------------+'
}

header() {
  command -v clear >/dev/null 2>&1 && clear || true
  line
  printf '%s\n' '|          Fluidd ACE Pro 中文管理工具                    |'
  line
}

ok() {
  printf '[  OK  ] %s\n' "$1"
}

bad() {
  printf '[ 失败 ] %s\n' "$1" >&2
}

pause_menu() {
  printf '\n按 Enter 返回菜单...'
  IFS= read -r _answer || true
}

confirm() {
  printf '%s [y/N]: ' "$1"
  IFS= read -r answer || return 1
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

check_driver() {
  failed=0
  printf '\n正在检测 Kobra-S1/ACEPRO 驱动...\n'

  if [ -d "$ACEPRO_ROOT" ]; then
    ok "驱动目录: $ACEPRO_ROOT"
  else
    bad "未找到驱动目录: $ACEPRO_ROOT"
    failed=1
  fi

  component="$MOONRAKER_ROOT/moonraker/components/ace_status.py"
  if [ -f "$component" ]; then
    ok "Moonraker ACE 组件已安装"
  else
    bad "未找到 Moonraker 组件: $component"
    failed=1
  fi

  if [ -f "$MOONRAKER_CONF" ] && grep -Eq '^[[:space:]]*\[ace_status\][[:space:]]*$' "$MOONRAKER_CONF"; then
    ok "Moonraker 已启用 [ace_status]"
  else
    bad "moonraker.conf 未启用 [ace_status]"
    failed=1
  fi

  if command -v curl >/dev/null 2>&1; then
    api_code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 10 http://127.0.0.1:7125/server/ace/status || true)
    if [ "$api_code" = "200" ]; then
      ok "ACE API 可访问: /server/ace/status"
    else
      bad "ACE API 不可用，HTTP 状态码: $api_code"
      failed=1
    fi
  else
    bad "系统缺少 curl，无法检测 ACE API"
    failed=1
  fi

  [ "$failed" -eq 0 ]
}

install_card() {
  check_driver || {
    bad "请先按 Kobra-S1/ACEPRO 教程完成驱动和 Moonraker 插件安装"
    return 1
  }

  [ -f "$PAYLOAD/index.html" ] || { bad "安装包缺少 dist/index.html"; return 1; }
  [ -d "$TARGET_PARENT" ] || { bad "目标父目录不存在: $TARGET_PARENT"; return 1; }
  [ -d "$FLUIDD_ROOT" ] || { bad "Fluidd 目录不存在: $FLUIDD_ROOT"; return 1; }

  stamp=$(date +%Y%m%d_%H%M%S)
  stage="$TARGET_PARENT/.${TARGET_NAME}.acepro-stage-$stamp-$$"
  mkdir -p "$STATE_DIR" "$BACKUP_DIR"
  cp -a "$PAYLOAD" "$stage"

  if [ -e "$FLUIDD_ROOT/config.json" ] || [ -L "$FLUIDD_ROOT/config.json" ]; then
    cp -a "$FLUIDD_ROOT/config.json" "$stage/config.json"
  fi
  for path in "$FLUIDD_ROOT"/ace*; do
    if [ -e "$path" ] || [ -L "$path" ]; then
      cp -a "$path" "$stage/$(basename -- "$path")"
    fi
  done

  if [ -f "$MARKER" ] && [ -s "$ACTIVE_FILE" ]; then
    moved_current="$BACKUP_DIR/upgrade-$stamp"
  else
    moved_current="$BACKUP_DIR/original-$stamp"
  fi

  mv "$FLUIDD_ROOT" "$moved_current"
  if ! mv "$stage" "$FLUIDD_ROOT"; then
    mv "$moved_current" "$FLUIDD_ROOT"
    bad "部署失败，已自动恢复原 Fluidd"
    return 1
  fi

  printf 'installed_at=%s\nsource=%s\n' "$stamp" "$PACKAGE_DIR" > "$MARKER"
  new_active=0
  if [ ! -s "$ACTIVE_FILE" ] || [ ! -f "$moved_current/.fluidd-acepro-installed" ]; then
    printf '%s\n' "$moved_current" > "$ACTIVE_FILE.tmp"
    mv "$ACTIVE_FILE.tmp" "$ACTIVE_FILE"
    new_active=1
  fi

  code=$(curl -L -sS -o /dev/null -w '%{http_code}' --max-time 15 http://127.0.0.1/ || true)
  if [ "$code" != "200" ]; then
    mv "$FLUIDD_ROOT" "$BACKUP_DIR/failed-install-$stamp"
    mv "$moved_current" "$FLUIDD_ROOT"
    if [ "$new_active" -eq 1 ]; then
      mv "$ACTIVE_FILE" "$STATE_DIR/active_backup.failed-$stamp"
    fi
    bad "HTTP 检查失败，已自动恢复，状态码: $code"
    return 1
  fi

  ok "ACE Pro Fluidd 卡片安装完成"
  printf '原版恢复点: %s\n' "$(cat "$ACTIVE_FILE")"
}

uninstall_card() {
  [ -s "$ACTIVE_FILE" ] || { bad "没有找到原版 Fluidd 恢复记录"; return 1; }
  original=$(cat "$ACTIVE_FILE")
  [ -d "$original" ] || { bad "原版备份不存在: $original"; return 1; }
  [ -d "$FLUIDD_ROOT" ] || { bad "当前 Fluidd 目录不存在: $FLUIDD_ROOT"; return 1; }

  stamp=$(date +%Y%m%d_%H%M%S)
  removed="$BACKUP_DIR/removed-custom-$stamp"
  mkdir -p "$BACKUP_DIR"
  mv "$FLUIDD_ROOT" "$removed"
  if ! mv "$original" "$FLUIDD_ROOT"; then
    mv "$removed" "$FLUIDD_ROOT"
    bad "恢复失败，已放回 ACE Pro 版 Fluidd"
    return 1
  fi

  code=$(curl -L -sS -o /dev/null -w '%{http_code}' --max-time 15 http://127.0.0.1/ || true)
  if [ "$code" != "200" ]; then
    mv "$FLUIDD_ROOT" "$original"
    mv "$removed" "$FLUIDD_ROOT"
    bad "恢复后 HTTP 检查失败，已回滚，状态码: $code"
    return 1
  fi

  mv "$ACTIVE_FILE" "$STATE_DIR/active_backup.uninstalled-$stamp"
  ok "ACE Pro Fluidd 卡片已卸载，原版 Fluidd 已恢复"
  printf '卸载版本备份: %s\n' "$removed"
}

install_chinese_page() {
  check_driver || return 1
  [ -f "$ZH_PAYLOAD/ace.html" ] || { bad "安装包缺少中文版 ace.html"; return 1; }
  [ -f "$ZH_PAYLOAD/ace-dashboard.js" ] || { bad "安装包缺少中文版 ace-dashboard.js"; return 1; }
  [ -d "$ACE_WEB_ROOT" ] || { bad "ACE 页面目录不存在: $ACE_WEB_ROOT"; return 1; }

  stamp=$(date +%Y%m%d_%H%M%S)
  if [ -s "$ZH_ACTIVE_FILE" ]; then
    backup="$STATE_DIR/chinese-backups/replaced-$stamp"
  else
    backup="$STATE_DIR/chinese-backups/original-$stamp"
  fi
  mkdir -p "$backup"

  for file in ace.html ace-dashboard.js; do
    [ -f "$ACE_WEB_ROOT/$file" ] || { bad "缺少原页面文件: $ACE_WEB_ROOT/$file"; return 1; }
    cp -a "$ACE_WEB_ROOT/$file" "$backup/$file"
    cp "$ZH_PAYLOAD/$file" "$ACE_WEB_ROOT/.$file.new"
  done

  if ! mv "$ACE_WEB_ROOT/.ace.html.new" "$ACE_WEB_ROOT/ace.html" ||
     ! mv "$ACE_WEB_ROOT/.ace-dashboard.js.new" "$ACE_WEB_ROOT/ace-dashboard.js"; then
    cp "$backup/ace.html" "$ACE_WEB_ROOT/ace.html"
    cp "$backup/ace-dashboard.js" "$ACE_WEB_ROOT/ace-dashboard.js"
    bad "页面替换失败，已恢复操作前版本"
    return 1
  fi

  if [ ! -s "$ZH_ACTIVE_FILE" ]; then
    printf '%s\n' "$backup" > "$ZH_ACTIVE_FILE.tmp"
    mv "$ZH_ACTIVE_FILE.tmp" "$ZH_ACTIVE_FILE"
  fi
  ok "ACE 独立控制页面已转换为中文"
  printf '本次操作前页面备份: %s\n' "$backup"
  printf '原页面恢复点: %s\n' "$(cat "$ZH_ACTIVE_FILE")"
}

restore_chinese_page() {
  [ -s "$ZH_ACTIVE_FILE" ] || { bad "没有找到中文化前的页面备份记录"; return 1; }
  original=$(cat "$ZH_ACTIVE_FILE")
  [ -f "$original/ace.html" ] || { bad "页面备份不完整: $original"; return 1; }
  [ -f "$original/ace-dashboard.js" ] || { bad "页面备份不完整: $original"; return 1; }

  stamp=$(date +%Y%m%d_%H%M%S)
  removed="$STATE_DIR/chinese-backups/removed-chinese-$stamp"
  mkdir -p "$removed"
  cp -a "$ACE_WEB_ROOT/ace.html" "$ACE_WEB_ROOT/ace-dashboard.js" "$removed/"

  for file in ace.html ace-dashboard.js; do
    cp "$original/$file" "$ACE_WEB_ROOT/.$file.restore"
  done

  if ! mv "$ACE_WEB_ROOT/.ace.html.restore" "$ACE_WEB_ROOT/ace.html" ||
     ! mv "$ACE_WEB_ROOT/.ace-dashboard.js.restore" "$ACE_WEB_ROOT/ace-dashboard.js"; then
    cp "$removed/ace.html" "$ACE_WEB_ROOT/ace.html"
    cp "$removed/ace-dashboard.js" "$ACE_WEB_ROOT/ace-dashboard.js"
    bad "页面还原失败，已恢复操作前的中文版"
    return 1
  fi

  mv "$ZH_ACTIVE_FILE" "$STATE_DIR/active_chinese_backup.restored-$stamp"
  ok "ACE 独立控制页面已还原"
  printf '被替换的中文版备份: %s\n' "$removed"
}

show_status() {
  printf '\n卡片状态: '
  if [ -f "$MARKER" ]; then printf '已安装\n'; else printf '未安装\n'; fi
  printf '中文页面恢复点: '
  if [ -s "$ZH_ACTIVE_FILE" ]; then printf '%s\n' "$(cat "$ZH_ACTIVE_FILE")"; else printf '无\n'; fi
  check_driver || true
}

menu() {
  while true; do
    header
    printf '%s\n' '|  1. 安装 / 更新 Fluidd ACE Pro 卡片                   |'
    printf '%s\n' '|  2. 卸载卡片并恢复原版 Fluidd                       |'
    printf '%s\n' '|  3. 将 ace.html 独立控制页面转换为中文               |'
    printf '%s\n' '|  4. 还原中文化前的 ace.html 控制页面                 |'
    printf '%s\n' '|  5. 检测驱动与安装状态                               |'
    printf '%s\n' '|  0. 退出                                              |'
    line
    printf '请选择 [0-5]: '
    IFS= read -r choice || exit 0
    case "$choice" in
      1) confirm '确认安装或更新 Fluidd ACE Pro 卡片？' && install_card || true; pause_menu ;;
      2) confirm '确认卸载并恢复原版 Fluidd？' && uninstall_card || true; pause_menu ;;
      3) confirm '确认备份当前页面并转换为中文？' && install_chinese_page || true; pause_menu ;;
      4) confirm '确认备份当前中文版并还原原页面？' && restore_chinese_page || true; pause_menu ;;
      5) show_status; pause_menu ;;
      0) exit 0 ;;
      *) bad "无效选项: $choice"; pause_menu ;;
    esac
  done
}

case "${1:-}" in
  --install) install_card ;;
  --uninstall) uninstall_card ;;
  --install-zh) install_chinese_page ;;
  --restore-zh) restore_chinese_page ;;
  --status) show_status ;;
  --help|-h)
    printf '%s\n' '用法: ./install.sh [--install|--uninstall|--install-zh|--restore-zh|--status]'
    ;;
  '') menu ;;
  *) bad "未知参数: $1"; exit 2 ;;
esac
