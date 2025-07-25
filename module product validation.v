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
