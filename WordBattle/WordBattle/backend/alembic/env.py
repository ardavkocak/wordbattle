import sys
import os
from logging.config import fileConfig
import sys, os
import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.models import Base

from sqlalchemy import create_engine, pool
from alembic import context
from app.models import Base

# Alembic Config
config = context.config

# Python yolunu ayarla (app dizinini görmesi için)
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Loglama
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# SQLAlchemy metadata
target_metadata = Base.metadata

# MSSQL bağlantısını burada kuruyoruz (çift escape dikkat!)
mssql_url = (
    "mssql+pyodbc:///?odbc_connect="
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=LAPTOP-5PISAT6S\\SQLEXPRESS;"
    "DATABASE=WordBattle;"
    "Trusted_Connection=yes;"
)

def run_migrations_offline() -> None:
    """Offline migration"""
    context.configure(
        url=mssql_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Online migration"""
    connectable = create_engine(mssql_url, poolclass=pool.NullPool)

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
