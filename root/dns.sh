#!/bin/sh
# OpenWrt / ImmortalWrt DNS 服务手动控制脚本
# 控制 smartdns 和 mosdns 的启动、停止、重启、状态
# 支持查看和修改 /etc/smartdns/custom.conf 中的 -subnet 参数
# 不控制开机自启 enable/disable

SMARTDNS="/etc/init.d/smartdns"
MOSDNS="/etc/init.d/mosdns"
SMARTDNS_CONF="/etc/smartdns/custom.conf"

# ========= 颜色定义 =========
# 如果不是终端环境，则自动关闭颜色，避免重定向日志时出现乱码
if [ -t 1 ]; then
    ESC="$(printf '\033')"
    RESET="${ESC}[0m"
    RED="${ESC}[31m"
    GREEN="${ESC}[32m"
    YELLOW="${ESC}[33m"
    BLUE="${ESC}[34m"
    MAGENTA="${ESC}[35m"
    CYAN="${ESC}[36m"
    BOLD="${ESC}[1m"
else
    RESET=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    BOLD=""
fi

line() {
    printf "%b\n" "${CYAN}----------------------------------------${RESET}"
}

info() {
    printf "%b\n" "${BLUE}[信息]${RESET} $1"
}

success() {
    printf "%b\n" "${GREEN}[成功]${RESET} $1"
}

warn() {
    printf "%b\n" "${YELLOW}[警告]${RESET} $1"
}

error() {
    printf "%b\n" "${RED}[错误]${RESET} $1"
}

title() {
    printf "%b\n" "${BOLD}${CYAN}$1${RESET}"
}

check_service() {
    if [ ! -x "$1" ]; then
        error "未找到服务脚本：$1"
        warn "请确认对应插件是否已经安装。"
        return 1
    fi
    return 0
}

check_smartdns_conf() {
    if [ ! -f "$SMARTDNS_CONF" ]; then
        error "未找到配置文件：$SMARTDNS_CONF"
        warn "请确认 smartdns custom.conf 是否存在。"
        return 1
    fi
    return 0
}

start_smartdns() {
    check_service "$SMARTDNS" || return
    info "正在启动 smartdns..."
    "$SMARTDNS" start
    success "smartdns 启动命令已执行。"
}

stop_smartdns() {
    check_service "$SMARTDNS" || return
    warn "正在停止 smartdns..."
    "$SMARTDNS" stop
    success "smartdns 停止命令已执行。"
}

restart_smartdns() {
    check_service "$SMARTDNS" || return
    warn "正在重启 smartdns..."
    "$SMARTDNS" restart
    success "smartdns 重启命令已执行。"
}

start_mosdns() {
    check_service "$MOSDNS" || return
    info "正在启动 mosdns..."
    "$MOSDNS" start
    success "mosdns 启动命令已执行。"
}

stop_mosdns() {
    check_service "$MOSDNS" || return
    warn "正在停止 mosdns..."
    "$MOSDNS" stop
    success "mosdns 停止命令已执行。"
}

restart_mosdns() {
    check_service "$MOSDNS" || return
    warn "正在重启 mosdns..."
    "$MOSDNS" restart
    success "mosdns 重启命令已执行。"
}

start_all() {
    title "正在启动 smartdns + mosdns..."
    line

    # 如果 mosdns 使用 smartdns 作为上游，建议先启动 smartdns
    start_smartdns
    sleep 1
    start_mosdns

    line
    success "启动完成。"
}

stop_all() {
    title "正在停止 smartdns + mosdns..."
    line

    # 如果 mosdns 依赖 smartdns，建议先停止 mosdns
    stop_mosdns
    sleep 1
    stop_smartdns

    line
    success "停止完成。"
}

restart_all() {
    title "正在重启 smartdns + mosdns..."
    line

    stop_mosdns
    sleep 1
    stop_smartdns
    sleep 1

    start_smartdns
    sleep 1
    start_mosdns

    line
    success "重启完成。"
}

