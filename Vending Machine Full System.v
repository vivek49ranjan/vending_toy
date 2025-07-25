`timescale 1ns / 1ps

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
    input logic [3:0] initial_product_qty [0:9],

    output wire invalid_coin,
    output wire max_balance,
    output reg in_stock,
    output reg not_available_balance,
    output wire [3:0] five, ten, twenty, fifty, hundred,
    output wire [3:0] product_dispensed
);

    wire [7:0] balance;
    wire [3:0] button_pressed;
    wire [7:0] price;
    wire press_valid_button;
    wire S_Row;
    wire [3:0] Row;
    wire [3:0] col;

    reg [1:0] state;
    reg [3:0] product_button;
    reg [3:0] product_qty [0:9];
    wire no_taker;

    parameter S_idle = 2'b00, S_product_selected = 2'b01, S_dispense_prep = 2'b10, S_dispensing = 2'b11;

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 10; i = i + 1) begin
                product_qty[i] <= initial_product_qty[i];
            end
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_idle;
            product_button <= 4'b0000;
        end else begin
            case(state)
                S_idle: begin
                    if (press_valid_button) begin
                        product_button <= button_pressed;
                        state <= S_product_selected;
                    end
                end
                S_product_selected: begin
                    state <= S_dispense_prep;
                end
                S_dispense_prep: begin
                    if (in_stock && !not_available_balance) begin
                        if (is_product_out) begin
                           if (product_button >= 1 && product_button <= 10) begin
                              product_qty[product_button - 1] <= product_qty[product_button - 1] - 1;
                           end
                           state <= S_dispensing;
                        end
                    end else begin
                        state <= S_idle;
                    end
                end
                S_dispensing: begin
                    state <= S_idle;
                end
                default: state <= S_idle;
            endcase
        end
    end

    wire [7:0] credit_in_from_coins;
    wire new_invalid_coin;
    wire new_max_balance;

    credit_manager coin_handler(
        .coin(coin),
        .coin_in(coin_in),
        .reset(reset),
        .balance_out(credit_in_from_coins),
        .invalid_coin(new_invalid_coin),
        .max_balance(new_max_balance)
    );

    assign invalid_coin = new_invalid_coin;
    assign max_balance = new_max_balance;

    reg [7:0] system_balance;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            system_balance <= 8'd0;
        end else begin
            if (coin_in) begin
                system_balance <= credit_in_from_coins;
            end else if (is_product_out && (price <= system_balance) && in_stock) begin
                system_balance <= system_balance - price;
            end else if (refund) begin
                system_balance <= 8'd0;
            end
        end
    end

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
        .calculate_price(state == S_dispense_prep),
        .price(price)
    );

    product_out dispenser(
        .clk(clk),
        .reset(reset),
        .price(price),
        .credit(system_balance),
        .product_no(product_button),
        .request_dispense(is_product_out),
        .product_dispensed(product_dispensed)
    );

    product_validation validator(
        .credit(system_balance),
        .price(price),
        .product_out_trigger(is_product_out),
        .not_available_balance(not_available_balance)
    );

    return_money returner(
        .refund(refund),
        .credit(system_balance),
        .five(five),
        .ten(ten),
        .twenty(twenty),
        .fifty(fifty),
        .hundred(hundred)
    );

    product_input check(
        .P_1(product_qty[0]), .P_2(product_qty[1]), .P_3(product_qty[2]), .P_4(product_qty[3]),
        .P_5(product_qty[4]), .P_6(product_qty[5]), .P_7(product_qty[6]), .P_8(product_qty[7]),
        .P_9(product_qty[8]), .P_10(product_qty[9]),
        .product_no(product_button),
        .product_check_trigger(state == S_dispense_prep),
        .in_stock(in_stock)
    );

    product_quantity quantify (
        .product_no(product_button),
        .selected_product_qty(product_qty[product_button - 1]),
        .no_taker(no_taker)
    );

endmodule

module credit_manager(
    input [4:0] coin,
    input coin_in,
    input reset,
    output reg [7:0] balance_out,
    output reg invalid_coin,
    output reg max_balance
);

    localparam R_5     = 5'b00001;
    localparam R_10    = 5'b00010;
    localparam R_20    = 5'b00100;
    localparam R_50    = 5'b01000;
    localparam R_100   = 5'b10000;
    localparam R_in    = 5'b11111;

    always @(posedge coin_in or posedge reset) begin
        if (reset) begin
            balance_out <= 8'd0;
            invalid_coin <= 1'b0;
            max_balance <= 1'b0;
        end else begin
            invalid_coin <= 1'b0;
            max_balance <= 1'b0;

            case (coin)
                R_5:    balance_out <= balance_out + 8'd5;
                R_10:   balance_out <= balance_out + 8'd10;
                R_20:   balance_out <= balance_out + 8'd20;
                R_50:   balance_out <= balance_out + 8'd50;
                R_100:  balance_out <= balance_out + 8'd100;
                R_in:   invalid_coin <= 1'b1;
                default: invalid_coin <= 1'b1;
            endcase

            if (balance_out > 8'd250) begin
                max_balance <= 1'b1;
            end
        end
    end

endmodule

module button(
    output reg [3:0] code,
    output reg [3:0] col,
    output wire valid,
    input [3:0] row,
    input S_Row,
    input clock, reset
);

    reg [5:0] state, next_state;

    parameter S_0 = 6'b000001, S_1 = 6'b000010, S_2 = 6'b000100;
    parameter S_3 = 6'b001000, S_4 = 6'b010000, S_5 = 6'b100000;

    assign valid = ((state == S_1) || (state == S_2) || (state == S_3) || (state == S_4)) && (row != 4'b0000);

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
            default: next_state = S_0;
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
        4'd1: selected_price = price_of_all[7:0];
        4'd2: selected_price = price_of_all[15:8];
        4'd3: selected_price = price_of_all[23:16];
        4'd4: selected_price = price_of_all[31:24];
        4'd5: selected_price = price_of_all[39:32];
        4'd6: selected_price = price_of_all[47:40];
        4'd7: selected_price = price_of_all[55:48];
        4'd8: selected_price = price_of_all[63:56];
        4'd9: selected_price = price_of_all[71:64];
        4'd10: selected_price = price_of_all[79:72];
        default: selected_price = 8'd0;
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
    input clk,
    input reset,
    input [7:0] price,
    input [7:0] credit,
    input [3:0] product_no,
    input request_dispense,
    output reg [7:0] updated_credit,
    output reg [3:0] product_dispensed
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        updated_credit <= 8'd0;
        product_dispensed <= 4'b0000;
    end else begin
        updated_credit <= credit;
        product_dispensed <= 4'b0000;

        if (request_dispense) begin
            if (credit >= price) begin
                updated_credit <= credit - price;
                product_dispensed <= product_no;
            end
        end
    end
end

endmodule

module product_validation (
    input [7:0] credit,
    input [7:0] price,
    input product_out_trigger,
    output reg not_available_balance
);

always @(posedge product_out_trigger) begin
    if (price > credit)
        not_available_balance <= 1'b1;
    else
        not_available_balance <= 1'b0;
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

always @(posedge refund) begin
    reg [7:0] temp_credit;

    five      <= 4'd0;
    ten       <= 4'd0;
    twenty    <= 4'd0;
    fifty     <= 4'd0;
    hundred   <= 4'd0;

    temp_credit = credit;

    while (temp_credit >= 8'd100) begin
        temp_credit = temp_credit - 8'd100;
        hundred <= hundred + 4'd1;
    end

    while (temp_credit >= 8'd50) begin
        temp_credit = temp_credit - 8'd50;
        fifty <= fifty + 4'd1;
    end

    while (temp_credit >= 8'd20) begin
        temp_credit = temp_credit - 8'd20;
        twenty <= twenty + 4'd1;
    end

    while (temp_credit >= 8'd10) begin
        temp_credit = temp_credit - 8'd10;
        ten <= ten + 4'd1;
    end

    while (temp_credit >= 8'd5) begin
        temp_credit = temp_credit - 8'd5;
        five <= five + 4'd1;
    end
end

endmodule

module product_input(
    input [3:0] P_1, P_2, P_3, P_4, P_5, P_6, P_7, P_8, P_9, P_10,
    input [3:0] product_no,
    input product_check_trigger,
    output reg in_stock
);

always @(posedge product_check_trigger) begin
    case (product_no)
        4'd1:  in_stock <= (P_1 > 4'd0);
        4'd2:  in_stock <= (P_2 > 4'd0);
        4'd3:  in_stock <= (P_3 > 4'd0);
        4'd4:  in_stock <= (P_4 > 4'd0);
        4'd5:  in_stock <= (P_5 > 4'd0);
        4'd6:  in_stock <= (P_6 > 4'd0);
        4'd7:  in_stock <= (P_7 > 4'd0);
        4'd8:  in_stock <= (P_8 > 4'd0);
        4'd9:  in_stock <= (P_9 > 4'd0);
        4'd10: in_stock <= (P_10 > 4'd0);
        default: in_stock <= 1'b0;
    endcase
end

endmodule

module product_quantity(
    input [3:0] product_no,
    input [3:0] selected_product_qty,
    output reg no_taker
);

    always @(*) begin
        if (selected_product_qty == 4'd0)
            no_taker = 1'b1;
        else
            no_taker = 1'b0;
    end

endmodule

module Synchronize(
    input S_Row,
    input [3:0] row,
    input clock,
    input reset
);
endmodule

module Row_Signal(
    input [3:0] Row,
    input [15:0] Key,
    output wire [3:0] Col
);
    assign Col = 4'b0000;
endmodule
