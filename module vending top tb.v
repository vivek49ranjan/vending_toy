`timescale 1ns / 1ps

module tb_vending_top;
    reg clk;
    reg reset;
    reg [4:0] coin;
    reg coin_in;
    reg [3:0] row;      
    reg S_Row;          
    reg is_product_out;
    reg refund;
    reg [15:0] key;
    reg [79:0] price_of_all;
    reg [3:0] initial_product_qty_tb [0:9];

    wire invalid_coin;
    wire max_balance;
    wire in_stock;
    wire not_available_balance;
    wire [3:0] five, ten, twenty, fifty, hundred; 
    wire [3:0] code;            
    wire [3:0] col;             
    wire valid;                 
    wire [3:0] product_dispensed;

    vending_top dut (
        .clk(clk),
        .reset(reset),
        .coin(coin),
        .coin_in(coin_in),
        .row(row),
        .key(key),
        .is_product_out(is_product_out),
        .refund(refund),
        .price_of_all(price_of_all),
        .initial_product_qty(initial_product_qty_tb), // Corrected: Direct connection of unpacked array
        .invalid_coin(invalid_coin),
        .max_balance(max_balance),
        .in_stock(in_stock),
        .not_available_balance(not_available_balance),
        .five(five),
        .ten(ten),
        .twenty(twenty),
        .fifty(fifty),
        .hundred(hundred),
        .product_dispensed(product_dispensed)
    );


    parameter CLK_PERIOD = 10; 

    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk; 
    end


    task simulate_button_press;
        input [3:0] target_code;
        reg [3:0] temp_row_task;
        begin
            $display("    Simulating button press for code %d...", target_code);

            case (target_code)
                4'd0: temp_row_task = 4'b0001;
                4'd1: temp_row_task = 4'b0001;
                4'd2: temp_row_task = 4'b0001;
                4'd3: temp_row_task = 4'b0001;
                4'd4: temp_row_task = 4'b0010;
                4'd5: temp_row_task = 4'b0010;
                4'd6: temp_row_task = 4'b0010;
                4'd7: temp_row_task = 4'b0010;
                4'd8: temp_row_task = 4'b0100;
                4'd9: temp_row_task = 4'b0100;
                4'd10: temp_row_task = 4'b0100;
                4'd11: temp_row_task = 4'b0100;
                default: temp_row_task = 4'b0000;
            endcase

            row = temp_row_task;
            S_Row = 1; 
            @(posedge clk); 
            while (!(valid && (code == target_code))) begin
                @(posedge clk);
            end
            $display("    Button code %d detected. Valid: %b at time %0t", code, valid, $time);

            # (CLK_PERIOD) row = 4'b0000;
            S_Row = 0;
            # (CLK_PERIOD * 2); 
            $display("    Button released at time %0t", $time);
        end
    endtask


    initial begin
        reset          = 1;
        coin           = 5'b0;
        coin_in        = 0;
        row            = 4'b0;
        S_Row          = 0;
        is_product_out = 0;
        refund         = 0;
        key            = 16'h0000;

        for(int j=0; j<10; j++) begin
            initial_product_qty_tb[j] = 4'd5;
        end

        price_of_all = {
            8'd0,
            8'd0,
            8'd0,
            8'd0,
            8'd0,
            8'd120,
            8'd50,
            8'd20,
            8'd10,
            8'd10
        };


        $display("------------------- Simulation Start -------------------");
        $monitor("Time=%0t | Reset=%b | Coin_in=%b | Coin=%5b | Row=%4b | S_Row=%b | is_product_out=%b | Refund=%b | Balance=%d | ProdCode=%d | DispensedProd=%d | InvalidCoin=%b | MaxBalance=%b | InStock=%b | NotAvailBalance=%b | NoTaker=%b | Five=%d Ten=%d Twenty=%d Fifty=%d Hundred=%d | P1_Qty=%d P2_Qty=%d P3_Qty=%d P4_Qty=%d P5_Qty=%d P6_Qty=%d P7_Qty=%d P8_Qty=%d P9_Qty=%d P10_Qty=%d",
                  $time, reset, coin_in, coin, row, S_Row, is_product_out, refund, dut.system_balance, dut.product_button, product_dispensed, invalid_coin, max_balance, in_stock, not_available_balance, dut.no_taker, five, ten, twenty, fifty, hundred, dut.product_qty[0], dut.product_qty[1], dut.product_qty[2], dut.product_qty[3], dut.product_qty[4], dut.product_qty[5], dut.product_qty[6], dut.product_qty[7], dut.product_qty[8], dut.product_qty[9]);

        
        # (CLK_PERIOD * 2) reset = 0; 
        $display("\n--- Test 1: Initial State After Reset ---");


        $display("\n--- Test 2: Inserting Coins ---");
        # (CLK_PERIOD * 2) coin = 5'b00001; coin_in = 1;
        # (CLK_PERIOD) coin_in = 0;
        # (CLK_PERIOD * 2) coin = 5'b00010; coin_in = 1;
        # (CLK_PERIOD) coin_in = 0;
        # (CLK_PERIOD * 2) coin = 5'b00100; coin_in = 1;
        # (CLK_PERIOD) coin_in = 0;
        # (CLK_PERIOD * 2) coin = 5'b00000; coin_in = 1;
        # (CLK_PERIOD) coin_in = 0;

        
        $display("\n--- Test 3: Select Product 1 (Price 10) ---");
        simulate_button_press(4'd1); 
        # (CLK_PERIOD * 2) is_product_out = 1; 
        # (CLK_PERIOD) is_product_out = 0; 

        $display("\n--- Test 4: Select Product 3 (Price 20) - Insufficient Funds ---");
        simulate_button_press(4'd3); 
        # (CLK_PERIOD * 2) is_product_out = 1; 
        # (CLK_PERIOD) is_product_out = 0;


        $display("\n--- Test 5: Insert more coins, then buy Product 3 ---");
        # (CLK_PERIOD * 2) coin = 5'b01000; coin_in = 1;
        # (CLK_PERIOD) coin_in = 0;


        # (CLK_PERIOD * 2) coin = 5'b00010; coin_in = 1;
        # (CLK_PERIOD) coin_in = 0;


        simulate_button_press(4'd3); 
        # (CLK_PERIOD * 2) is_product_out = 1; 
        # (CLK_PERIOD) is_product_out = 0;


        $display("\n--- Test 6: Test Max Balance ---");

        for (int m = 0; m < 3; m++) begin
            # (CLK_PERIOD * 2) coin = 5'b10000; coin_in = 1; 
            # (CLK_PERIOD) coin_in = 0;
        end
    
        $display("\n--- Test 7: Buy Product 5 (Price 120) ---");
        simulate_button_press(4'd5); 
        # (CLK_PERIOD * 2) is_product_out = 1;
        # (CLK_PERIOD) is_product_out = 0;

        $display("\n--- Test 8: Initiating Refund ---");
        # (CLK_PERIOD * 5) refund = 1;
        # (CLK_PERIOD * 2) refund = 0; 

        
        $display("\n--- Test 9: Buy remaining P1, then attempt purchase when out of stock ---");

        # (CLK_PERIOD * 2) coin = 5'b10000; coin_in = 1; 
        # (CLK_PERIOD) coin_in = 0;
        # (CLK_PERIOD * 2) coin = 5'b10000; coin_in = 1; 
        # (CLK_PERIOD) coin_in = 0;


        for (int k = 0; k < 5; k = k + 1) begin
            $display("    Attempting to buy P1, iteration %0d", k+1);
            simulate_button_press(4'd1); 
            # (CLK_PERIOD * 2) is_product_out = 1;
            # (CLK_PERIOD) is_product_out = 0;
        end
        
        $display("\n--- Attempt to buy P1 when out of stock ---");
        simulate_button_press(4'd1); 
        # (CLK_PERIOD * 2) is_product_out = 1;
        # (CLK_PERIOD) is_product_out = 0;

        # (CLK_PERIOD * 10) $finish;
    end

endmodule
