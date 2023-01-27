from typing import Optional
from sqlalchemy.orm import Session

from api.lib import auth
from api.models import User
from api.schemas.user import UserCreateSchema, UserUpdateSchema

# Session API: https://docs.sqlalchemy.org/en/14/orm/session_api.html#sqlalchemy.orm.Session
# Query API: https://docs.sqlalchemy.org/en/14/orm/query.html#sqlalchemy.orm.Query

def get_user(session: Session, user_id: int) -> Optional[User]:
    return session.query(User).filter(User.id == user_id).first()

def get_user_by_name(session: Session, username: str) -> Optional[User]:
    return session.query(User).filter(User.username == username).first()

def get_users(session: Session, skip: int = 0, limit: int = 100):
    return session.query(User).offset(skip).limit(limit).all()

def create_user(session: Session, user_schema: UserCreateSchema) -> User:
    hashed_password = auth.get_password_hash(user_schema.password)
    user = User(
        username=user_schema.username,
        hashed_password=hashed_password,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

def create_user_if_not_exists(session: Session, user_schema: UserCreateSchema) -> User:
    user = session.query(User).filter(User.username == user_schema.username).first()
    if user is not None:
        return user
    hashed_password = auth.get_password_hash(user_schema.password)
    user = User(
        username=user_schema.username,
        hashed_password=hashed_password,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

def update_user_password(session: Session, user_schema: UserCreateSchema, user: User) -> User:
    user.username = user_schema.username
    user.hashed_password = auth.get_password_hash(user_schema.password)
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

def update_user(session: Session, user_schema: UserUpdateSchema, user: User) -> User:
    user.username = user_schema.username
    user.is_superuser = user_schema.is_superuser
    user.is_active = user_schema.is_active
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

def delete_user(session: Session, user: User):
    session.delete(user)
    session.commit()