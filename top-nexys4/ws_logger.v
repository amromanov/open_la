//*********Logical analyzer for long-term jitter monitoring*************
//
//  Top module of 4-channel Logical analyzer for long-term 
//  jitter monitoring designed for Diggilent Nexys 4 DDR kit
//
//MIREA - Russian Technological University, 2020
//Author: Alexey M. Romanov
// 
//Distributed under the Creative Commons Attribution-ShareAlike license
//**********************************************************************

module ws_logger(
    input clk,          //Input 100 Mhz clock
    input ch0,          //Trigger channel (master devices)
    input ch1,          //Slave device 1
    input ch2,          //Slave device 2
    input ch3,          //Slave device 3
    input ch4,          //Slave device 4
    output reg rm_clk,  //RMII Clock
    output [1:0]rm_tx,  //RMII Tx
    output rm_tx_en,    //RMII Tx enable
    inout  [2:0]mode,   //Mode/RMII pins to turn on auto-negotiation
    output reg phy_rst, //PHY reset
    output reg trg_led  //Led, which toggles every time UDP frame is transmitted
);

parameter Npr = 7;  //Prescaler settings (send UDP frame every 2^Npr measurement
parameter Nl  = 8;  //If jitter > (2^(16-Nl)-1) then frame would be sent on each edge
parameter Na  = 5;  //Antibounce delay line length in clk cycles

//******** Reset signals *****************
reg rst;

initial rst = 1;

always @(posedge clk)
    rst <= 0;

always @(posedge rst, posedge clk)
    if(rst)
        phy_rst <= 0;
    else
        phy_rst <= 1;

assign mode = (phy_rst) ?  3'bzzz : 3'b000;     //During reset mode should be zero to move PHY in auto-negotiation mode, but them it should
                                                //be switched to z-state, because those pins are combined with RMII RX/CRS_DV channels

//******** Input channel analysis *******
//Edge timestamps
wire [15:0]ts0;
wire [15:0]ts1;
wire [15:0]ts2;
wire [15:0]ts3;
wire [15:0]ts4;
//Evaluated jitter
wire [15:0]jtr1;
wire [15:0]jtr2;
wire [15:0]jtr3;
wire [15:0]jtr4;

wire rdy1, rdy2, rdy3, rdy4;

//Measurment counter
reg [31:0]pcnt;

//Signal, which triggers UDP transmition
wire rdy; 
assign rdy = rdy1 | rdy2 | rdy3 |rdy4;


//Led control
always @(posedge clk, posedge rst)
    if(rst)
        trg_led <= 0;
    else if(rdy)
        trg_led <= ~trg_led;    

//Trigger on a channel 0
wire st_start;
wire st_rdy;
wire [15:0]m_cnt;
wire [31:0]p_cnt;

//
// ch0  ______/---------------------------\_____________
//            |                 |         |         |
//            |<----------- Tp--|-------->|         |
//                              |                   |
//                              |<-------Tm-------->|
// Start of edge timestamping-->|                   |
//                              |                   |
//                       End of edge timestamping-->|           
//

ws_trigger_ch #(.Np(16),.Nm(16),.Nc(32),.Na(Na))
ws_trigger_ch(
        .rst(rst),
        .clk(clk),
        .ch(ch0),
        .period(50000),                 //Desired period of the master clock (Tp) in clk cycles
        .mes_period(10000),             //Desired measurement period (Tm) in clk cycles
        .m_cnt(m_cnt),
        .p_cnt(p_cnt),
        .st_start(st_start),
        .st_rdy(st_rdy)
);

always @(posedge clk, posedge rst)
    if(rst)
        pcnt <= 0;
    else if(st_rdy)
            pcnt <= p_cnt;


//Master channel timestamping
ws_log_ch #(.Nm(16))
ws_log_ch0(
        .rst(rst),
        .clk(clk),
        .ch(ch0),
        .m_cnt(m_cnt),
        .st_start(st_start),
        .st_rdy(st_rdy),
        .edge_type(),
        .ts(ts0)
);


//Slave channel 1 timestamping
ws_log_ch #(.Nm(16),.Na(Na))
ws_log_ch1(
        .rst(rst),
        .clk(clk),
        .ch(ch1),
        .m_cnt(m_cnt),
        .st_start(st_start),
        .st_rdy(st_rdy),
        .edge_type(),
        .ts(ts1)
);

//Slave channel 1 worst-case jitter evaluation
ws_log_max #(.Nm(16),.Npr(Npr),.Nl(Nl+2))       //Use 4 times lower limit for this channel
ws_log_max1 (
        .rst(rst),
        .clk(clk),
        .ts(ts1),
        .tr(ts0),
        .st_rdy(st_rdy),
        .prescaler(pcnt[Npr-1:0]),
        .jtr(jtr1),
        .rdy(rdy1)
);


