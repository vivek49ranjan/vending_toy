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

