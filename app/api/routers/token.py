from datetime import timedelta
from sqlalchemy.orm import Session
from fastapi import Depends, APIRouter, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm

from api.lib import auth
from api import session
from api.crud import user as crud_user
#from api.schemas.token import TokenCreateSchema

router = APIRouter()

@router.post("/token")
def login_for_access_token(
    session: Session = Depends(session.get_session),
    form_data: OAuth2PasswordRequestForm = Depends()
):
    # OAuth2PasswordRequestForm は username, password, scope, grant_type といったメンバを持つ
    # https://fastapi.tiangolo.com/tutorial/security/simple-oauth2/#oauth2passwordrequestform
    login_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Incorrect username or password",
        headers={"WWW-Authenticate": "Bearer"},
    )
    user = crud_user.get_user_by_name(session, form_data.username)
    if user is None:
        raise login_exception
    if not auth.verify_password(form_data.password, user.hashed_password):
        raise login_exception
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        # JWT "sub" Claim : https://openid-foundation-japan.github.io/draft-ietf-oauth-json-web-token-11.ja.html#subDef
        payload={
            "sub": user.username,
            "scopes": [],
            "is_superuser": user.is_superuser,
        },
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


#@router.post("/token_json")
#def login_for_access_token_json(schema: TokenCreateSchema, session: Session = Depends(session.get_session)):
#    # OAuth2PasswordRequestForm は username, password, scope, grant_type といったメンバを持つ
#    # https://fastapi.tiangolo.com/tutorial/security/simple-oauth2/#oauth2passwordrequestform
#    login_exception = HTTPException(
#        status_code=status.HTTP_401_UNAUTHORIZED,
#        detail="Incorrect username or password",
#        headers={"WWW-Authenticate": "Bearer"},
#    )
#    user = crud_user.get_user_by_name(session, schema.username)
#    if user is None:
#        raise login_exception
#    if not auth.verify_password(schema.password, user.hashed_password):
#        raise login_exception
#    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
#    access_token = auth.create_access_token(
#        # JWT "sub" Claim : https://openid-foundation-japan.github.io/draft-ietf-oauth-json-web-token-11.ja.html#subDef
#        payload={"sub": user.username},
#        expires_delta=access_token_expires
#    )
#    return {"access_token": access_token, "token_type": "bearer"}