status_service() {
    NAME="$1"
    INIT="$2"

    printf "%b\n" "${BOLD}${MAGENTA}[$NAME]${RESET}"

    if [ ! -x "$INIT" ]; then
        error "服务脚本不存在：$INIT"
        echo
        return
    fi

    "$INIT" status 2>/dev/null

    if pidof "$NAME" >/dev/null 2>&1; then
        printf "%b\n" "${GREEN}进程状态：运行中${RESET}"
        printf "%b\n" "${GREEN}PID：$(pidof "$NAME")${RESET}"
    else
        printf "%b\n" "${RED}进程状态：未运行${RESET}"
    fi

    echo
}

status_all() {
    line
    status_service "smartdns" "$SMARTDNS"
    status_service "mosdns" "$MOSDNS"
    line
}

show_subnet_config() {
    check_smartdns_conf || return

    line
    printf "%b\n" "${MAGENTA}当前 $SMARTDNS_CONF 中已启用的 -subnet 配置：${RESET}"
    line

    awk -v green="$GREEN" -v yellow="$YELLOW" -v reset="$RESET" '
    BEGIN {
        found = 0
    }

    /^[[:space:]]*#/ {
        next
    }

    {
        for (i = 1; i <= NF; i++) {
            if ($i == "-subnet" && (i + 1) <= NF) {
                found = 1
                printf("%s第 %d 行：%s%s\n", green, NR, $(i + 1), reset)
                printf("%s  %s%s\n\n", yellow, $0, reset)
            }
        }
    }

    END {
        if (found == 0) {
            print "未发现已启用的 -subnet 参数。"
        }
    }
    ' "$SMARTDNS_CONF"

    line
}

validate_subnet() {
    SUBNET="$1"

    echo "$SUBNET" | awk -F'[./]' '
    NF != 5 {
        exit 1
    }

    {
        for (i = 1; i <= 5; i++) {
            if ($i !~ /^[0-9]+$/) {
                exit 1
            }
        }

        if ($1 < 0 || $1 > 255) exit 1
        if ($2 < 0 || $2 > 255) exit 1
        if ($3 < 0 || $3 > 255) exit 1
        if ($4 < 0 || $4 > 255) exit 1
        if ($5 < 0 || $5 > 32) exit 1
    }
    '
}

