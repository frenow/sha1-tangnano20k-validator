# Contexto do Projeto SHA-1 Tang Nano 20K Validator

## Status Atual
✅ Projeto completado e enviado para GitHub

## Resumo do Trabalho Realizado

### 1. **Análise Inicial**
- Leitura do firmware original (blink_leds.v): apenas acendia/apagava LED estático
- Identificadas 2 constantes:
  - `CONST_TEST = 8'h0A` (valor 10 decimal)
  - `SHA1_TEST = 160'h86f7e437faa5a7fce15d1ddcb9eaeaea377667b8` (SHA-1 de "a")

### 2. **Exploração do SHA-1 Reference**
- Analisados 3 módulos Verilog da pasta `sha1-verilog2`:
  - `sha1_core.v`: Core SHA-1 com máquina de estados (80 rounds)
  - `sha1_w_mem.v`: Expansão de palavras W (512 bits → 2560 bits)
  - `sha1.v`: Wrapper com interface de memória

### 3. **Problemas Enfrentados e Soluções**

#### Problema 1: LED Apagado (Primeira Versão)
- **Causa**: Máquina de estados não inicializava corretamente
- **Solução**: Adicionar inicialização explícita de variáveis e timing adequado

#### Problema 2: LED Continua Apagado (Segunda Versão)
- **Causa**: Falta de tempo suficiente para SHA-1 calcular (80 ciclos + overhead)
- **Solução**: 
  - Implementar STATE_RESET para estabilização (100 ciclos)
  - Aumentar tempo em STATE_RUNNING para 200 ciclos
  - Adicionar STATE_DONE_WAIT aguardando `digest_valid` do core

### 4. **Solução Final Implementada**
Máquina de estados com 6 estados:
```
STATE_RESET (100 ciclos)
  ↓
STATE_IDLE (aguarda SHA-1 pronto)
  ↓
STATE_INIT_SHA1 (ativa init por 1 ciclo)
  ↓
STATE_RUNNING (200 ciclos aguardando cálculo)
  ↓
STATE_DONE_WAIT (aguarda digest_valid)
  ↓
STATE_RESULT (compara e acende LED)
```

### 5. **Testes Realizados**
| Caractere | ASCII | SHA-1                                | Resultado |
|-----------|-------|--------------------------------------|-----------|
| 'a'       | 0x61  | 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 | ✅ LED aceso |
| 'b'       | 0x62  | e9d71f5ee7c92d6dc9e92ffdad17b8bd49418f98 | ✅ LED aceso |
| 'c'       | 0x63  | 84a516841ba77a5b4648de2cd0dfcb30ea46dbb4 | ✅ LED aceso |
| 0x0A (LF) | 0x0A  | adc83b19e793491b1c6ea0fd8b46cd9f32e592fc | ✅ LED aceso |

### 6. **Implementação Final**
- **Arquivo Principal**: `src/blink_leds.v`
  - MESSAGE_BLOCK: Dinâmico, usa CONST_TEST como entrada
  - Padding SHA-1 RFC 3174 explícito (64 bytes = 512 bits)
  - Comparação automática com SHA1_EXPECTED
  - LED acende quando hashes batem

### 7. **Documentação**
- Criado `README.md` completo com:
  - Descrição do projeto
  - Instruções de uso
  - Estrutura de arquivos
  - Fluxo de execução
  - Tabela de testes
  - Referências técnicas
  - Sugestões de melhorias

## Arquivos do Projeto

```
verilog-fimware/
├── src/
│   ├── blink_leds.v          # Módulo principal (179 linhas)
│   ├── sha1_core.v           # Core SHA-1 (433 linhas)
│   ├── sha1_w_mem.v          # W memory (265 linhas)
│   ├── blink_leds.cst        # Constraints (18 linhas)
│   └── blink_leds.sdc        # Timing (3 linhas)
├── impl/                     # Saída de compilação
├── blink_leds.gprj          # Projeto Gowin
├── blink_leds.fs            # Bitstream compilado
├── calc_sha1.py             # Script para calcular SHA-1
└── README.md                # Documentação completa
```

## Hardware & Placa
- **Placa**: Tang Nano 20K (GW2AR-18C)
- **Pino CLK**: 4 (LVCMOS33)
- **Pino LED**: 15 (LVCMOS33, ativo baixo)

## Repositório GitHub
- **URL**: https://github.com/frenow/sha1-tangnano20k-validator
- **Branch**: main
- **Commits**: 1 (Initial commit)
- **Status**: ✅ Pronto para uso

## Próximas Melhorias Sugeridas
1. Suporte para strings multi-byte (não apenas caracteres únicos)
2. Interface UART para entrada dinâmica de dados
3. Múltiplos LEDs para indicar estado (calculando, pronto, correto/incorreto)
4. Comparação com várias hashes simultaneamente
5. Contador de ciclos para análise de performance

## Comandos Importantes para Continuar

**Clonar repositório:**
```bash
git clone https://github.com/frenow/sha1-tangnano20k-validator.git
cd sha1-tangnano20k-validator
```

**Compilar:**
1. Abrir `blink_leds.gprj` em Gowin EDA
2. Synthesize → Place & Route
3. Gerar bitstream

**Programar:**
1. Conectar Tang Nano 20K via USB
2. Usar Gowin Programmer
3. Carregar `impl/pnr/blink_leds.bin`

**Testar novo caractere:**
1. Editar `src/blink_leds.v`
2. Mudar `CONST_TEST = 8'hXX` (novo valor)
3. Calcular SHA-1: `python calc_sha1.py`
4. Atualizar `SHA1_EXPECTED`
5. Recompilar e programar

## Lições Aprendidas
1. **Timing é crítico em FPGA**: Sinais precisam de ciclos suficientes
2. **Padding SHA-1 deve ser exato**: RFC 3174 bem específico
3. **Máquinas de estado simplificam lógica**: Melhor que lógica combinacional complexa
4. **Inicialização explícita**: Evita estados indefinidos
5. **Testes iterativos**: Testar com múltiplos valores valida implementação

## Data de Conclusão
17 de Abril de 2026

## Responsável
Emerson