//Slave channel 2 timestamping
ws_log_ch #(.Nm(16),.Na(Na))
ws_log_ch2(
        .rst(rst),
        .clk(clk),
        .ch(ch2),
        .m_cnt(m_cnt),
        .st_start(st_start),
        .st_rdy(st_rdy),
        .edge_type(),
        .ts(ts2)
);

//Slave channel 2 worst-case jitter evaluation
ws_log_max #(.Nm(16),.Npr(Npr),.Nl(Nl))
ws_log_max2 (
        .rst(rst),
        .clk(clk),
        .ts(ts2),
        .tr(ts0),
        .st_rdy(st_rdy),
        .prescaler(pcnt[Npr-1:0]),
        .jtr(jtr2),
        .rdy(rdy2)
);

//Slave channel 3 timestamping
ws_log_ch #(.Nm(16),.Na(Na))
ws_log_ch3(
        .rst(rst),
        .clk(clk),
        .ch(ch3),
        .m_cnt(m_cnt),
        .st_start(st_start),
        .st_rdy(st_rdy),
        .edge_type(),
        .ts(ts3)
);

//Slave channel 3 worst-case jitter evaluation
ws_log_max #(.Nm(16),.Npr(Npr),.Nl(Nl))
ws_log_max3 (
        .rst(rst),
        .clk(clk),
        .ts(ts3),
        .tr(ts0),
        .st_rdy(st_rdy),
        .prescaler(pcnt[Npr-1:0]),
        .jtr(jtr3),
        .rdy(rdy3)
);

ws_log_ch #(.Nm(16),.Na(Na))
ws_log_ch4(
        .rst(rst),
        .clk(clk),
        .ch(ch4),
        .m_cnt(m_cnt),
        .st_start(st_start),
        .st_rdy(st_rdy),
        .edge_type(),
        .ts(ts4)
);

//Slave channel 4 timestamping
ws_log_max #(.Nm(16),.Npr(Npr),.Nl(Nl-2))       //Use 4 times higher limit for this channel
ws_log_max4 (
        .rst(rst),
        .clk(clk),
        .ts(ts4),
        .tr(ts0),
        .st_rdy(st_rdy),
        .prescaler(pcnt[Npr-1:0]),
        .jtr(jtr4),
        .rdy(rdy4)
);


//***************UDP transmission interface****************     
reg [7:0]payload[0:17];     //Defining udp frame payload

always @(*)
    begin   
        payload[0]  = pcnt[7:0];
        payload[1]  = pcnt[15:8];
        payload[2]  = pcnt[23:16];
        payload[3]  = pcnt[31:24];
        payload[4]  = jtr1[7:0];
        payload[5]  = jtr1[15:8];
        payload[6]  = jtr2[7:0];
        payload[7]  = jtr2[15:8];
        payload[8]  = jtr3[7:0];
        payload[9]  = jtr3[15:8];
        payload[10] = jtr4[7:0];
        payload[11] = jtr4[15:8];
        payload[12] = 0;
        payload[13] = 0;
        payload[14] = 0;
        payload[15] = 0;
        payload[16] = 0;
        payload[17] = 0;
    end

//Simple RMII clock generation
always @(posedge clk, posedge rst)
    if(rst)
        rm_clk <= 0;
    else
        rm_clk <= ~rm_clk;

wire tx_rdy;
wire [7:0]tx_data;
wire tx_start;

wire [6:0]addr;

//UDP transmission core
udp_send #(.dst_addr(48'hFF_FF_FF_FF_FF_FF),        //Broadcast
           .src_addr(48'h00_12_34_56_78_90),        //Some random MAC
           .dst_ip({8'd192,8'd168,8'd0,8'd255}),    //Broadcast
           .src_ip({8'd192,8'd168,8'd0,8'd2}),      //Some free IP
           .dst_port(10241),                        //Some free port
           .src_port(10241),
           .Nsz(7),                                 //ceil(log2(55+p_sz))
           .p_sz(18))                               //Payload size
udp_send(
        .clk(clk),
        .rst(rst),
        .start(rdy),
        .addr(addr),
        .payload(payload[addr[4:0]]),
        .tx_rdy(tx_rdy),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .rdy()
);

//RMII transmitter
rmii_send_byte
rmii_send_byte(
	.rst(rst),
	.clk(clk),
	.rmii_clk(rm_clk),
	.start(tx_start),
	.fast_eth(1),
	.data(tx_data),
	.rm_tx_en(rm_tx_en),
	.rm_tx_data(rm_tx),
	.rdy(tx_rdy)
);

endmodule
