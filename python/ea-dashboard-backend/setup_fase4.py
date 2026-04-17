import os
import subprocess
import sys
import platform
from pathlib import Path

# ANSI colors
def color_text(text, color):
    colors = {
        'red': '\033[91m',
        'green': '\033[92m',
        'yellow': '\033[93m',
        'blue': '\033[94m',
        'reset': '\033[0m'
    }
    return f"{colors.get(color, '')}{text}{colors.get('reset', '')}"

# Cross-platform path handling
def run_command(command, cwd=None):
    try:
        result = subprocess.run(command, shell=True, cwd=cwd, capture_output=True, text=True)
        if result.returncode != 0:
            print(color_text(f"Erro ao executar: {command}\n{result.stderr}", 'red'))
        else:
            print(color_text(f"Sucesso: {command}", 'green'))
        return result.returncode == 0
    except Exception as e:
        print(color_text(f"Exceção: {e}", 'red'))
        return False

# Create directories
def create_structure():
    dirs = ['backend', 'dashboard', 'data']
    for d in dirs:
        Path(d).mkdir(exist_ok=True)
        print(color_text(f"Criado: {d}/", 'blue'))

# Create files
def create_files():
    # Backend files
    backend_files = {
        'backend/config.py': '''# Configurações do backend
DATABASE_URL = "sqlite:///data/app.db"
SECRET_KEY = "your-secret-key"
''',
        'backend/models.py': '''from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)
''',
        'backend/app.py': '''from flask import Flask
from config import DATABASE_URL
from models import db

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
db.init_app(app)

@app.route('/')
def home():
    return "Backend running!"

if __name__ == '__main__':
    app.run(debug=True)
''',
        'backend/requirements.txt': '''Flask
Flask-SQLAlchemy
'''
    }
    # Dashboard files (assuming similar structure, e.g., for a simple Flask dashboard)
    dashboard_files = {
        'dashboard/app.py': '''from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return "Dashboard running!"

if __name__ == '__main__':
    app.run(debug=True, port=5001)
''',
        'dashboard/requirements.txt': '''Flask
'''
    }
    all_files = {**backend_files, **dashboard_files}
    for file_path, content in all_files.items():
        Path(file_path).write_text(content)
        print(color_text(f"Criado: {file_path}", 'blue'))

# Install dependencies
def install_deps():
    print(color_text("Instalando dependências do backend...", 'yellow'))
    run_command("pip install -r requirements.txt", cwd="backend")
    print(color_text("Instalando dependências do dashboard...", 'yellow'))
    run_command("pip install -r requirements.txt", cwd="dashboard")

# Initialize DB
def init_db():
    print(color_text("Inicializando banco de dados...", 'yellow'))
    # Assuming backend has the models
    run_command("python -c \"from backend.app import app, db; app.app_context().push(); db.create_all()\"")
    print(color_text("BD inicializado.", 'green'))

# Run servers
def run_backend():
    print(color_text("Iniciando backend...", 'yellow'))
    subprocess.Popen([sys.executable, "app.py"], cwd="backend")

def run_dashboard():
    print(color_text("Iniciando dashboard...", 'yellow'))
    subprocess.Popen([sys.executable, "app.py"], cwd="dashboard")

# Main menu
def main():
    print(color_text("=== Setup Automático FASE 4 ===", 'green'))
    print("1) Setup only")
    print("2) Backend + Dashboard")
    print("3) Backend only")
    print("4) Dashboard only")
    choice = input("Escolha uma opção: ")
    
    if choice in ['1', '2', '3', '4']:
        create_structure()
        create_files()
        install_deps()
        init_db()
        
        if choice == '1':
            print(color_text("Setup concluído.", 'green'))
        elif choice == '2':
            run_backend()
            run_dashboard()
        elif choice == '3':
            run_backend()
        elif choice == '4':
            run_dashboard()
    else:
        print(color_text("Opção inválida.", 'red'))

if __name__ == '__main__':
    main()