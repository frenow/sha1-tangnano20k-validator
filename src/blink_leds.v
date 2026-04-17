module top(
    input       clk,
    output      led
);

//==================================================================
// Constantes do projeto
//==================================================================
localparam [7:0] CONST_TEST = 8'h0A;  // Caractere para teste
localparam [159:0] SHA1_EXPECTED = 160'hadc83b19e793491b1c6ea0fd8b46cd9f32e592fc;  // SHA-1(0x0A)

// Bloco de mensagem com CONST_TEST:
// CONST_TEST em ASCII + padding SHA-1 RFC 3174
// Total: 512 bits (64 bytes)
wire [511:0] MESSAGE_BLOCK;

// Monta o bloco de mensagem dinamicamente usando CONST_TEST
assign MESSAGE_BLOCK = {
    CONST_TEST,                     // Byte 0: caractere de teste
    8'h80,                          // Byte 1: padding separator
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 2-5
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 6-9
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 10-13
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 14-17
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 18-21
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 22-25
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 26-29
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 30-33
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 34-37
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 38-41
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 42-45
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 46-49
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 50-53
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 54-57
    8'h00, 8'h00,                  // Bytes 58-59
    8'h00, 8'h00, 8'h00, 8'h08     // Bytes 60-63: comprimento = 8 bits (big-endian)
};

//==================================================================
// Sinais internos
//==================================================================
// Contadores e flags
reg [12:0] clock_counter;           // Contador para gerenciar timing
reg [159:0] sha1_digest;
reg sha1_digest_valid;

// Sinais SHA-1 da instância
wire sha1_core_ready;
wire [159:0] sha1_core_digest;
wire sha1_core_digest_valid;

// Sinais de controle
reg sha1_init;
reg sha1_next;
reg led_output;

// Estados
reg [2:0] state;
localparam STATE_RESET      = 3'b000;
localparam STATE_IDLE       = 3'b001;
localparam STATE_INIT_SHA1  = 3'b010;
localparam STATE_RUNNING    = 3'b011;
localparam STATE_DONE_WAIT  = 3'b100;
localparam STATE_RESULT     = 3'b101;

//==================================================================
// Saída do LED
//==================================================================
assign led = ~led_output;  // Inverte: 1 = aceso, 0 = apagado

//==================================================================
// Instanciação do core SHA-1
//==================================================================
sha1_core sha1_inst(
    .clk(clk),
    .reset_n(1'b1),                 // Reset sempre ativo
    .init(sha1_init),
    .next(sha1_next),
    .block(MESSAGE_BLOCK),
    .ready(sha1_core_ready),
    .digest(sha1_core_digest),
    .digest_valid(sha1_core_digest_valid)
);

//==================================================================
// Máquina de estados com contadores explícitos
//==================================================================
always @(posedge clk) begin
    // Limpa sinais de controle por padrão
    sha1_init <= 1'b0;
    sha1_next <= 1'b0;
    
    case (state)
        //-------------------------------------------------------
        // STATE_RESET: Espera alguns ciclos para o sistema estabilizar
        //-------------------------------------------------------
        STATE_RESET: begin
            led_output <= 1'b0;
            clock_counter <= 13'd0;
            
            if (clock_counter >= 13'd100) begin
                clock_counter <= 13'd0;
                state <= STATE_IDLE;
            end else begin
                clock_counter <= clock_counter + 1'b1;
            end
        end
        
        //-------------------------------------------------------
        // STATE_IDLE: Aguarda SHA-1 estar pronto
        //-------------------------------------------------------
        STATE_IDLE: begin
            led_output <= 1'b0;
            
            if (sha1_core_ready) begin
                state <= STATE_INIT_SHA1;
                clock_counter <= 13'd0;
            end
        end
        
        //-------------------------------------------------------
        // STATE_INIT_SHA1: Inicia o cálculo SHA-1
        //-------------------------------------------------------
        STATE_INIT_SHA1: begin
            sha1_init <= 1'b1;  // Ativa sinal de init por 1 ciclo
            state <= STATE_RUNNING;
            clock_counter <= 13'd0;
        end
        
        //-------------------------------------------------------
        // STATE_RUNNING: Aguarda conclusão (80 rounds + overhead)
        //-------------------------------------------------------
        STATE_RUNNING: begin
            // SHA-1 core leva ~80 ciclos de clock para calcular
            if (clock_counter >= 13'd200) begin
                state <= STATE_DONE_WAIT;
                clock_counter <= 13'd0;
            end else begin
                clock_counter <= clock_counter + 1'b1;
            end
        end
        
        //-------------------------------------------------------
        // STATE_DONE_WAIT: Aguarda digest_valid
        //-------------------------------------------------------
        STATE_DONE_WAIT: begin
            if (sha1_core_digest_valid) begin
                // Armazena resultado
                sha1_digest <= sha1_core_digest;
                sha1_digest_valid <= 1'b1;
                state <= STATE_RESULT;
            end
        end
        
        //-------------------------------------------------------
        // STATE_RESULT: Compara SHA-1 e acende LED se correto
        //-------------------------------------------------------
        STATE_RESULT: begin
            if (sha1_digest == SHA1_EXPECTED) begin
                led_output <= 1'b1;  // Acende LED quando SHA-1 bate
            end else begin
                led_output <= 1'b0;  // Apaga LED se não bater
            end
            // Permanece neste estado
        end
        
        default: begin
            state <= STATE_RESET;
        end
    endcase
end

endmodule
