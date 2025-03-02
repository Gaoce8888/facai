#!/bin/bash
set -e

# 确保以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 权限运行此脚本: sudo bash install.sh"
    exit 1
fi

# 定义仓库地址
REPO_URL="https://raw.githubusercontent.com/Gaoce8888/facai/main/99.sh"

# 下载 ubuntu_helper.sh
echo "正在下载 Ubuntu Helper..."
curl -o /usr/local/bin/99.sh -fsSL "$REPO_URL"

# 赋予执行权限
chmod +x /usr/local/bin/ubuntu_helper.sh

# 创建快捷方式
echo -e "#!/bin/bash\nsudo bash /usr/local/bin/99.sh" > /usr/local/bin/ubuntu-helper
chmod +x /usr/local/bin/ubuntu-helper

echo "✅ Ubuntu Helper 安装完成！"
echo "现在你可以输入 'ubuntu-helper' 在终端中运行该工具！"
