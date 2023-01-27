from pydantic import BaseModel

class UserSchemaBase(BaseModel):
    """Userの参照・作成で共通して必要になるメンバを定義したスキーマ"""
    username: str

class UserCreateSchema(UserSchemaBase):
    """User作成時に利用されるスキーマ"""
    password: str

class UserUpdateSchema(UserSchemaBase):
    is_superuser: bool
    is_active: bool

class UserSchema(UserSchemaBase):
    """Userの参照時や、APIからの返却データとして利用されるスキーマ"""
    id: int
    is_superuser: bool
    is_active: bool
    
    class Config:
        orm_mode = True