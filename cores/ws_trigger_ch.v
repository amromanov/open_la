//*********Logical analyzer for long-term jitter monitoring*************
//
//  IP core, which triggers measurement of slave channels according
//  to edges of the master channel
//
//MIREA - Russian Technological University, 2020
//Author: Alexey M. Romanov
// 
//Distributed under the Creative Commons Attribution-ShareAlike license
//**********************************************************************

module ws_trigger_ch  #(parameter Np = 16,       //Size of period
                                  Nm = 16,       //Size of measurement
                                  Nc = 32,       //Period counter
                                  Na = 5         //Antibounce delay line length
)(
    input rst,                  //Async reset
    input clk,                  //Clock
    input ch,                   //Input channel
    input [Np-1:0]period,       //Predicted duration between edges
    input [Nm-1:0]mes_period,   //Duration of measurments
    output reg [Nm-1:0]m_cnt,   //Number of clocks from period start
    output reg [Nc-1:0]p_cnt,   //Period counter
    output st_start,            //Start of measurement
    output st_rdy               //Strobe that measurement period is finished and ready to be transmitted
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

//Period counter
always @(posedge clk, posedge rst)
    if(rst)
        p_cnt <= 0;
    else if(st_edge)
            p_cnt <= p_cnt +1;

//Measurement start counters
reg [Np:0]wait_cnt;

/* verilator lint_off WIDTH */
always @(posedge clk, posedge rst)
    if(rst)
        wait_cnt <= -1;
    else begin
            if(~wait_cnt[Np])
                wait_cnt <= wait_cnt - 1;
            if(st_edge)
                wait_cnt <= period - (mes_period>>1);
         end
/* verilator lint_on WIDTH */

assign st_start = (wait_cnt==0);

reg [Nm:0]mes_cnt;

always @(posedge clk, posedge rst)
    if(rst)
    begin
        mes_cnt <= -1;
        m_cnt <= 0;
    end else
        begin
            if(~mes_cnt[Nm])
            begin
                mes_cnt <= mes_cnt -1;
                m_cnt <= m_cnt + 1;
            end
            if(st_start)
            begin
              mes_cnt <= {1'b0,mes_period};
              m_cnt <= 0;
            end
        end

assign st_rdy = (mes_cnt == 0);

endmodule

