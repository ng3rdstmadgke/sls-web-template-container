import json
from typing import Dict
import boto3
from functools import lru_cache
from pydantic import BaseModel

from api.env import get_env, Environment, Mode
from api.lib.logger import logger

"""
SecretsManagerに格納されているSecretsStringを構造体として取得するための関数
lru_cacheを利用することで、複数回アクセスしないようになっている
"""

class RdsSecret(BaseModel):
    db_user: str
    db_password: str
    db_host: str
    db_port: int


class JwtSecret(BaseModel):
    secret_key: str


def get_secret(secret_name: str, aws_region: str) -> Dict[str, str]:
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name = aws_region
    )
    get_secret_value_response = client.get_secret_value(
        SecretId=secret_name
    )
    return json.loads(get_secret_value_response['SecretString'])


@lru_cache
def get_rds_secret(_ttl_hash: int = -1, env: Environment = get_env()) -> RdsSecret:
    logger.info(f"get_rds_secret _ttl_hash: {_ttl_hash}")
    if env.mode is Mode.LOCAL:
        return RdsSecret(
            password="",
            dbname="",
            engine="",
            port="",
            dbInstanceIdentifier="",
            host="",
            username=""
        )
    else:
        secret = get_secret(env.db_secret_name, env.aws_region)
        return RdsSecret.parse_obj(secret)


@lru_cache
def get_jwt_secret(_ttl_hash: int = -1, env: Environment = get_env()) -> JwtSecret:
    logger.info(f"get_jwt_secret _ttl_hash: {_ttl_hash}")
    if env.mode is Mode.LOCAL:
        return JwtSecret(secret_key="abcdefg123456789")
    else:
        secret = get_secret(env.jwt_secret_name, env.aws_region)
        return JwtSecret.parse_obj(secret)