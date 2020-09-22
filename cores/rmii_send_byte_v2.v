//*********Logical analyzer for long-term jitter monitoring*************
//
//  IP core, which transmits data from FPGA to Ethernet throught 
//  PHY, equipped with RMII interface (tested on LAN8720A)
//  (Version for 50 MHz FPGA clock)
//
//MIREA - Russian Technological University, 2020
//Author: Alexey M. Romanov
// 
//Distributed under the Creative Commons Attribution-ShareAlike license
//**********************************************************************

module rmii_send_byte_v2(
    input rst,                  //Asynchrnous reset
    input clk,                  //50 Mhz source clock 
    input start,                //Start strob
    input fast_eth,             //Ethernet speed 0 - 10 Mbps, 1 - 100 Mbps    
    input [7:0]data,            //Data to send
    output reg rm_tx_en,        //RMII enable
    output reg [1:0]rm_tx_data, //RMII data
    output reg rdy              //Ready to transmit flag
);

reg [4:0]wait_cnt;     

reg [5:0]tx_data;       
reg [1:0]bit_cnt;     

always @(posedge rst, posedge clk)
    if(rst)
    begin
        rm_tx_data <= 0;
        rm_tx_en <= 0;
        wait_cnt <= 0;
        rdy <= 1;
        bit_cnt <= 0;
		tx_data <= 0;
    end else
        if(wait_cnt==0)
	        begin
	            if(rdy)
		            begin   
		                if(start)
			                begin
    							rm_tx_en <= 1;  
	                    		{tx_data,rm_tx_data} <= data;
								bit_cnt <= 1;
	                    		rdy <= 0;
								if(!fast_eth)
		                        	wait_cnt <=9;
			                end 
						else
		                    begin               
		                        rm_tx_en <= 0;  
		                        rm_tx_data <= 0;
		                    end    
		            end 
				else
	                begin
                        if(rm_tx_en)
                        begin
                            {tx_data,rm_tx_data} <= {2'b00,tx_data};        
                            bit_cnt <= bit_cnt + 1;
                        end
                        if(!fast_eth)
                            wait_cnt <=9;

	                    if(bit_cnt=={fast_eth,fast_eth})               
	                    begin
	                        rdy <= 1;
	                        wait_cnt <=0;                                
	                    end
	                end
	        end 
		else
        begin
            wait_cnt <= wait_cnt - 1;                               
            if(~fast_eth)
            begin
                if((wait_cnt == 1)&&(bit_cnt==0))          
                    rdy <= 1;                               
            end        
        end
endmodule
