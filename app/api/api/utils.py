import time
import boto3
import json
from typing import Dict
import boto3
from functools import lru_cache
from pydantic import BaseModel
from .env import get_env, Mode, Environment
from .logger import logger

class RdsSecret(BaseModel):
    db_user: str
    db_password: str
    db_host: str
    db_port: str

class JwtSecret(BaseModel):
    secret_key: str

class Utils:
    @staticmethod
    def get_ttl_hash(seconds: int = 600) -> int:
        """Return the same value withing `seconds` time period"""
        return round(time.time() / seconds)

    @staticmethod
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

    @staticmethod
    @lru_cache
    def get_db_secret( _ttl_hash: int = -1, env: Environment = get_env()) -> RdsSecret:
        logger.info(f"get_db_secret _ttl_hash: {_ttl_hash}")
        if (env.mode == Mode.LOCAL):
            secret = {
                "db_user": "test_admin",
                "db_password": "admin1234",
                "db_host": "127.0.0.1",
                "db_port": "53361",
            }
        else:
            secret = Utils.get_secret(env.db_secret_name, env.aws_region)
        # logger.info(secret)
        return RdsSecret.parse_obj(secret)


    @staticmethod
    @lru_cache
    def get_jwt_secret(_ttl_hash: int = -1, env: Environment = get_env()) -> JwtSecret:
        logger.info(f"get_jwt_secret _ttl_hash: {_ttl_hash}")
        if (env.mode == Mode.LOCAL):
            secret = {
                "secret_key": "0123456789abcdef",
            }
        else:
            secret = Utils.get_secret(env.jwt_secret_name, env.aws_region)
        # logger.info(secret)
        return JwtSecret.parse_obj(secret)