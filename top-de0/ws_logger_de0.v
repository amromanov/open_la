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

module ws_logger_de0 #(parameter Nc=16
)(
    input clkin,        //Input 50 Mhz clock
    input [Nc-1:0]ch,   //Trigger channel (master devices)
    output reg rm_clk,  //RMII Clock
    output [1:0]rm_tx,  //RMII Tx
    output rm_tx_en,    //RMII Tx enable
    output reg trg_led  //Led, which toggles every time UDP frame is transmitted
);



parameter Npr = 7;  //Prescaler settings (send UDP frame every 2^Npr measurement
parameter Nl  = 8;  //If jitter > (2^(16-Nl)-1) then frame would be sent on each edge
parameter Na  = 5;  //Antibounce delay line length in clk cycles

//******** Reset and reset signals *****************
reg rst;

initial rst = 1;
	 
wire clk;			//100 MHz clock

always @(posedge clk)
    rst <= 0;

alt_pll
	alt_pll(
		.inclk0(clkin),
		.c0(clk)
	);
	 

//******** Input channel analysis *******
//Edge timestamps
wire [15:0]ts[0:Nc-1];
//Evaluated jitter
wire [15:0]jtr[0:Nc-1];

wire [Nc-1:0]rdy_c;

//Measurment counter
reg [31:0]pcnt;

//Signal, which triggers UDP transmition
wire rdy; 
assign rdy = (|rdy_c);


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
        .ch(ch[0]),
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
        .ch(ch[0]),
        .m_cnt(m_cnt),
        .st_start(st_start),
        .st_rdy(st_rdy),
        .edge_type(),
        .ts(ts[0])
);

genvar channel;       //Номер ступени

generate
    for(channel=1; channel<Nc; channel=channel+1)
    begin:la_channels
        //Slave channel timestamping
        ws_log_ch #(.Nm(16),.Na(Na))
        ws_log_ch(
                .rst(rst),
                .clk(clk),
                .ch(ch[channel]),
                .m_cnt(m_cnt),
                .st_start(st_start),
                .st_rdy(st_rdy),
                .edge_type(),
                .ts(ts[channel])
        );

        //Slave channel worst-case jitter evaluation
        ws_log_max #(.Nm(16),.Npr(Npr),.Nl(Nl))     
        ws_log_max (
                .rst(rst),
                .clk(clk),
                .ts(ts[channel]),
                .tr(ts[0]),
                .st_rdy(st_rdy),
                .prescaler(pcnt[Npr-1:0]),
                .jtr(jtr[channel]),
                .rdy(rdy_c[channel])
        );    
    end
endgenerate


//***************UDP transmission interface****************     
reg [7:0]payload[0:(4+Nc*2)-1];     //Defining udp frame payload

integer i;

reg [15:0]pre_jtr;
always @(*)
    begin   
        payload[0]  = pcnt[7:0];
        payload[1]  = pcnt[15:8];
        payload[2]  = pcnt[23:16];
        payload[3]  = pcnt[31:24];
        for ( i=1; i < Nc; i=i+1 )
        begin
            pre_jtr = jtr[i];
            payload[4+i*2] = pre_jtr[7:0];
            payload[4+i*2+1] = pre_jtr[15:8];
        end
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

function integer log2;			//Функция выисления логорифма по основанию 2
  input integer value;
  begin
    for (log2=0; value>0; log2=log2+1)
      value = value>>1;
  end
endfunction

parameter Nsz_mem = log2(4+Nc*2);
parameter Nsz_udp = log2(55+4+Nc*2);

wire [Nsz_udp-1:0]addr;

//UDP transmission core
udp_send #(.dst_addr(48'hFF_FF_FF_FF_FF_FF),        //Broadcast
           .src_addr(48'h00_12_34_56_78_90),        //Some random MAC
           .dst_ip({8'd192,8'd168,8'd0,8'd255}),    //Broadcast
           .src_ip({8'd192,8'd168,8'd0,8'd2}),      //Some free IP
           .dst_port(10241),                        //Some free port
           .src_port(10241),
           .Nsz(Nsz_udp),                           //ceil(log2(55+p_sz))
           .p_sz((4+Nc*2)-1))                       //Payload size
udp_send(
        .clk(clk),
        .rst(rst),
        .start(rdy),
        .addr(addr),
        .payload(payload[addr[Nsz_mem-1:0]]),
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
