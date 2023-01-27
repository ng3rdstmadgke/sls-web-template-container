from functools import lru_cache
from pydantic import BaseSettings
import enum

class Mode(str, enum.Enum):
    PRD = "prd"
    STG = "stg"
    DEV = "dev"
    LOCAL = "local"

class Environment(BaseSettings):
    """環境変数を定義する構造体。
    """
    stage_name: str
    aws_region: str = "ap-northeast-1"
    api_gateway_base_path: str = ""
    mode: Mode
    db_secret_name: str
    jwt_secret_name: str

@lru_cache
def get_env() -> Environment:
    """環境変数を読み込んでEnvironmentオブジェクトを生成する。
    Environmentオブジェクトはlru_cacheで保持されるため、何回も読み込まない

    fastAPIによる環境変数の読み込み: https://fastapi.tiangolo.com/advanced/settings/#environment-variables
    """
    return Environment()