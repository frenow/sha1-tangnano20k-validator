import time
import serial

# Configuração da porta serial
SERIAL_PORT = 'COM9'
SERIAL_BAUD = 115200

# Abrir conexão
ser = serial.Serial(SERIAL_PORT, SERIAL_BAUD, timeout=2)
time.sleep(1)  # Aguarda inicialização

def current_time():
    return time.strftime("%H:%M:%S", time.localtime())

def send_to_fpga(msg):
    """Envia mensagem para FPGA via UART"""
    ser.write(f"{msg}\n".encode('utf-8'))
    ser.flush()
    print(f'{current_time()} : Enviado para FPGA: {msg}')

try:
    print(f'{current_time()} : Sistema SHA-1 UART - Tang Nano 20K')
    print(f'{current_time()} : Conexão estabelecida em {SERIAL_PORT} @ {SERIAL_BAUD} bps\n')
    
    # Envia os 3 caracteres 'abc'
    msg = 'abc'
    print(f'{current_time()} : Enviando: "{msg}"')
    send_to_fpga(msg)
    
    print(f'{current_time()} : Aguardando cálculo SHA-1 na FPGA...')
    print(f'{current_time()} : Verifique o LED: deve acender se SHA-1 bater com esperado')
    print(f'{current_time()} : SHA-1(abc) = a9993e364706816aba3e25717850c26c9cd0d89d')
    
    # Aguarda um tempo para observar resultado
    time.sleep(3)
    
    print(f'\n{current_time()} : Teste concluído!')

except Exception as e:
    print(f'{current_time()} : Erro: {e}')

finally:
    ser.close()
    print(f'{current_time()} : Conexão fechada')
