//*********Logical analyzer for long-term jitter monitoring*************
//
//  IP core, which transmits data from FPGA to Ethernet throught 
//  PHY, equipped with RMII interface (tested on LAN8720A)
//  (Version for 100 MHz FPGA clock)
//
//MIREA - Russian Technological University, 2020
//Author: Alexey M. Romanov
// 
//Distributed under the Creative Commons Attribution-ShareAlike license
//**********************************************************************

module rmii_send_byte(
    input rst,                  //Asynchrnous reset
    input clk,                  //100 Mhz source clock
    input rmii_clk,             //50 Mhz synchrnous RMII clock
    input start,                //Start strob
    input fast_eth,             //Ethernet speed 0 - 10 Mbps, 1 - 100 Mbps    
    input [7:0]data,            //Data to send
    output reg rm_tx_en,        //RMII enable
    output reg [1:0]rm_tx_data, //RMII data
    output reg rdy              //Ready to transmit flag
);

reg [4:0]wait_cnt;      //Wait counter for 10 Mbps 

reg [5:0]tx_data;       //Data buffer for immidiate transmission
reg [1:0]bit_cnt;       //Bit-pair counter

always @(posedge rst, posedge clk)
    if(rst)
    begin
        rm_tx_data <= 0;
        rm_tx_en <= 0;
        wait_cnt <= 0;
        rdy <= 1;
        bit_cnt <= 0;
    end else
        if(wait_cnt==0)
        begin
            if(rdy)
            begin   
                if(start)
                begin
                    if(rmii_clk)         
                        rm_tx_en <= 1;  
                    {tx_data,rm_tx_data} <= data; 
                    if((!fast_eth)&(rmii_clk))
                        wait_cnt <=18;
                    bit_cnt <= 1;
                    rdy <= 0;
                end else
                    begin              
                        rm_tx_en <= 0;
                        rm_tx_data <= 0;
                    end    
            end else
                begin
                    rm_tx_en <= 1;       
                    if(rmii_clk)         
                    begin
                        if(rm_tx_en)
                        begin
                            {tx_data,rm_tx_data} <= {2'b00,tx_data};        
                            bit_cnt <= bit_cnt + 1;                            
                        end
                        if(!fast_eth)
                                wait_cnt <=18;
                    end
                    if(bit_cnt==0)                                  
                    begin
                        rdy <= 1;
                        wait_cnt <=0;                               
                    end
                end
        end else
            wait_cnt <= wait_cnt - 1;                              
endmodule
