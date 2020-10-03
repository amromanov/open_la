//*********Logical analyzer for long-term jitter monitoring*************
//
//  IP core, which evaluates difference between reference and input
//  channels and finds maximum jitter during one prescaled period
//
//MIREA - Russian Technological University, 2020
//Author: Alexey M. Romanov
// 
//Distributed under the Creative Commons Attribution-ShareAlike license
//**********************************************************************

module ws_log_max #(parameter Nm  = 16,       //Size of measurement
                              Nl  = 8,        //If jitter > (2^(Nm-Nl)-1) then frame would be sent on each edge
                              Npr = 7         //Size of prescaler
)(
    input rst,                  //Async reset
    input clk,                  //Clock
    input [Nm-1:0]ts,           //Input channel edge timestamp (changes next cycle after st_rdy)
    input [Nm-1:0]tr,           //Reference channel edge timestamp (changes next cycle after st_rdy)
    input st_rdy,               //Strobe that measurement period is finished and ready to be transmitted
    input [Npr-1:0]prescaler,   //Lower size of frame counter when Npr==0 frame is transmitted
    output reg [Nm-1:0]jtr,     //Maximal jitter for the last 2^Np frames
    output reg rdy              //Strobe that jitter is ok
);

reg s_rdy;      //Strobe syncronous to ts and tr changes

always @(posedge clk, posedge rst)
    if(rst)
        s_rdy <= 0;
    else
        s_rdy <= st_rdy;

reg [3:0]state;
reg [Nm:0]mx;
reg [Nm:0]d;
reg [Nm+1:0]dm;
reg send_all;

always @(posedge clk, posedge rst)
    if(rst)
    begin
        mx <= 0;
        d <= 0;
        state <= 0;
        dm <= 0;
        rdy <= 0;
        jtr <= 0;
        send_all <= 0;
    end else
        begin
            rdy <= 0;
            case(state)
                0: begin
                        if(s_rdy)
                        begin
                            d <= {1'b0,ts}-{1'b0,tr};
                            state <= 1;
                        end
                   end
                1: begin
                        if(mx[Nm]==d[Nm])               //if sign is the same then -
                            dm <= {mx[Nm],mx}-{d[Nm], d};
                        else                            //if different change it to the same to compare abs
                            dm <= {mx[Nm],mx}+{d[Nm], d};
                        state <= 2;  
                   end
                2: begin
                        if(mx[Nm]!=dm[Nm+1])            //if sign changes then |mx|<|d|
                            mx <= d;
                        if(!((&d[Nm:Nm-Nl])|(&(~d[Nm:Nm-Nl]))))      //If jitter is higher then (2^(Nm-Nl)-1) send frame on each edge
                            send_all <= 1;                           //till the next time prescaler go to zero
                        state <= 3; 
                   end
                3: begin
                        if(prescaler==0)
                        begin
                            if(mx[Nm]==mx[Nm-1])        //Rounding
                                jtr <= mx[Nm-1:0];
                            else begin
                                     if(mx[Nm])
                                        jtr <= (1<<Nm);
                                     else
                                        jtr <= (1<<Nm)-1;
                                 end
                            mx <= 0;
                            send_all <= 0;
                            rdy <= 1;
                        end 
                        if(send_all)                  //If presecaler == 0, then override it, 
                        begin                                       
                            if(d[Nm]==d[Nm-1])        //Rounding
                                jtr <= d[Nm-1:0];
                            else begin
                                     if(d[Nm])
                                         jtr <= (1<<Nm);
                                     else
                                         jtr <= (1<<Nm)-1;
                                     end
                            rdy <= 1;                                
                        end
                        state <= 0;
                   end
            endcase
        end


endmodule
