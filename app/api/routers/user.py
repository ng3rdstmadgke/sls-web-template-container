from typing import List

from sqlalchemy.orm import Session
from fastapi import Depends, APIRouter, HTTPException

from api.lib import auth
from api import session
from api.models import User
from api.schemas.user import UserSchema, UserCreateSchema, UserUpdateSchema
from api.crud import user as crud_user

router = APIRouter()

@router.get("/users/me", response_model=UserSchema)
def read_me(current_user: User = Depends(auth.get_current_active_user)):
    return current_user

# Depends(Callable[..., Any]) は引数に取った関数を実行してその実行結果を返す。
#  Dependencies: https://fastapi.tiangolo.com/tutorial/dependencies/
@router.post("/users/", response_model=UserSchema)
def create_user(
    user_schema: UserCreateSchema,
    session: Session = Depends(session.get_session),
    _: User = Depends(auth.get_current_admin_user)
):
    user = crud_user.get_user_by_name(session, username=user_schema.username)
    if user:
        raise HTTPException(status_code=400, detail="Username already registerd")
    return crud_user.create_user(session, user_schema)

@router.get("/users/", response_model=List[UserSchema])
def read_users(
    skip: int = 0, # GETパラメータ
    limit: int = 100, # GETパラメータ
    session: Session = Depends(session.get_session),
    _: User = Depends(auth.get_current_admin_user)
):
    users = crud_user.get_users(session, skip=skip, limit = limit)
    return users

@router.get("/users/{user_id}", response_model=UserSchema)
def read_user(
    user_id: int, # URLの{user_id}プレースホルダ
    session: Session = Depends(session.get_session),
    _: User = Depends(auth.get_current_admin_user)
):
    user = crud_user.get_user(session, user_id=user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

#@router.put("/users/{user_id}/password", response_model=UserSchema)
#def update_user_password(
#    user_id: int,
#    user_schema: UserCreateSchema,
#    session: Session = Depends(session.get_session),
#    _: User = Depends(auth.get_current_admin_user)
#):
#    user = crud_user.get_user(session, user_id=user_id)
#    if user is None:
#        raise HTTPException(status_code=404, detail="User not found")
#    return crud_user.update_user_password(session, user_schema, user)

@router.put("/users/{user_id}", response_model=UserSchema)
def update_user(
    user_id: int,
    user_schema: UserUpdateSchema,
    session: Session = Depends(session.get_session),
    _: User = Depends(auth.get_current_admin_user)
):
    user = crud_user.get_user(session, user_id=user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return crud_user.update_user(session, user_schema, user)

@router.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    session: Session = Depends(session.get_session),
    _: User = Depends(auth.get_current_admin_user)
):
    user = crud_user.get_user(session, user_id=user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    crud_user.delete_user(session, user)
    return {"user_id": user_id}