from sqlmodel import Session, create_engine
from core.config import settings

# El motor de la base de datos.
# La URL de conexión la toma de la configuración central.
# echo=True hace que SQLAlchemy imprima todas las sentencias SQL que ejecuta.
# Es muy útil para depurar.
engine = create_engine(settings.database_url, echo=True)

def get_session():
    """
    Dependencia de FastAPI que crea y proporciona una sesión de base de datos
    por cada petición y la cierra al terminar.
    """
    with Session(engine) as session:
        yield session
