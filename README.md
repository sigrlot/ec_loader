# Locust 压测代码使用说明

## 压测步骤

1. 使用 sql 构造数据，接口涉及的表和构造 sql 添加在压测方法的注释中。 //关联性数据怎么处理？

2. 逐个接口进行压测

3. 运行线上模拟场景压测，要求模拟线上接口压力分布情况

## 功能概述

这个 Locust 压测脚本基于提供的 OpenAPI 文件生成，涵盖了所有的 API 接口，包括：

### Account API 接口

- `/api/acc/account-txs` - 账户交易列表 (GET/POST)
- `/api/acc/module-transfers` - 模块转账记录
- `/api/account/address-equity-info/{address}` - 用户权益信息
- `/api/account/address-substitutable-equity/{address}` - 用户地址可置换权益
- `/api/account/balance-states/{address}` - 账户余额状态
- `/api/account/public_address` - 地址公示

### Block API 接口

- `/api/block/blocklist` - 区块列表

### Txs API 接口

- `/api/txs/hub/list` - Hub 交易列表

## 特殊功能

### 1. 动态地址生成

- 脚本包含 `generate_ec_address()` 函数，可以生成符合 Cosmos 体系的 bech32 地址（前缀为 "ec"）
- 在测试中会随机使用预定义地址和动态生成的 ec 地址

### 2. 综合测试场景

- **用户工作流测试**: 模拟真实用户的操作流程
- **分页压力测试**: 测试各种分页参数组合
- **边界值测试**: 测试极限参数值
- **ec 地址压力测试**: 专门测试对新生成地址的支持

## 使用方法

### 1. 环境准备

```bash
# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 2. 配置服务器地址

在 `WebsiteUser` 类中修改 `host` 配置：

```python
host = "http://your-server-address:port"
```

### 3. 运行压测

```bash
# 基本运行（Web UI 模式）
locust -f test_http.py

# 命令行模式运行
locust -f test_http.py --headless -u 10 -r 2 -t 60s

# 参数说明：
# -u 10: 模拟 10 个用户
# -r 2: 每秒启动 2 个用户
# -t 60s: 运行 60 秒
```

### 4. 自定义配置

#### 修改测试数据

- `accounts`: 修改账户列表
- `cleaned_data`: 修改交易哈希数据
- `addresses`: 修改地址列表

#### 调整任务权重

使用 `@task(weight)` 装饰器调整不同接口的调用频率：

```python
@task(5)  # 高频率调用
def important_api(self):
    pass

@task(1)  # 低频率调用
def less_important_api(self):
    pass
```

## 测试策略

### 1. 压力测试

- 逐步增加并发用户数
- 观察系统响应时间和错误率
- 找到系统性能瓶颈

### 2. 功能测试

- 验证所有接口正常响应
- 测试各种参数组合
- 验证边界条件处理

### 3. 稳定性测试

- 长时间运行测试
- 观察系统是否有内存泄漏
- 验证系统恢复能力

## 监控指标

关注以下关键指标：

- **响应时间**: 平均响应时间、95% 百分位数
- **吞吐量**: 每秒请求数 (RPS)
- **错误率**: 失败请求百分比
- **并发能力**: 最大支持的并发用户数

## 注意事项

1. **数据准备**: 确保 `data/hash.txt` 和 `data/addresses.txt` 文件存在且包含有效数据
2. **网络连接**: 确保测试机器能正常访问目标服务器
3. **资源监控**: 同时监控服务器端的 CPU、内存、数据库等资源使用情况
4. **测试环境**: 建议在专用测试环境中进行，避免影响生产环境

## 扩展说明

如需添加新的测试场景：

1. 在 `UserBehavior` 类中添加新的方法
2. 使用 `@task` 装饰器标记
3. 遵循现有的错误处理模式
4. 添加适当的测试数据和参数

例如：

```python
@task(1)
def new_api_test(self):
    url = f'{self.user.host}/api/new-endpoint'
    with self.client.get(url, catch_response=True) as response:
        if response.status_code == 200:
            response.success()
        else:
            response.failure("new_api_test error")
```
