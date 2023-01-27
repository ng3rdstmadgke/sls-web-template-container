from api.session import engine
from api.models import Base

Base.metadata.create_all(bind=engine)