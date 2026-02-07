module timer (
    input clk,
    input reset,
    input start_timer,
    input [31:0] load_value,
    output reg timeout
);

    reg [31:0] counter;
    reg timer_running;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            timeout <= 0;
            timer_running <= 0;
        end else if (start_timer && !timer_running) begin
// Load new value when timer is not running
            counter <= load_value;
            timeout <= 0;
            timer_running <= 1;
        end else if (timer_running) begin
            if (counter == 1) begin
                counter <= 0;
                timeout <= 1;
                timer_running <= 0; 
            end else begin
                counter <= counter - 1;
                timeout <= 0;
            end
        end else begin
            timeout <= 0; 
        end
    end

endmodule