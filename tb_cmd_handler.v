`timescale 1ns/1ps

module tb_cmd_handler();

    reg clk;
    reg rx_data_ready;
    reg [7:0] rx_data;
    reg tx_active;
    wire cmd_ready;
    wire [15:0] cmd;
    wire tx_send;
    wire [7:0] tx_data;
    
    // Clock generation
    always #5 clk = ~clk;
    
    // DUT Instantiation
    cmd_handler dut(
        .clk(clk),
        .rx_data_ready(rx_data_ready),
        .rx_data(rx_data),
        .tx_active(tx_active),
        .cmd_ready(cmd_ready),
        .cmd(cmd),
        .tx_send(tx_send),
        .tx_data(tx_data)
    );
    
    // Test sequence
    initial begin
        clk = 0;
        rx_data_ready = 0;
        rx_data = 0;
        tx_active = 0;
        
        // Test Case 1: Valid command 'A' + 0x55
        send_uart_byte("A");
        #20;
        send_uart_byte(8'h55);
        #200;
        
        // Test Case 2: Invalid command 'D' + 0xAA
        send_uart_byte("D");
        #20;
        send_uart_byte(8'hAA);
        #200;
        
        // Test Case 3: Valid command 'B' + 0x7F
        send_uart_byte("B");
        #20;
        send_uart_byte(8'h7F);
        #200;
    end
    
    // UART Byte Send Task
    task send_uart_byte(input [7:0] data);
        begin
            // Sending data at negative edge of the clock
            #5;  // Wait for half a clock cycle (this ensures proper timing)
            rx_data = data;
            rx_data_ready = 1;
            #5;  // Keep rx_data_ready high for one clock cycle
            rx_data_ready = 0;
        end
    endtask
    
    // TX Activity Simulation
    always @(posedge tx_send) begin
        tx_active = 1;
        #100;
        tx_active = 0;
    end
    
    // Monitoring
    always @(posedge cmd_ready) begin
        $display("[%t] Command Received: 0x%h (Wave: %s, Freq: 0x%h)", 
               $time, cmd, cmd[15:8], cmd[7:0]);
    end
    
    always @(posedge tx_send) begin
        $display("[%t] Sending TX Data: 0x%h", $time, tx_data);
    end

endmodule
