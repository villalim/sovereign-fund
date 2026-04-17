import sqlite3
import os

# Caminho do banco de dados
db_path = 'fase5b_final.db'

# Verifica se o banco já existe
if os.path.exists(db_path):
    print('Banco de dados já existe. Removendo...')
    os.remove(db_path)

# Conecta ao banco de dados (cria se não existir)
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Cria tabela instances
cursor.execute('''
CREATE TABLE instances (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
''')

# Cria tabela commands
cursor.execute('''
CREATE TABLE commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    instance_id INTEGER,
    command TEXT NOT NULL,
    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (instance_id) REFERENCES instances (id)
)
''')

# Confirma as mudanças
conn.commit()

# Fecha a conexão
conn.close()

print('Banco de dados criado com sucesso!')