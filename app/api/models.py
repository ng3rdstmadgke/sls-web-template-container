from datetime import datetime
import enum
from sqlalchemy import Column, ForeignKey, Integer, String, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.mysql import MEDIUMTEXT
from sqlalchemy.sql.sqltypes import DateTime, Enum

from sqlalchemy.orm.decl_api import declarative_base
Base = declarative_base()

#
# usersテーブル
#
class User(Base):
    __tablename__ = "users"
    __table_args__ = {'mysql_engine':'InnoDB', 'mysql_charset':'utf8mb4','mysql_collate':'utf8mb4_bin'}

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(255, collation="utf8mb4_bin"), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_superuser = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created = Column(DateTime, default=datetime.now, nullable=False)
    updated = Column(DateTime, default=datetime.now, onupdate=datetime.now, nullable=False)

    # カスケード: https://docs.sqlalchemy.org/en/14/orm/cascades.html
    # 一対多のリレーション: https://docs.sqlalchemy.org/en/14/orm/basic_relationships.html#one-to-many
    # 多対多のリレーション: https://docs.sqlalchemy.org/en/14/orm/basic_relationships.html#many-to-many
    items = relationship(
        "Item",                      # リレーション先のモデルクラス名
        back_populates="user",       # リレーション先の変数名
        cascade="all, delete-orphan" # Userレコードを削除したとに関連するitemsを削除する(default="save-update")
    )


#
# itemsテーブル
#
class ItemDataFormat(str, enum.Enum):
    CSV = "CSV",
    TSV = "TSV"

class Item(Base):
    __tablename__ = "items"
    __table_args__ = {'mysql_engine':'InnoDB', 'mysql_charset':'utf8mb4','mysql_collate':'utf8mb4_bin'}
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(255, collation="utf8mb4_bin"), nullable=False, index=True)
    content = Column(MEDIUMTEXT)
    is_common = Column(Boolean, default=False, nullable=False)
    data_format = Column(Enum(ItemDataFormat), nullable=False)
    created = Column(DateTime, default=datetime.now, nullable=False)
    updated = Column(DateTime, default=datetime.now, onupdate=datetime.now, nullable=False)

    # リレーション
    user = relationship("User", back_populates="items")