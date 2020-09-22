//*********Logical analyzer for long-term jitter monitoring*************
//
//  IP core, which timestamps input channel edges using FPGA clock
//
//MIREA - Russian Technological University, 2020
//Author: Alexey M. Romanov
// 
//Distributed under the Creative Commons Attribution-ShareAlike license
//**********************************************************************

module ws_log_ch  #(parameter Nm = 16,        //Size of measurement
                              Na = 5          //Antibounce delay line length
)(
    input rst,                  //Async reset
    input clk,                  //Clock
    input ch,                   //Input channel
    input [Nm-1:0]m_cnt,        //Number of clocks from period start
    input st_start,             //Start of measurement
    input st_rdy,               //Strobe that measurement period is finished and ready to be transmitted
    output reg edge_type,       //Edge type (0 - negative edge, 1 - positive edge)
    output reg [Nm-1:0]ts       //Edge timestamp
);
/* verilator lint_off CLKDATA */


//Syncrhonizer
reg _ch;
reg s_ch;
reg ss_ch;
reg [Na-1:0]dl;     //Antibounce delay line

always @(posedge clk, posedge rst)
    if(rst)
     {_ch, dl, s_ch, ss_ch} <= 0;
    else
     {_ch, dl, s_ch, ss_ch} <= {ch, _ch, dl, s_ch};

//Edge detector
reg st_edge;

always @(posedge clk, posedge rst)
    if(rst)
        st_edge <= 0;
    else begin
            st_edge <= 0;
            if((&(~dl))|(&dl))              //if signal stays constant for Na cycles
               st_edge <= (s_ch!=ss_ch);
         end

//Timestamping
reg [Nm-1:0]pre_ts;

always @(posedge clk, posedge rst)
    if(rst)
    begin
        pre_ts <= 0;
    end else
        begin
            if(st_start)
                pre_ts <= 0;
            if(st_edge)
                pre_ts <= m_cnt;
        end

always @(posedge clk, posedge rst)
    if(rst)
    begin
        ts <= 0;
        edge_type <= 0;
    end 
    else if(st_rdy)
         begin
            edge_type <= s_ch;
            ts <= pre_ts;
         end
endmodule

