# SHA-1 Validator FPGA Firmware

Firmware Verilog para Tang Nano 20K que calcula SHA-1 de um caractere e valida contra um hash esperado, acendendo um LED se o cálculo estiver correto.

## 🎯 Objetivo

Implementar validação de SHA-1 em hardware FPGA, demonstrando:
- Cálculo de hash SHA-1 em Verilog
- Comparação com valor esperado
- Indicação visual de resultado (LED)

## 📋 Características

- **Suporte dinâmico**: Altere `CONST_TEST` para testar qualquer caractere (8 bits)
- **SHA-1 RFC 3174**: Implementação completa com padding correto
- **Tang Nano 20K**: Otimizado para placa GW2AR-18C
- **Máquina de estados simples**: Fácil de entender e evoluir
- **LED indicador**: Acende quando SHA-1 bate com esperado

## 🔧 Hardware Necessário

- Tang Nano 20K (GW2AR-18C)
- Cable USB para programação
- LED (opcional - para visualização)

## 📁 Estrutura do Projeto

```
verilog-fimware/
├── src/
│   ├── blink_leds.v          # Módulo principal com validação SHA-1
│   ├── sha1_core.v           # Core SHA-1 (cálculo dos rounds)
│   ├── sha1_w_mem.v          # Expansão de palavras SHA-1
│   ├── blink_leds.cst        # Constraints (pinos)
│   └── blink_leds.sdc        # Timing constraints
├── blink_leds.gprj           # Projeto Gowin EDA
└── calc_sha1.py              # Script para calcular SHA-1 (teste)
```

## 🚀 Como Usar

### 1. Alterar o caractere a testar

Edite `src/blink_leds.v` e mude a constante:

```verilog
localparam [7:0] CONST_TEST = 8'h0A;  // Caractere ASCII (0x0A = LF)
```

### 2. Calcular o SHA-1 esperado

Use o script Python:

```bash
python calc_sha1.py
```

Ou use um site online. Atualize `SHA1_EXPECTED`:

```verilog
localparam [159:0] SHA1_EXPECTED = 160'hadc83b19e793491b1c6ea0fd8b46cd9f32e592fc;
```

### 3. Compilar com Gowin EDA

1. Abra `blink_leds.gprj` no Gowin EDA
2. Clique em "Synthesize" e depois "Place & Route"
3. Gere o arquivo `.fs` para programação

### 4. Programar a FPGA

Use o Gowin Programmer:
1. Conecte a Tang Nano 20K via USB
2. Carregue o arquivo `.bin` gerado
3. Clique em "Program"

## 📊 Fluxo de Execução

```
RESET (100 ciclos) 
  ↓
IDLE (aguarda SHA-1 pronto)
  ↓
INIT_SHA1 (ativa sinal init)
  ↓
RUNNING (aguarda ~200 ciclos)
  ↓
DONE_WAIT (aguarda digest_valid)
  ↓
RESULT (compara e acende LED)
  ↓
[Mantém resultado]
```

## 💡 Exemplos de Teste

| Caractere | Hex    | SHA-1                                | Comportamento    |
|-----------|--------|--------------------------------------|------------------|
| a         | 0x61   | 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 | LED acende ✓     |
| b         | 0x62   | e9d71f5ee7c92d6dc9e92ffdad17b8bd49418f98 | LED acende ✓     |
| c         | 0x63   | 84a516841ba77a5b4648de2cd0dfcb30ea46dbb4 | LED acende ✓     |
| LF        | 0x0A   | adc83b19e793491b1c6ea0fd8b46cd9f32e592fc | LED acende ✓     |

## 🔌 Pinagem

| Sinal | Pino | Tipo | Voltagem |
|-------|------|------|----------|
| clk   | 4    | In   | LVCMOS33 |
| led   | 15   | Out  | LVCMOS33 |

## 📚 Referências

- [SHA-1 RFC 3174](https://tools.ietf.org/html/rfc3174)
- [Tang Nano 20K Documentation](https://github.com/sipeed/TangNano-20K-Dock)
- [Gowin FPGA](https://www.gowinsemi.com/)

## 🛠️ Próximas Melhorias

- [ ] Suporte para strings multi-byte
- [ ] Interface UART para entrada de dados
- [ ] Múltiplos LEDs para indicar estado
- [ ] Comparação com várias hashes
- [ ] Contador de ciclos para análise de performance

## 📝 Licença

MIT License

## ✍️ Autor

Desenvolvido como teste de validação SHA-1 em FPGA.
