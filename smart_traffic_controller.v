module smart_traffic_controller (
    input clk,
    input reset,
    
    input [1:0] sensor_north, sensor_south, sensor_east, sensor_west,
    output reg light_north_red,
    output reg light_north_yellow,
    output reg light_north_green_straight,
    output reg light_north_green_right,
    output reg light_south_red,
    output reg light_south_yellow,
    output reg light_south_green_straight,
    output reg light_south_green_right,
    output reg light_east_red,
    output reg light_east_yellow,
    output reg light_east_green_straight,
    output reg light_east_green_right,
    output reg light_west_red,
    output reg light_west_yellow,
    output reg light_west_green_straight,
    output reg light_west_green_right
);

    reg [3:0] state;
    reg start_timer; 
    reg [31:0] duration;
    wire timeout;
    reg prev_timeout;

    timer t1 (
        .clk(clk),
        .reset(reset),
        .start_timer(start_timer),
        .load_value(duration),
        .timeout(timeout)
    );
    function [31:0] get_dynamic_green_total;
        input [1:0] sensor;
        begin
            case(sensor)
                2'b00: get_dynamic_green_total = 30;   //No traffic
                2'b01: get_dynamic_green_total = 45;   //Low traffic
                2'b10: get_dynamic_green_total = 70;   //Medium traffic
                2'b11: get_dynamic_green_total = 100;  //High traffic
                default: get_dynamic_green_total = 45;
            endcase
        end
    endfunction

    // 70% of total time is straight+right
    function [31:0] get_straight_right_duration;
        input [1:0] sensor;
        begin
            get_straight_right_duration = (get_dynamic_green_total(sensor) * 7) / 10;
        end
    endfunction

    //30%
    function [31:0] get_straight_only_duration;
        input [1:0] sensor;2
        begin
            get_straight_only_duration = get_dynamic_green_total(sensor) - get_straight_right_duration(sensor);
        end
    endfunction

    //fsm
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 1;
            start_timer <= 1;
            duration <= get_straight_right_duration(sensor_south);
            prev_timeout <= 0;
        end 
        else begin
            prev_timeout <= timeout;
            
            if (timeout && !prev_timeout) begin
                start_timer <= 0; 
                case (state)
                    1: begin // South straight+right
                        state <= 2;
                        duration <= get_straight_only_duration(sensor_south);
                    end
                    2: begin 
                        state <= 3;
                        duration <= 5; //yellow
                    end
                    3: begin
                        state <= 4;
                        duration <= get_straight_right_duration(sensor_north);
                    end
                    4: begin 
                        state <= 5;
                        duration <= 5;
                    end
                    5: begin
                        state <= 6;
                        duration <= get_straight_right_duration(sensor_east);
                    end
                    6: begin // East straight+right
                        state <= 7;
                        duration <= get_straight_only_duration(sensor_east);
                    end
                    7: begin //East straight + West straight
                        state <= 8;
                        duration <= 5; //yellow
                    end
                    8: begin
                        state <= 9;
                        duration <= get_straight_right_duration(sensor_west);
                    end
                    9: begin 
                        state <= 10;
                        duration <= 5; //yellow
                    end
                    10: begin 
                        state <= 1;
                        duration <= get_straight_right_duration(sensor_south);
                    end
                endcase
                start_timer <= 1;
            end
            else if (!timeout) begin
                start_timer <= 0; 
            end
        end
    end

    always @(*) begin
        light_north_red = 1; light_north_yellow = 0; 
        light_north_green_straight = 0; light_north_green_right = 0;
        
        light_south_red = 1; light_south_yellow = 0; 
        light_south_green_straight = 0; light_south_green_right = 0;
        
        light_east_red = 1; light_east_yellow = 0; 
        light_east_green_straight = 0; light_east_green_right = 0;
        
        light_west_red = 1; light_west_yellow = 0; 
        light_west_green_straight = 0; light_west_green_right = 0;

        case (state)
            1: begin // South straight+right
                light_south_red = 0;
                light_south_green_straight = 1;
                light_south_green_right = 1;
            end
            2: begin // South straight+North straight
                light_south_red = 0;
                light_south_green_straight = 1;
                light_north_red = 0;
                light_north_green_straight = 1;
            end
            3: begin //South yellow, North straight continues
                light_south_red = 0;
                light_south_yellow = 1;
                light_north_red = 0;
                light_north_green_straight = 1;
            end
            4: begin //North straight+right
                light_north_red = 0;
                light_north_green_straight = 1;
                light_north_green_right = 1;
            end
            5: begin // North yellow
                light_north_red = 0;
                light_north_yellow = 1;
            end
            6: begin //East straight+right
                light_east_red = 0;
                light_east_green_straight = 1;
                light_east_green_right = 1;
            end
            7: begin //East straight +West straight
                light_east_red = 0;
                light_east_green_straight = 1;
                light_west_red = 0;
                light_west_green_straight = 1;
            end
            8: begin //East yellow, West straight continue
                light_east_red = 0;
                light_east_yellow = 1;
                light_west_red = 0;
                light_west_green_straight = 1;
            end
            9: begin //West straight+right
                light_west_red = 0;
                light_west_green_straight = 1;
                light_west_green_right = 1;
            end
            10: begin //West yellow
                light_west_red = 0;
                light_west_yellow = 1;
            end
        endcase
    end

endmodule