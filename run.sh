#!/bin/bash

# Locust 压测启动脚本

echo "=== Locust 压测工具启动脚本 ==="

# 检查虚拟环境
if [ ! -d "venv" ]; then
    echo "创建虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
echo "激活虚拟环境..."
source venv/bin/activate

# 安装依赖
echo "安装依赖..."
pip install -r requirements.txt

# 检查数据文件
if [ ! -f "data/hash.txt" ]; then
    echo "警告: data/hash.txt 文件不存在，创建示例文件..."
    mkdir -p data
    echo -e "hash1\nhash2\nhash3" > data/hash.txt
fi

if [ ! -f "data/addresses.txt" ]; then
    echo "警告: data/addresses.txt 文件不存在，创建示例文件..."
    mkdir -p data
    echo -e "me1example1\nme1example2\nme1example3" > data/addresses.txt
fi

echo "=== 启动选项 ==="
echo "1. Web UI 模式 (推荐)"
echo "2. 命令行模式 - 轻量级测试"
echo "3. 命令行模式 - 压力测试"
echo "4. 命令行模式 - 自定义参数"

read -p "请选择启动模式 (1-4): " choice

case $choice in
    1)
        echo "启动 Web UI 模式..."
        echo "浏览器访问 http://localhost:8089 来配置和监控测试"
        locust -f test_http.py
        ;;
    2)
        echo "启动轻量级测试 (10用户, 持续30秒)..."
        locust -f test_http.py --headless -u 10 -r 2 -t 30s
        ;;
    3)
        echo "启动压力测试 (20用户, 持续1分钟)..."
        locust -f test_http.py --headless -u 20 -r 5 -t 60s
        ;;
    4)
        read -p "用户数量: " users
        read -p "每秒启动用户数: " spawn_rate
        read -p "运行时间(如: 60s, 5m): " run_time
        echo "启动自定义测试..."
        locust -f test_http.py --headless -u $users -r $spawn_rate -t $run_time
        ;;
    *)
        echo "无效选择，启动 Web UI 模式..."
        locust -f test_http.py
        ;;
esac
