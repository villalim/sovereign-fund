import sqlite3

# Conectar ao banco de dados SQLite
db_path = 'database.db'
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Inserir dados de teste na tabela instances
dados_teste = [
    (1, 'MT5-Instance-01', 'active'),
    (2, 'MT5-Instance-02', 'active'),
    (3, 'MT5-Instance-03', 'active')
]

for dado in dados_teste:
    cursor.execute('''
        INSERT INTO instances (id, name, status)
        VALUES (?, ?, ?)
    ''', dado)

# Confirmar as inserções
conn.commit()

# Verificar dados inseridos
cursor.execute('SELECT * FROM instances')
rows = cursor.fetchall()
print('Dados inseridos na tabela instances:')
for row in rows:
    print(row)

# Fechar conexão
conn.close()

# Mensagem de sucesso
print('Script executado com sucesso! Dados de teste inseridos e verificados.')