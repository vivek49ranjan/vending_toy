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
