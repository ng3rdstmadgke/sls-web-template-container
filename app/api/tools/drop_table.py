from api.session import engine
from api.models import Base

Base.metadata.drop_all(bind=engine)