cat << 'EOF' > setup_swap.sh
#!/bin/bash

# 设置 Swap 大小 (GB)，默认 2GB
SWAP_SIZE_GB=2
SWAP_PATH="/swapfile"

echo "--- 开始配置虚拟内存 (Swap: ${SWAP_SIZE_GB}GB) ---"

# 1. 检查是否已经存在 Swap
if [ $(swapon --show | wc -l) -gt 0 ]; then
    echo "错误: 检测到已存在 Swap，请手动检查。脚本退出。"
    exit 1
fi

# 2. 创建 Swap 文件 (使用 fallocate 更快，dd 作为备选)
echo "正在分配空间..."
if command -v fallocate &> /dev/null; then
    sudo fallocate -l ${SWAP_SIZE_GB}G $SWAP_PATH
else
    sudo dd if=/dev/zero of=$SWAP_PATH bs=1024M count=$SWAP_SIZE_GB
fi

# 3. 设置权限
echo "设置文件权限..."
sudo chmod 600 $SWAP_PATH

# 4. 设置 Swap 区域
echo "初始化 Swap..."
sudo mkswap $SWAP_PATH

# 5. 启用 Swap
echo "激活 Swap..."
sudo swapon $SWAP_PATH

# 6. 设置开机自启
echo "设置开机自启..."
if ! grep -q "$SWAP_PATH" /etc/fstab; then
    echo "$SWAP_PATH swap swap defaults 0 0" | sudo tee -a /etc/fstab
fi

# 7. 优化 Swappiness (可选：改为 10，让系统优先使用内存)
echo "优化 Swappiness 参数..."
sudo sysctl vm.swappiness=10
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf

echo "--- Swap 配置完成！ ---"
free -h
EOF
