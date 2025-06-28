import os

from bech32 import bech32_encode, convertbits


def generate_ec_address():
    """
    生成 cosmos 体系的 bech32 地址，前缀为 ec
    """
    # 随机生成 20 字节的公钥哈希
    data = os.urandom(20)
    # 转换为 5 bit 分组
    bech32_data = convertbits(data, 8, 5)
    # 生成 bech32 地址
    address = bech32_encode('ec', bech32_data)
    return address