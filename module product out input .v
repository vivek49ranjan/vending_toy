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
