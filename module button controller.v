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

