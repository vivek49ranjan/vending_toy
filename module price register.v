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

