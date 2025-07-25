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

