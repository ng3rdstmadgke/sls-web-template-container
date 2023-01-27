import traceback
from typing import Optional
from datetime import datetime, timedelta

from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordBearer
from fastapi import Depends, HTTPException, status
from passlib.context import CryptContext
from jose import jwt, JWTError

from api import session
from api.models import User
from api.schemas.token import TokenDataSchema
from api.lib.utils import Utils
from api.lib.logger import logger

SECRET_KEY = Utils.get_jwt_secret().secret_key
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2PasswordBearerのインスタンスはDependencyとして利用される
# RequestのAuthorizationヘッダを探し、値が `Bearer {token}` 形式であることを確認し、tokenをstrで返す
# 引数の tokenUrl には token を取得するURLを指定する。(swagger UIのAuthorizeの宛先になる)
# もしAuthorizationヘッダがなかったり、 値の形式が異なっていた場合は、401ステータスエラー(UNAUTHORIZED)を返す。
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/token")
# oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/token_json")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """plain_passwordが正しいパスワードかを検証する

    Args:
        plain_password (str): 検証したいパスワード(平文)
        hashed_password (str): ハッシュ化されたパスワード

    Returns:
        bool: 正しいパスワードならTrue, そうでないならFalse
    """
    return pwd_context.verify(plain_password, hashed_password)
    # plain_passwordをそのまま引き渡して問題ない

def get_password_hash(plain_password: str) -> str:
    """入力されたパスワードをハッシュ化する

    Args:
        plain_password (str): ハッシュ化したいパスワード

    Returns:
        str: ハッシュ化されたパスワード
    """
    return pwd_context.hash(plain_password)


def create_access_token(payload: dict, expires_delta: Optional[timedelta] = None) -> str:
    """入力されたpayloadでJWTを生成する。

    Args:
        payload (dict): JWTのペイロード部分のデータ
        expires_delta (Optional[timedelta], optional): JWTの有効期限

    Returns:
        str: エンコード済みJWT(<ヘッダー>.<ペイロード>.<署名>)
    """
    to_encode = payload.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def get_current_user(session: Session = Depends(session.get_session), token: str = Depends(oauth2_scheme)) -> User:
    """JWTの署名検証を行い、subに格納されているusernameからUserオブジェクトを取得する
    引数のtokenには "/api/v1/token" でリターンした access_token が格納されている

    Args:
        session (Session, optional): dbセッション
        token (str, optional): エンコード済みJWT

    Raises:
        HTTPException: 署名の検証に失敗した場合や、ユーザーが存在しない場合の例外
    Returns:
        User: 認証済みUserオブジェクト
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid authentication credentials",
        headers={"WWW-Authenticate": "Bearer"}
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload["sub"]
        if username is None:
            logger.info("user not exists in JWT")
            raise credentials_exception
        token_data = TokenDataSchema(username=username)
    except JWTError:
        logger.warning(traceback.format_exc())
        raise credentials_exception
    user = session.query(User).filter(User.username == username).first()
    if user is None:
        logger.info(f"user not exists in DB (username={username})")
        raise credentials_exception
    return user

def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """is_activeがTrueのユーザーを返す

    Args:
        current_user (User, optional): 現在のユーザー

    Raises:
        HTTPException: current_userのis_activeがFalseの場合の例外

    Returns:
        User: is_active = TrueのUser
    """
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


def get_current_admin_user(current_user: User = Depends(get_current_user)) -> User:
    """is_superuserがTrueのユーザーを返す

    Args:
        current_user (User, optional): 現在のユーザー

    Raises:
        HTTPException: current_userのis_superuserがFalseの場合の例外

    Returns:
        User: is_superuser = TrueのUser
    """
    if not current_user.is_active:
        logger.info(f"user is not active (username={current_user.username})")
        raise HTTPException(status_code=400, detail="Inactive user")
    if not current_user.is_superuser:
        logger.info(f"user is not superuser (username={current_user.username})")
        raise HTTPException(
            status_code=401,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"}
        )
    return current_user