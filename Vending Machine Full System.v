module vending_top(
    input [4:0] coin,
    input coin_in,
    input reset,
    input clk,
    input is_product_out,
    input refund,
    input [3:0] row,
    input [15:0] key,
    input [79:0] price_of_all,
    output wire invalid_coin,
    output wire max_balance,
    output reg in_stock,
    output reg not_available_balance,
    output wire [3:0] five, ten, twenty, fifty, hundred
);

   
    wire [3:0] button_pressed;
    wire [7:0] price;
    wire press_valid_button;
    wire S_Row;
    wire [3:0] Row;
    wire [3:0] col;

    reg [1:0] state;
    reg [3:0] product_button;
    reg [3:0] qty_button;
    wire [3:0] product_qty [0:9];
    wire [7:0] updated_credit;
    wire [3:0] product;
    wire no_taker;


    parameter S_idle = 2'b00, S_0 = 2'b01, S_1 = 2'b10, S_2 = 2'b11;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_idle;
            product_button <= 4'b0000;
            qty_button <= 4'b0000;
        end else begin
            case(state)
                S_idle: begin
                    if (press_valid_button) begin
                        product_button <= button_pressed;
                        state <= S_0;
                    end
                end
                S_0: begin
                    if (press_valid_button) begin
                        qty_button <= button_pressed;
                        state <= S_1;
                    end
                end
                S_1: begin
                    state <= S_2;
                end
                S_2: begin
                    state <= S_idle;
                end
                default: state <= S_idle;
            endcase
        end
    end


    credit give_credit(
        .coin(coin),
        .coin_in(coin_in),
        .reset(reset),
        .balance(balance),
        .invalid_coin(invalid_coin),
        .max_balance(max_balance)
    );

    button button_pressed_module(
        .code(button_pressed),
        .col(col),
        .valid(press_valid_button),
        .row(Row),
        .S_Row(S_Row),
        .clock(clk),
        .reset(reset)
    );

    Synchronize sync(
        .S_Row(S_Row),
        .row(Row),
        .clock(clk),
        .reset(reset)
    );

    Row_Signal R_S(
        .Row(Row),
        .Key(key),
        .Col(col)
    );

    give_price price_fetcher(
        .price_of_all(price_of_all),
        .product_no(product_button),
        .calculate_price(is_product_out),
        .price(price)
    );

    product_out out_module(
        .clk(clk),
        .reset(reset),
        .price(price),
        .credit(balance),
        .product_no(product_button),
        .is_product_out(is_product_out),
        .updated_credit(updated_credit),
        .product(product),
        .product_qty(product_qty)
    );

    product_validation validator(
        .credit(balance),
        .price(price),
        .product_out(is_product_out),
        .not_available_balance(not_available_balance)
    );

    return_money returner(
        .refund(refund),
        .credit(balance),
        .five(five),
        .ten(ten),
        .twenty(twenty),
        .fifty(fifty),
        .hundred(hundred)
    );

    product_input checker(
        .P_1(product_qty[0]), .P_2(product_qty[1]), .P_3(product_qty[2]), .P_4(product_qty[3]),
        .P_5(product_qty[4]), .P_6(product_qty[5]), .P_7(product_qty[6]), .P_8(product_qty[7]),
        .P_9(product_qty[8]), .P_10(product_qty[9]),
        .product_no(product_button),
        .product_in(is_product_out),
        .in_stock(in_stock)
    );

    product_quantity quantify (
        .product_no(product_button),
        .product_qty(product_qty[product_button]),
        .no_taker(no_taker)
    );

endmodule

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
module button_controller (
  input clock,
  input reset,
  input valid,                 
  input [3:0] code,            
  output reg [3:0] product_no, 
  output reg valid_product,  
  output reg S_Row             
);

  typedef enum reg [1:0] {
    WAIT1 = 2'd0,
    WAIT2 = 2'd1,
    DONE  = 2'd2
  } state_t;

  state_t state;
  reg [3:0] digit1, digit2;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      state <= WAIT1;
      product_no <= 4'd0;
      valid_product <= 0;
      digit1 <= 4'd0;
      digit2 <= 4'd0;
      S_Row <= 0;
    end else begin
      S_Row <= 1;

      case (state)
        WAIT1: begin
          valid_product <= 0;
          if (valid) begin
            digit1 <= code;
            state <= WAIT2;
          end
        end

        WAIT2: begin
          if (valid) begin
            digit2 <= code;
            state <= DONE;
          end
        end

        DONE: begin
          product_no <= digit1 * 4'd10 + digit2;
          valid_product <= 1;
          state <= WAIT1;
        end
      endcase
    end
  end

