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



