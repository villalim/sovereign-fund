import time
import requests

# Cores ANSI
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

# Configurações
BACKEND_URL = 'http://localhost:8000'  # Substitua pela URL real do backend

# Função para imprimir com cor
def print_colored(message, color):
    print(f'{color}{message}{RESET}')

# Relatório de status
test_results = []

def log_test(step, success, details=''):
    status = 'PASSOU' if success else 'FALHOU'
    color = GREEN if success else RED
    print_colored(f'{step}: {status} - {details}', color)
    test_results.append({'step': step, 'status': status, 'details': details})

# 1. Verificar saúde do backend
def check_backend_health():
    try:
        response = requests.get(f'{BACKEND_URL}/health', timeout=5)
        if response.status_code == 200:
            log_test('Verificar saúde do backend', True, 'Backend saudável')
            return True
        else:
            log_test('Verificar saúde do backend', False, f'Status code: {response.status_code}')
            return False
    except Exception as e:
        log_test('Verificar saúde do backend', False, str(e))
        return False

# 2. Enviar heartbeat de teste
def send_test_heartbeat():
    try:
        data = {'type': 'heartbeat', 'timestamp': time.time()}
        response = requests.post(f'{BACKEND_URL}/heartbeat', json=data, timeout=5)
        if response.status_code == 200:
            log_test('Enviar heartbeat de teste', True, 'Heartbeat enviado')
            return True
        else:
            log_test('Enviar heartbeat de teste', False, f'Status code: {response.status_code}')
            return False
    except Exception as e:
        log_test('Enviar heartbeat de teste', False, str(e))
        return False

# 3. Verificar se heartbeat foi recebido
def verify_heartbeat_received():
    time.sleep(2)  # Simular espera
    try:
        response = requests.get(f'{BACKEND_URL}/heartbeat/status', timeout=5)
        if response.status_code == 200 and response.json().get('received'):
            log_test('Verificar se heartbeat foi recebido', True, 'Heartbeat recebido')
            return True
        else:
            log_test('Verificar se heartbeat foi recebido', False, 'Heartbeat não recebido')
            return False
    except Exception as e:
        log_test('Verificar se heartbeat foi recebido', False, str(e))
        return False

# 4. Enviar comando START_STRATEGY
def send_start_strategy():
    try:
        data = {'command': 'START_STRATEGY'}
        response = requests.post(f'{BACKEND_URL}/command', json=data, timeout=5)
        if response.status_code == 200:
            log_test('Enviar comando START_STRATEGY', True, 'Comando enviado')
            return True
        else:
            log_test('Enviar comando START_STRATEGY', False, f'Status code: {response.status_code}')
            return False
    except Exception as e:
        log_test('Enviar comando START_STRATEGY', False, str(e))
        return False

# 5. Simular resposta de comando
def simulate_command_response():
    time.sleep(1)  # Simular processamento
    # Simulação: assumir sucesso
    log_test('Simular resposta de comando', True, 'Resposta simulada recebida')
    return True

# 6. Enviar métricas
def send_metrics():
    try:
        metrics = {'cpu': 45.2, 'memory': 67.8, 'timestamp': time.time()}
        response = requests.post(f'{BACKEND_URL}/metrics', json=metrics, timeout=5)
        if response.status_code == 200:
            log_test('Enviar métricas', True, 'Métricas enviadas')
            return True
        else:
            log_test('Enviar métricas', False, f'Status code: {response.status_code}')
            return False
    except Exception as e:
        log_test('Enviar métricas', False, str(e))
        return False

# 7. Gerar relatório
def generate_report():
    print_colored('\n=== RELATÓRIO DE TESTES FASE 3.2 ===', BLUE)
    for result in test_results:
        color = GREEN if result['status'] == 'PASSOU' else RED
        print_colored(f'{result["step"]}: {result["status"]} - {result["details"]}', color)
    total_tests = len(test_results)
    passed = sum(1 for r in test_results if r['status'] == 'PASSOU')
    print_colored(f'\nTotal de testes: {total_tests}, Passaram: {passed}, Falharam: {total_tests - passed}', YELLOW)

# Execução principal
def main():
    print_colored('Iniciando automação de testes FASE 3.2...', BLUE)
    start_time = time.time()

    check_backend_health()
    send_test_heartbeat()
    verify_heartbeat_received()
    send_start_strategy()
    simulate_command_response()
    send_metrics()

    end_time = time.time()
    print_colored(f'\nTempo total de execução: {end_time - start_time:.2f} segundos', YELLOW)

    generate_report()

if __name__ == '__main__':
    main()