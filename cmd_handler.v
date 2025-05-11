module cmd_handler(
    input wire clk,
    input wire rx_data_ready,
    input wire [7:0] rx_data,
    input wire tx_active,
    output reg cmd_ready,
    output reg [15:0] cmd,
    output reg tx_send,
    output reg [7:0] tx_data
);

    // FSM states
    parameter [1:0] 
        IDLE       = 2'b00,
        WAIT_FREQ  = 2'b01,
        SEND_BACK_1 = 2'b10,
        SEND_BACK_2 = 2'b11;
    
    reg [1:0] state = IDLE;
    reg [1:0] next_state;

    reg [7:0] wave_type = 8'h0;
    reg [7:0] frequency = 8'h0;

    // FSM state transition
    always @(posedge clk) begin
        state <= next_state;
        tx_send <= 0;  // Default value
        
        if (state != next_state && next_state == IDLE)
            cmd_ready <= 0;
    end

    // FSM next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (rx_data_ready && (rx_data == "A" || rx_data == "B" || rx_data == "C")) 
                    next_state = WAIT_FREQ;
            end
            
            WAIT_FREQ: begin
                if (rx_data_ready)
                    next_state = SEND_BACK_1;
            end
            
            SEND_BACK_1: begin
                if (!tx_active)
                    next_state = SEND_BACK_2;
            end
            
            SEND_BACK_2: begin
                if (!tx_active)
                    next_state = IDLE;
            end
        endcase
    end

    // Output and data processing
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                if (rx_data_ready && (rx_data == "A" || rx_data == "B" || rx_data == "C"))
                    wave_type <= rx_data;
            end
            
            WAIT_FREQ: begin
                if (rx_data_ready) begin
                    frequency <= rx_data;
                    cmd <= {wave_type, rx_data};
                    cmd_ready <= 1;
                end
            end
            
            SEND_BACK_1: begin
                if (!tx_active) begin
                    tx_data <= cmd[15:8];
                    tx_send <= 1;
                end
            end
            
            SEND_BACK_2: begin
                if (!tx_active) begin
                    tx_data <= cmd[7:0];
                    tx_send <= 1;
                end
            end
        endcase
    end

endmodule