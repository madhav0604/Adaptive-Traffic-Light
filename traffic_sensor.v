
module traffic_sensor(
    input clk,
    output reg [1:0] sensor
);
    always @(posedge clk) begin
    sensor <= $random % 4;
    end
endmodule