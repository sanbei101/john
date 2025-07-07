# set -e  # 遇到错误立即退出
# set -u  # 禁止使用未定义变量

# # 定义变量
JOHN_DIR="john-the-ripper"  # 
JOHN_REPO="https://gitee.com/sanbei101/john.git"  # 官方仓库地址
DEPENDENCIES=(
    git build-essential autoconf libssl-dev libnss3-dev libkrb5-dev
    libgmp-dev libz-dev libbz2-dev python3 libpcap-dev
)  # 依赖包列表

# 1. 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用 root 权限运行脚本(sudo ./compile_john.sh)"
    exit 1
fi

# 2. 安装依赖
echo "===== 开始安装依赖包 ====="
apt update -y
apt install -y "${DEPENDENCIES[@]}" || {
    echo "错误：依赖包安装失败"
    exit 1
}

# 3. 克隆源码（若目录已存在则更新）
echo -e "\n===== 开始获取 John 源码 ====="
if [ -d "$JOHN_DIR" ]; then
    echo "检测到已有源码目录，更新代码..."
    cd "$JOHN_DIR" && git pull && cd ..
else
    echo "克隆源码仓库..."
    git clone "$JOHN_REPO" --depth=1 "$JOHN_DIR" || {
        echo "错误:源码克隆失败"
        exit 1
    }
fi

# 4. 进入源码 src 目录并编译
echo -e "\n===== 开始编译 John ====="
cd "$JOHN_DIR/src" || {
    echo "错误:进入 src 目录失败"
    exit 1
}

# 清理旧编译
make clean

# 配置并编译
./configure 
if [ $? -ne 0 ]; then
    echo "错误:configure 配置失败"
    exit 1
fi

make -s -j"$(nproc)"
if [ $? -ne 0 ]; then
    echo "错误:make 编译失败"
    exit 1
fi
# 5. 验证编译结果
echo -e "\n===== 验证编译结果 ====="
cd ../run || {
    echo "错误：进入 run 目录失败"
    exit 1
}

if [ -f "./john" ]; then
    echo "编译成功!John 可执行文件路径：$(pwd)/john"
    echo "运行测试命令验证功能："
    echo "  ./john --test"
else
    echo "错误：编译后未找到 john 可执行文件"
    exit 1
fi

echo -e "\n===== 操作完成 ====="
echo "使用方法："
echo "  1. 进入 run 目录:cd $(pwd)"
echo "  2. 运行 John:./john [选项] [目标文件]"
echo "  3. 例如破解 zip 密码：./zip2john 目标.zip > hash.txt && ./john hash.txt"