change_subnet_config() {
    check_smartdns_conf || return

    line
    printf "%b\n" "${BOLD}${MAGENTA}修改 smartdns custom.conf 中的 -subnet 参数${RESET}"
    line

    show_subnet_config

    OLD_COUNT="$(awk '
    /^[[:space:]]*#/ {
        next
    }

    {
        for (i = 1; i <= NF; i++) {
            if ($i == "-subnet" && (i + 1) <= NF) {
                count++
            }
        }
    }

    END {
        print count + 0
    }
    ' "$SMARTDNS_CONF")"

    if [ "$OLD_COUNT" -eq 0 ]; then
        warn "当前未发现启用状态的 -subnet 参数，已取消修改。"
        return
    fi

    printf "%b\n" "${BLUE}请输入新的 -subnet 参数。${RESET}"
    printf "%b\n" "${YELLOW}示例：120.82.69.34/24${RESET}"
    printf "%b" "${MAGENTA}新的 -subnet：${RESET}"
    read NEW_SUBNET

    if [ -z "$NEW_SUBNET" ]; then
        warn "输入为空，已取消修改。"
        return
    fi

    if ! validate_subnet "$NEW_SUBNET"; then
        error "格式错误：$NEW_SUBNET"
        warn "正确示例：120.82.69.34/24"
        warn "CIDR 掩码范围必须是 0-32。"
        return
    fi

    line
    printf "%b\n" "${YELLOW}将把所有未注释行中的 -subnet 参数替换为：${RESET}${GREEN}$NEW_SUBNET${RESET}"
    printf "%b\n" "${YELLOW}预计替换数量：${RESET}${GREEN}$OLD_COUNT${RESET}"
    line
    printf "%b" "${YELLOW}确认修改？[y/N]：${RESET}"
    read CONFIRM

    case "$CONFIRM" in
        y|Y|yes|YES)
            ;;
        *)
            warn "已取消修改。"
            return
            ;;
    esac

    BACKUP="${SMARTDNS_CONF}.bak.$(date +%Y%m%d-%H%M%S)"
    TMP="/tmp/smartdns_custom_conf.$$"

    cp "$SMARTDNS_CONF" "$BACKUP" || {
        error "备份失败，已取消修改。"
        return
    }

    awk -v new_subnet="$NEW_SUBNET" '
    /^[[:space:]]*#/ {
        print
        next
    }

    {
        line = $0
        gsub(/-subnet[[:space:]]+[^[:space:]]+/, "-subnet " new_subnet, line)
        print line
    }
    ' "$SMARTDNS_CONF" > "$TMP" || {
        error "生成临时配置失败，已取消修改。"
        rm -f "$TMP"
        return
    }

    cat "$TMP" > "$SMARTDNS_CONF" || {
        error "写入配置失败。"
        warn "备份文件保存在：$BACKUP"
        rm -f "$TMP"
        return
    }

    rm -f "$TMP"

    line
    success "修改完成。"
    printf "%b\n" "${BLUE}备份文件：$BACKUP${RESET}"
    line

    show_subnet_config

    printf "%b" "${YELLOW}是否立即重启 smartdns 让配置生效？[y/N]：${RESET}"
    read RESTART_CONFIRM

    case "$RESTART_CONFIRM" in
        y|Y|yes|YES)
            restart_smartdns
            ;;
        *)
            warn "未重启 smartdns。"
            info "你可以之后手动选择菜单中的 smartdns 重启选项。"
            ;;
    esac
}

show_menu() {
    clear
    title "OpenWrt DNS 服务控制脚本"
    line
    printf "%b\n" "${GREEN}1. 启动 smartdns + mosdns${RESET}"
    printf "%b\n" "${RED}2. 停止 smartdns + mosdns${RESET}"
    printf "%b\n" "${YELLOW}3. 重启 smartdns + mosdns${RESET}"
    printf "%b\n" "${BLUE}4. 查看 smartdns + mosdns 状态${RESET}"
    line
    printf "%b\n" "${GREEN}5. 只启动 smartdns${RESET}"
    printf "%b\n" "${RED}6. 只停止 smartdns${RESET}"
    printf "%b\n" "${YELLOW}7. 只重启 smartdns${RESET}"
    line
    printf "%b\n" "${GREEN}8. 只启动 mosdns${RESET}"
    printf "%b\n" "${RED}9. 只停止 mosdns${RESET}"
    printf "%b\n" "${YELLOW}10. 只重启 mosdns${RESET}"
    line
    printf "%b\n" "${MAGENTA}11. 查看 smartdns custom.conf 中的 -subnet${RESET}"
    printf "%b\n" "${MAGENTA}12. 修改 smartdns custom.conf 中的 -subnet${RESET}"
    line
    printf "%b\n" "${RED}0. 退出${RESET}"
    line
}

while true
do
    show_menu

    printf "%b" "${BOLD}请输入选项：${RESET}"
    read choice

    case "$choice" in
        1)
            start_all
            ;;
        2)
            stop_all
            ;;
        3)
            restart_all
            ;;
        4)
            status_all
            ;;
        5)
            start_smartdns
            ;;
        6)
            stop_smartdns
            ;;
        7)
            restart_smartdns
            ;;
        8)
            start_mosdns
            ;;
        9)
            stop_mosdns
            ;;
        10)
            restart_mosdns
            ;;
        11)
            show_subnet_config
            ;;
        12)
            change_subnet_config
            ;;
        0)
            success "已退出。"
            exit 0
            ;;
        *)
            error "无效选项。"
            ;;
    esac

    echo
    printf "%b" "${CYAN}按回车键返回菜单...${RESET}"
    read dummy
done