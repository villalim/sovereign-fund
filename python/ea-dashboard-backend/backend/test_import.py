#!/usr/bin/env python
"""Script para testar imports e configurações"""

import sys
import traceback

print("=" * 60)
print("🔍 TESTE DE IMPORTS - EA DASHBOARD BACKEND")
print("=" * 60)

# Test 1: Python version
print(f"\n✓ Python Version: {sys.version}")
print(f"✓ Python Executable: {sys.executable}")

# Test 2: Verify working directory
import os
print(f"✓ Current Working Directory: {os.getcwd()}")

# Test 3: Check if required files exist
required_files = [
    ".env",
    "config/__init__.py",
    "routes/__init__.py",
    "models/__init__.py",
    "database/__init__.py",
    "services/__init__.py"
]

print("\n📁 Verificando arquivos necessários:")
for file in required_files:
    exists = os.path.exists(file)
    status = "✓" if exists else "✗"
    print(f"  {status} {file}")

# Test 4: Try importing config
print("\n📦 Testando imports:")
try:
    print("  → Importando config.settings...")
    from config.settings import settings
    print(f"    ✓ DEBUG={settings.DEBUG}")
    print(f"    ✓ BACKEND_PORT={settings.BACKEND_PORT}")
except Exception as e:
    print(f"    ✗ ERRO: {str(e)}")
    traceback.print_exc()

# Test 5: Try importing FastAPI
try:
    print("  → Importando FastAPI...")
    from fastapi import FastAPI
    print(f"    ✓ FastAPI importado com sucesso")
except Exception as e:
    print(f"    ✗ ERRO: {str(e)}")
    traceback.print_exc()

# Test 6: Try importing database
try:
    print("  → Importando database...")
    from database.database import init_db
    print(f"    ✓ Database importado com sucesso")
except Exception as e:
    print(f"    ✗ ERRO: {str(e)}")
    traceback.print_exc()

# Test 7: Try importing routes
try:
    print("  → Importando routes...")
    from routes.ea_receiver import router as ea_receiver_router
    print(f"    ✓ Routes importadas com sucesso")
except Exception as e:
    print(f"    ✗ ERRO: {str(e)}")
    traceback.print_exc()

print("\n" + "=" * 60)
print("✅ TESTE CONCLUÍDO")
print("=" * 60)