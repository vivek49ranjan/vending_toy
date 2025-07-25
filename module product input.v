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
