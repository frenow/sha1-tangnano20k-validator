module top(
    input       clk,
    input       uart_rx,
    output      uart_tx,
    output      led
);

//==================================================================
// Parâmetros UART
//==================================================================
parameter CLK_FRE  = 27;        // Frequência do clock em MHz
parameter UART_FRE = 115200;    // Taxa de baud
parameter BUFFER_SIZE = 256;    // Tamanho do buffer

//==================================================================
// Estados da máquina principal
//==================================================================
localparam STATE_RESET       = 3'b000;
localparam STATE_WAIT_UART   = 3'b001;  // Aguardando dados UART
localparam STATE_UART_RX     = 3'b010;  // Recebendo dados UART
localparam STATE_SHA1_INIT   = 3'b011;  // Iniciando cálculo SHA-1
localparam STATE_SHA1_RUN    = 3'b100;  // Calculando SHA-1
localparam STATE_SHA1_WAIT   = 3'b101;  // Aguardando resultado
localparam STATE_RESULT      = 3'b110;  // Resultado pronto

//==================================================================
// Sinais UART
//==================================================================
wire rst_n = 1'b1;
reg [7:0] tx_data;
reg tx_data_valid;
wire tx_data_ready;
wire [7:0] rx_data;
wire rx_data_valid;
reg rx_data_ready;

//==================================================================
// Buffer para armazenar dados recebidos via UART
//==================================================================
reg [7:0] rx_buf [0:2];  // Buffer para 3 caracteres
reg [7:0] rx_cnt;

//==================================================================
// SHA-1
//==================================================================
reg [159:0] sha1_digest;
reg sha1_digest_valid;
wire sha1_core_ready;
wire [159:0] sha1_core_digest;
wire sha1_core_digest_valid;
reg sha1_init;
wire [511:0] MESSAGE_BLOCK;

// Constante esperada para SHA-1('abc')
localparam [159:0] SHA1_EXPECTED = 160'ha9993e364706816aba3e25717850c26c9cd0d89d;

//==================================================================
// Máquina de estados
//==================================================================
reg [2:0] state;
reg [12:0] clock_counter;
reg led_output;

// Saída do LED
assign led = ~led_output;  // Inverte: 1 = aceso, 0 = apagado

//==================================================================
// Monta o bloco de mensagem com dados recebidos
//==================================================================
assign MESSAGE_BLOCK = {
    rx_buf[0],                      // Byte 0: primeiro caractere
    rx_buf[1],                      // Byte 1: segundo caractere
    rx_buf[2],                      // Byte 2: terceiro caractere
    8'h80,                          // Byte 3: padding separator
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 4-7
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 8-11
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 12-15
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 16-19
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 20-23
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 24-27
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 28-31
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 32-35
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 36-39
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 40-43
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 44-47
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 48-51
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 52-55
    8'h00, 8'h00, 8'h00, 8'h00,    // Bytes 56-59
    8'h00, 8'h00, 8'h00, 8'h18     // Bytes 60-63: comprimento = 24 bits
};

//==================================================================
// Instanciação dos módulos UART
//==================================================================
uart_rx #(
    .CLK_FRE(CLK_FRE),
    .BAUD_RATE(UART_FRE)
) uart_rx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx_data(rx_data),
    .rx_data_valid(rx_data_valid),
    .rx_data_ready(rx_data_ready),
    .rx_pin(uart_rx)
);

uart_tx #(
    .CLK_FRE(CLK_FRE),
    .BAUD_RATE(UART_FRE)
) uart_tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data(tx_data),
    .tx_data_valid(tx_data_valid),
    .tx_data_ready(tx_data_ready),
    .tx_pin(uart_tx)
);

//==================================================================
// Instanciação do SHA-1
//==================================================================
sha1_core sha1_inst (
    .clk(clk),
    .reset_n(rst_n),
    .init(sha1_init),
    .next(1'b0),
    .block(MESSAGE_BLOCK),
    .ready(sha1_core_ready),
    .digest(sha1_core_digest),
    .digest_valid(sha1_core_digest_valid)
);

//==================================================================
// Máquina de estados principal
//==================================================================
always @(posedge clk) begin
    // Defaults
    sha1_init <= 1'b0;
    tx_data_valid <= 1'b0;
    rx_data_ready <= 1'b1;
    
    case (state)
        //-----------------------------------------------------------
        // STATE_RESET: Inicializa
        //-----------------------------------------------------------
        STATE_RESET: begin
            led_output <= 1'b0;
            rx_cnt <= 8'd0;
            clock_counter <= 13'd0;
            state <= STATE_WAIT_UART;
        end
        
        //-----------------------------------------------------------
        // STATE_WAIT_UART: Aguarda primeiro caractere via UART
        //-----------------------------------------------------------
        STATE_WAIT_UART: begin
            led_output <= 1'b0;
            if (rx_data_valid && rx_cnt == 0) begin
                if (rx_data != 8'h0A) begin  // Ignora line feed
                    rx_buf[0] <= rx_data;
                    rx_cnt <= 8'd1;
                    state <= STATE_UART_RX;
                end
            end
        end
        
        //-----------------------------------------------------------
        // STATE_UART_RX: Recebe 2 caracteres adicionais
        //-----------------------------------------------------------
        STATE_UART_RX: begin
            if (rx_data_valid) begin
                if (rx_data == 8'h0A) begin  // Line feed = fim de transmissão
                    // Dados completos recebidos, inicia SHA-1
                    state <= STATE_SHA1_INIT;
                    clock_counter <= 13'd0;
                end else if (rx_cnt < 3) begin
                    // Armazena caractere
                    rx_buf[rx_cnt] <= rx_data;
                    rx_cnt <= rx_cnt + 8'd1;
                end
            end
        end
        
        //-----------------------------------------------------------
        // STATE_SHA1_INIT: Inicia cálculo SHA-1
        //-----------------------------------------------------------
        STATE_SHA1_INIT: begin
            sha1_init <= 1'b1;
            state <= STATE_SHA1_RUN;
            clock_counter <= 13'd0;
        end
        
        //-----------------------------------------------------------
        // STATE_SHA1_RUN: Aguarda conclusão do SHA-1
        //-----------------------------------------------------------
        STATE_SHA1_RUN: begin
            if (clock_counter >= 13'd200) begin
                state <= STATE_SHA1_WAIT;
                clock_counter <= 13'd0;
            end else begin
                clock_counter <= clock_counter + 1'b1;
            end
        end
        
        //-----------------------------------------------------------
        // STATE_SHA1_WAIT: Aguarda digest válido
        //-----------------------------------------------------------
        STATE_SHA1_WAIT: begin
            if (sha1_core_digest_valid) begin
                sha1_digest <= sha1_core_digest;
                sha1_digest_valid <= 1'b1;
                state <= STATE_RESULT;
            end
        end
        
        //-----------------------------------------------------------
        // STATE_RESULT: Compara SHA-1 e acende LED se correto
        //-----------------------------------------------------------
        STATE_RESULT: begin
            if (sha1_digest == SHA1_EXPECTED) begin
                led_output <= 1'b1;  // Acende LED
            end else begin
                led_output <= 1'b0;  // Apaga LED
            end
            // Permanece neste estado
        end
        
        default: begin
            state <= STATE_RESET;
        end
    endcase
end

endmodule
