#!/bin/bash

# Ubuntu Tools 脚本 - 项目虚拟目录管理功能
# 功能：
#   1. 创建虚拟目录（支持自定义路径）
#   2. 进入虚拟目录（支持选择已有目录进入）
#   3. 列出所有虚拟目录
#   4. 删除虚拟目录（确认后彻底删除，避免误删）
# 兼容：Ubuntu 20.04 及更高版本

# 配置：虚拟目录列表文件路径（用于保存创建的虚拟目录路径）
VDIR_LIST_FILE="$HOME/.vdirs_list"
# 如果列表文件不存在则创建
if [ ! -f "$VDIR_LIST_FILE" ]; then
    touch "$VDIR_LIST_FILE"
fi

# 创建虚拟目录
create_vdir() {
    echo "=== 创建虚拟目录 ==="
    # 提示用户输入要创建的目录路径或名称
    read -p "请输入新虚拟目录的路径（可自定义路径，留空则取消）： " new_dir
    # 如果未输入任何内容，则取消操作
    if [[ -z "$new_dir" ]]; then
        echo "已取消创建。"
        return
    fi
    # 如果用户输入的不是绝对路径，则默认在 ~/vdirs 下创建
    if [[ "$new_dir" != /* ]]; then
        base_path="$HOME/vdirs"            # 虚拟目录默认根路径
        mkdir -p "$base_path"              # 确保默认路径存在
        new_dir="$base_path/$new_dir"      # 将目录名称拼接为完整路径
    fi
    # 检查目标目录是否已存在
    if [ -e "$new_dir" ]; then
        if [ -d "$new_dir" ]; then
            echo "目录 $new_dir 已存在，无需创建。"
        else
            echo "错误：路径 $new_dir 已存在且不是目录！"
            return
        fi
    else
        # 尝试创建目录
        mkdir -p "$new_dir"
        if [ $? -ne 0 ]; then
            echo "创建目录失败：无法创建 $new_dir"
            return
        fi
        echo "目录已创建：$new_dir"
    fi
    # 将目录添加到列表文件（如果尚未在列表中）
    if ! grep -Fxq "$new_dir" "$VDIR_LIST_FILE"; then
        echo "$new_dir" >> "$VDIR_LIST_FILE"
    fi
    echo "虚拟目录已添加到列表。"
}

# 进入虚拟目录
enter_vdir() {
    echo "=== 进入虚拟目录 ==="
    # 读取列表文件中的所有目录到数组
    mapfile -t vdirs < "$VDIR_LIST_FILE"
    if [ ${#vdirs[@]} -eq 0 ]; then
        echo "当前没有任何虚拟目录可进入。"
        return
    fi
    # 列出可供选择的目录
    echo "请选择要进入的虚拟目录："
    for i in "${!vdirs[@]}"; do
        printf "%d) %s\n" $((i+1)) "${vdirs[i]}"
    done
    echo "0) 取消"
    # 读取用户选择
    read -p "输入编号以进入对应目录： " choice
    # 验证输入是否为数字
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "无效的选择。"
        return
    fi
    # 用户选择0则取消操作
    if [ "$choice" -eq 0 ]; then
        echo "已取消进入目录。"
        return
    fi
    # 检查选择编号是否有效
    if [ "$choice" -lt 1 ] || [ "$choice" -gt ${#vdirs[@]} ]; then
        echo "无效的选择。"
        return
    fi
    # 获取目标目录路径
    target_dir="${vdirs[$((choice-1))]}"
    # 检查目录在文件系统中是否存在
    if [ ! -d "$target_dir" ]; then
        echo "目录不存在：$target_dir"
        # 从列表中移除不存在的目录项
        sed -i "\#^$target_dir\$#d" "$VDIR_LIST_FILE"
        return
    fi
    # 切换到该目录并启动一个子Shell，让用户在该目录下操作
    echo "切换到目录: $target_dir"
    echo "提示: 您已进入子Shell，完成操作后输入 'exit' 可返回菜单。"
    cd "$target_dir" || { echo "无法进入目录 $target_dir"; return; }
    $SHELL  # 启动交互式子Shell
    # 用户退出子Shell后执行
    echo "已从虚拟目录 $target_dir 返回。"
}

# 列出所有虚拟目录
list_vdir() {
    echo "=== 列出所有虚拟目录 ==="
    if [ ! -s "$VDIR_LIST_FILE" ]; then
        echo "虚拟目录列表为空。"
    else
        echo "当前项目虚拟目录列表："
        local i=1
        while IFS= read -r dir; do
            # 跳过空行
            [[ -z "$dir" ]] && continue
            echo "$i. $dir"
            i=$((i+1))
        done < "$VDIR_LIST_FILE"
    fi
}

# 删除虚拟目录
delete_vdir() {
    echo "=== 删除虚拟目录 ==="
    # 读取所有目录到数组
    mapfile -t vdirs < "$VDIR_LIST_FILE"
    if [ ${#vdirs[@]} -eq 0 ]; then
        echo "当前没有虚拟目录可删除。"
        return
    fi
    # 列出目录供用户选择删除哪一个
    echo "请选择要删除的虚拟目录："
    for i in "${!vdirs[@]}"; do
        printf "%d) %s\n" $((i+1)) "${vdirs[i]}"
    done
    echo "0) 取消"
    read -p "输入编号以删除对应目录： " choice
    # 验证输入
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "无效的选择。"
        return
    fi
    if [ "$choice" -eq 0 ]; then
        echo "已取消删除。"
        return
    fi
    if [ "$choice" -lt 1 ] || [ "$choice" -gt ${#vdirs[@]} ]; then
        echo "无效的选择。"
        return
    fi
    target_dir="${vdirs[$((choice-1))]}"
    # 检查目录是否存在于文件系统
    if [ ! -d "$target_dir" ]; then
        echo "目录不存在：$target_dir"
        # 从列表中移除不存在的目录项
        sed -i "\#^$target_dir\$#d" "$VDIR_LIST_FILE"
        return
    fi
    # 安全检查：避免删除关键系统目录或用户主目录
    protected_dirs=( "/" "/home" "/root" "/bin" "/boot" "/dev" "/etc" "/lib" "/lib32" "/lib64" "/libx32" "/media" "/mnt" "/opt" "/proc" "/run" "/sbin" "/srv" "/sys" "/usr" "/var" )
    for pd in "${protected_dirs[@]}"; do
        if [[ "$target_dir" == "$pd" ]]; then
            echo "错误：禁止删除关键系统目录 $target_dir"
            return
        fi
    done
    if [[ "$target_dir" == "$HOME" ]]; then
        echo "错误：禁止删除用户主目录！"
        return
    fi
    # 二次确认删除操作
    echo "您正准备删除目录及其中的所有文件： $target_dir"
    read -p "此操作不可恢复！请输入 DELETE 确认删除，或直接回车取消： " confirm
    if [ "$confirm" != "DELETE" ]; then
        echo "已取消删除操作。"
        return
    fi
    # 执行删除目录
    rm -rf "$target_dir"
    if [ $? -eq 0 ]; then
        echo "目录 $target_dir 已成功删除。"
    else
        echo "删除目录 $target_dir 时发生错误！"
    fi
    # 从列表文件中移除该目录路径
    sed -i "\#^$target_dir\$#d" "$VDIR_LIST_FILE"
}

# 支持将各功能作为独立命令调用
if [ $# -gt 0 ]; then
    case "$1" in
        create-vdir) create_vdir ;;
        enter-vdir)  enter_vdir ;;
        list-vdir)   list_vdir ;;
        delete-vdir) delete_vdir ;;
        *)
            echo "未知命令: $1"
            echo "可用命令: create-vdir, enter-vdir, list-vdir, delete-vdir"
            ;;
    esac
    # 结束脚本执行
    exit 0
fi

# 交互式菜单界面
while true; do
    echo "====== Ubuntu 工具菜单 ======"
    echo "1) 创建虚拟目录 (create-vdir)"
    echo "2) 进入虚拟目录 (enter-vdir)"
    echo "3) 列出虚拟目录 (list-vdir)"
    echo "4) 删除虚拟目录 (delete-vdir)"
    echo "5) 退出"
    read -p "请选择操作 [1-5]: " opt
    case "$opt" in
        1) create_vdir ;;
        2) enter_vdir  ;;
        3) list_vdir   ;;
        4) delete_vdir ;;
        5) echo "已退出 Ubuntu 工具脚本。"; break ;;
        *) echo "无效的选项，请重新选择。" ;;
    esac
    echo    # 输出空行，美化显示
done
