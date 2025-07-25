module credit(
    input [4:0] coin,
    input coin_in,
    input reset,
    output reg [7:0] balance
    output invalid_coin;
    output max_balance;
);

    localparam R_5    = 5'b00001;
    localparam R_10   = 5'b00010;
    localparam R_20   = 5'b00100;
    localparam R_50   = 5'b01000;
    localparam R_100  = 5'b10000;
    localparam R_in =5'b11111;
    assign invalid_coin <= 0;
    assign max_balance <= 0;
    always @(posedge coin_in or posedge reset) begin
        if (reset) begin
            balance <= 8'd0;
        end else begin
            if (coin == R_5)
                balance <= balance + 8'd5;
            else if (coin == R_10)
                balance <= balance + 8'd10;
            else if (coin == R_20)
                balance <= balance + 8'd20;
            else if (coin == R_50)
                balance <= balance + 8'd50;
            else if (coin == R_100)
                balance <= balance + 8'd100;
            else if(coin == R_in)
                invalid_coin <= 1;
            else
                balance <= balance; 
        end
    end
    
    begin balance_check
     if (balance > 8'b1111111)
     assign max_balance <= 1;
     else
     assign max_balance <=0;

endmodule