endmodule
module button(
  output reg [3:0] code, 
  output reg [3:0] col, 
  output valid,
  input [3:0] row,
  input S_Row,
  input clock, reset
);

  reg [5:0] state, next_state;

  parameter S_0 = 6'b000001, S_1 = 6'b000010, S_2 = 6'b000100;
  parameter S_3 = 6'b001000, S_4 = 6'b010000, S_5 = 6'b100000;

  assign valid = ((state == S_1) || (state == S_2) || (state == S_3) || (state == S_4)) && (row != 0);


  always @(*) begin
    case ({row, col})
      8'b0001_0001: code = 4'd0;
      8'b0001_0010: code = 4'd1;
      8'b0001_0100: code = 4'd2;
      8'b0001_1000: code = 4'd3;
      
      8'b0010_0001: code = 4'd4;
      8'b0010_0010: code = 4'd5;
      8'b0010_0100: code = 4'd6;
      8'b0010_1000: code = 4'd7;
      
      8'b0100_0001: code = 4'd8;
      8'b0100_0010: code = 4'd9;
      

      8'b0100_0100: code = 4'd10; 
      8'b0100_1000: code = 4'd11; 

      default: code = 4'd0;
    endcase
  end


  always @(posedge clock or posedge reset) begin
    if (reset) 
      state <= S_0;
    else 
      state <= next_state;
  end

  always @(*) begin
    next_state = state;
    col = 4'b0000;

    case (state)
      S_0: begin col = 4'b1111; if (S_Row) next_state = S_1; end
      S_1: begin col = 4'b0001; if (row != 4'b0000) next_state = S_5; else next_state = S_2; end
      S_2: begin col = 4'b0010; if (row != 4'b0000) next_state = S_5; else next_state = S_3; end
      S_3: begin col = 4'b0100; if (row != 4'b0000) next_state = S_5; else next_state = S_4; end
      S_4: begin col = 4'b1000; if (row != 4'b0000) next_state = S_5; else next_state = S_0; end
      S_5: begin col = 4'b1111; if (row == 4'b0000) next_state = S_0; end
    endcase
  end

endmodule
module give_price(
    input [79:0] price_of_all, 
    input [3:0] product_no, 
    input calculate_price,
    output [7:0] price
);

reg [7:0] selected_price;


price_register u1 (
    .clk(calculate_price),
    .in_price(selected_price),
    .load(calculate_price),
    .out_price(price)
);

always @(*) begin
    case (product_no)
        4'b0001: selected_price = price_of_all[7:0];
        4'b0010: selected_price = price_of_all[15:8];
        4'b0011: selected_price = price_of_all[23:16];
        4'b0100: selected_price = price_of_all[31:24];
        4'b0101: selected_price = price_of_all[39:32];
        4'b0110: selected_price = price_of_all[47:40];
        4'b0111: selected_price = price_of_all[55:48];
        4'b1000: selected_price = price_of_all[63:56];
        4'b1001: selected_price = price_of_all[71:64];
        4'b1010: selected_price = price_of_all[79:72];
        default: selected_price = 8'bzzzzzzzz;
    endcase
end

endmodule


module price_register(
    input clk,
    input [7:0] in_price,
    input load,
    output reg [7:0] out_price
);
  always @(posedge clk) begin
    if (load)
        out_price <= in_price;
  end
endmodule
module product_out(
    input [7:0] price,              
    input [7:0] credit,             
    input is_product_out,           
    output reg [7:0] updated_credit,
    output reg [3:0] product        
);

always @(posedge is_product_out) begin
    if (credit >= price) begin
        updated_credit <= credit - price;
        product <= 4'b0001;  
    end else begin
        updated_credit <= credit;
        product <= 4'b0000; 
    end
end

endmodule
module product_validation (
    input [7:0] credit, 
    input [7:0] price, 
    input product_out,
    output reg not_available_balance
);

always @(posedge product_out) begin
    if (price > credit)
        not_available_balance <= 1;
    else
        not_available_balance <= 0;
end

endmodule
module return_money (
    input refund,
    input [7:0] credit,
    output reg [3:0] five,
    output reg [3:0] ten,
    output reg [3:0] twenty,
    output reg [3:0] fifty,
    output reg [3:0] hundred
);

reg [7:0] temp_credit;

always @(posedge refund) begin

    five    <= 0;
    ten     <= 0;
    twenty  <= 0;
    fifty   <= 0;
    hundred <= 0;

    temp_credit = credit;

    while (temp_credit >= 100) begin
        temp_credit = temp_credit - 100;
        hundred <= hundred + 1;
    end

    while (temp_credit >= 50) begin
        temp_credit = temp_credit - 50;
        fifty <= fifty + 1;
    end

    while (temp_credit >= 20) begin
        temp_credit = temp_credit - 20;
        twenty <= twenty + 1;
    end

    while (temp_credit >= 10) begin
        temp_credit = temp_credit - 10;
        ten <= ten + 1;
    end

    while (temp_credit >= 5) begin
        temp_credit = temp_credit - 5;
        five <= five + 1;
    end
end

endmodule
module product_input(
    input [3:0] P_1, P_2, P_3, P_4, P_5, P_6, P_7, P_8, P_9, P_10,
    input [3:0] product_no,
    input product_in,
    output reg in_stock
);

always @(posedge product_in) begin
    case (product_no)
        4'd1:  in_stock <= (P_1 > 0);
        4'd2:  in_stock <= (P_2 > 0);
        4'd3:  in_stock <= (P_3 > 0);
        4'd4:  in_stock <= (P_4 > 0);
        4'd5:  in_stock <= (P_5 > 0);
        4'd6:  in_stock <= (P_6 > 0);
        4'd7:  in_stock <= (P_7 > 0);
        4'd8:  in_stock <= (P_8 > 0);
        4'd9:  in_stock <= (P_9 > 0);
        4'd10: in_stock <= (P_10 > 0);
        default: in_stock <= 0;
    endcase
end

endmodule
module product_quantity(
    input [3:0] product_no,
    input [3:0] product_qty,
    output reg no_taker
);

    always @(*) begin
        if (product_qty == 4'd0)
            no_taker = 1'b1;
        else
            no_taker = 1'b0;
    end

endmodule




