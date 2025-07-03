import random
import logging

from locust import TaskSet, task, HttpUser, tag

MAX_OFFSET = 9970
MAX_LIMIT = 20
MAX_BLOCK_HEIGHT = 600000

logging.getLogger("locust.stats_logger").setLevel(logging.WARNING)

def random_offset():    
    """获取随机偏移量"""
    # return 0
    return random.randint(0, MAX_OFFSET)

def random_limit():
    """获取随机限制"""
    return random.randint(1, MAX_LIMIT)

def random_block_height():
    """获取随机区块高度"""
    return random.randint(1, MAX_BLOCK_HEIGHT)


class UserBehavior(TaskSet):

    # 账户地址列表
    addr_path = 'data/address.txt'
    with open(addr_path, 'r', encoding='utf-8') as file_data:
        addr_data = file_data.readlines()
        addresses = [s.strip() for s in addr_data]

    # 区块hash列表
    block_path = 'data/block_hash.txt'
    with open(block_path, 'r', encoding='utf-8') as file_data:
        block_data = file_data.readlines()
        block_hashes = [s.strip() for s in block_data]

    # 交易hash列表
    tx_path = './data/tx_hash.txt'
    with open(tx_path, 'r', encoding='utf-8') as file_data:
        tx_data = file_data.readlines()
        tx_hashes = [s.strip() for s in tx_data]
    
    # 验证人地址列表
    validator_path = './data/validator.txt'
    with open(validator_path, 'r', encoding='utf-8') as file_data:
        validator_data = file_data.readlines()
        validators = [s.strip() for s in validator_data]


    # ===== PROTO API =====

    # Block API 接口测试
    @tag('block_list')
    @task(0)
    def block_list(self):
        """区块列表"""
        params = {
            "offset": random_offset(),
            "limit": random_limit(),
            "key": ""
        }
        url = f'{self.user.host}/api/block/blocklist'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    # Txs API 接口测试
    @tag('tx_list')
    @task(0)
    def tx_list(self):
        """Hub交易列表"""
        data = {
            "limit": random_limit(),
            "offset": random_offset(),
            "msgTypeNin": random.choice(["", "StakeEc", "Transfer"]),
            "key": ""
        }
        url = f'{self.user.host}/api/txs/hub/list'
        with self.client.post(url, json=data, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    # Account API 接口测试
    @tag('account_txs_get')
    @task(0)
    def account_txs_get(self):
        """账户交易列表 - GET"""
        address = random.choice(self.addresses)
        params = {
            "offset": random_offset(),
            "limit": random_limit()
        }
        url = f'{self.user.host}/api/acc/account-txs/{address}'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('account_txs_post')
    @task(0)
    def account_txs_post(self):
        """账户交易列表 - POST"""
        data = {
            "address": random.choice(self.addresses),
            "offset": random_offset(),
            "limit": random_limit()
        }
        url = f'{self.user.host}/api/acc/account-txs'
        with self.client.post(url, json=data, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('account_module_transfers')
    @task(0)
    def account_module_transfers(self):
        """模块转账记录"""
        params = {
            "address": random.choice(self.addresses),
            "net_type": "hub",
            "limit": str(random_limit()),
            "offset": str(random_offset()),
            "key": ""
        }
        url = f'{self.user.host}/api/acc/module-transfers'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('account_equity_info')
    @task(0)
    def account_equity_info(self):
        """用户权益信息"""
        address = random.choice(self.addresses)
        
        url = f'{self.user.host}/api/account/address-equity-info/{address}'
        with self.client.get(url, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('account_substitutable_equity')
    @task(1)
    def account_substitutable_equity(self):
        """用户地址可置换权益"""
        address = random.choice(self.addresses)
        url = f'{self.user.host}/api/account/address-substitutable-equity/{address}'
        with self.client.get(url, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('account_balance_states')
    @task(1)
    def account_balance_states(self):
        """账户余额状态"""
        address = random.choice(self.addresses)
        params = {}
        # 随机添加可选参数
        # if random.choice([True, False]):
        #     params["denom"] = "uec"
        # if random.choice([True, False]):
        #     params["coin"] = "uec"
        
        url = f'{self.user.host}/api/account/balance-states/{address}'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('public_address')
    @task(0)
    def public_address(self):
        """地址公示"""
        url = f'{self.user.host}/api/account/public_address'
        with self.client.get(url, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")


    # ===== HASURA 接口测试 =====
    
    # Home REST API
    @tag('liquidity_info')
    @task(0)
    def home_liquidity_info(self):
        """流通量信息"""
        url = f'{self.user.host}/api/rest/home/liquidity_info'
        with self.client.get(url, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('query_exists')
    @task(1)
    def home_query_exists(self):
        """查询key是否存在"""
        # 随机选择不同类型的key进行测试
        # 注意：是否需要单项key测试？
        keys = [
            random.choice(self.addresses),  # 地址
            random.choice(self.tx_hashes),  # 交易哈希
            random.choice(self.block_hashes),  # 区块哈希
            random_block_height(),  # 区块高度
            random.choice(self.validators),  # 验证人地址
        ]
        params = {
            "key": random.choice(keys)
        }
        url = f'{self.user.host}/api/rest/home/query_exists'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")


    @tag('block_detail_get')
    @task(0)
    def block_detail_get(self):
        """区块详情 (GET)"""
        rp = random.choice([True, False])
        params = {"hash": random.choice(self.block_hashes)} if rp else {"height": random_block_height()}
        url = f'{self.user.host}/api/rest/block/detail'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    # @task(0)
    # def block_detail_post(self):
    #     """区块详情 (POST)"""
    #     data = {
    #         "height": random_block_height(),
    #         "hash": ""
    #     }
    #     url = f'{self.user.host}/api/rest/block/detail'
    #     with self.client.post(url, json=data, catch_response=True) as response:
    #         if response.status_code == 200:
    #             response.success()
    #         else:
    #             response.failure("rest_block_detail_post error")

    @tag('block_raw_log')
    @task(0)
    def block_raw_log(self):
        """区块原始日志"""
        data = {
            "height": random_block_height()
        }
        url = f'{self.user.host}/api/rest/block/raw_log'
        with self.client.get(url, json=data, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('block_txs')
    @task(0)
    def block_txs(self):
        """区块交易列表"""
        data = {
            "height": random_block_height(),
            "limit": random_limit(),
            "offset": random_offset()
        }
        url = f'{self.user.host}/api/rest/block/txs'
        with self.client.get(url, json=data, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('block_module_transfers')
    @task(0)
    def block_module_transfers(self):
        """区块模块转账"""
        data = {
            "height": random_block_height(),
            "limit": random_limit(),
            "offset": random_offset()
        }
        url = f'{self.user.host}/api/rest/block/module/transfers'
        with self.client.post(url, json=data, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    # Transaction REST API
    @tag('tx_detail')
    @task(0)
    def tx_detail(self):
        """交易详情"""
        params = {
            "hash": random.choice(self.tx_hashes) if self.tx_hashes else "test_hash"
        }
        url = f'{self.user.host}/api/rest/tx/detail'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")


    # @tag('tx_detail_with_address_get')
    # @task(0)
    # def tx_detail_with_address_get(self):
    #     """带地址的交易详情 (GET)"""
    #     params = {
    #         "hash": random.choice(self.tx_hashes) if self.tx_hashes else "test_hash"
    #     }
    #     url = f'{self.user.host}/api/rest/tx/detail_with_address'
    #     with self.client.get(url, params=params, catch_response=True) as response:
    #         if response.status_code == 200:
    #             response.success()
    #         else:
    #             response.failure(f"Error {response.status_code}: {response.text}")

    # @task(0)
    # def tx_detail_with_address_post(self):
    #     """带地址的交易详情 (POST)"""
    #     data = {
    #         "hash": random.choice(self.txs) if self.txs else "test_hash",
    #         "msg_with_address": [random.choice(self.addres)]
    #     }
    #     url = f'{self.user.host}/api/rest/tx/detail_with_address'
    #     with self.client.post(url, json=data, catch_response=True) as response:
    #         if response.status_code == 200:
    #             response.success()
    #         else:
    #             response.failure("rest_tx_detail_with_address_post error")

    @tag('tx_raw_log')
    @task(0)
    def tx_raw_log(self):
        """交易原始日志"""
        params = {
            "hash": random.choice(self.tx_hashes) if self.tx_hashes else "test_hash"
        }
        url = f'{self.user.host}/api/rest/tx/raw_log'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('tx_asset_change_log')
    @task(0)
    def tx_asset_change_log(self):
        """交易资产变化日志"""
        params = {
            "address": random.choice(self.addresses),
            "tx_hash": random.choice(self.tx_hashes) if self.tx_hashes else "test_hash"
        }
        url = f'{self.user.host}/api/rest/tx/asset_change_log'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    # Account REST API
    @tag('account_module_addresses')
    @task(0)
    def account_module_addresses(self):
        """模块账户地址列表"""
        url = f'{self.user.host}/api/rest/account/module/addresses'
        with self.client.get(url, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('account_detail')
    @task(0)
    def account_detail(self):
        """账户详情"""
        params = {
            "address": random.choice(self.addresses)
        }
        url = f'{self.user.host}/api/rest/account/detail'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('account_staking_records')
    @task(0)
    def account_staking_records(self):
        """账户权益变更记录"""
        params = {
            "address": random.choice(self.addresses),
            "limit": random_limit(),
            "offset": random_offset()
        }
        url = f'{self.user.host}/api/rest/account/staking_records'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    # Validator REST API
    @tag('validator_detail')
    @task(0)
    def validator_detail(self):
        """验证节点详情"""
        params = {
            "validator_address": random.choice(self.validators)
        }
        url = f'{self.user.host}/api/rest/validator/detail'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('validator_statistic')
    @task(0)
    def validator_statistic(self):
        """验证节点统计"""
        url = f'{self.user.host}/api/rest/validator/statistic'
        with self.client.get(url, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")

    @tag('validator_blocks')
    @task(0)
    def validator_blocks(self):
        """验证节点区块列表"""
        params = {
            "validator_address": random.choice(self.validators),
            "limit": random_limit(),
            "offset": random_offset()
        }
        url = f'{self.user.host}/api/rest/validator/blocks'
        with self.client.get(url, params=params, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Error {response.status_code}: {response.text}")


class WebsiteUser(HttpUser):
    host = "http://192.168.0.100:8000"
    tasks = [UserBehavior]