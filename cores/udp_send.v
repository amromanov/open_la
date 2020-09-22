//*********Logical analyzer for long-term jitter monitoring*************
//
//  IP core, which generates outgoing UDP frames with defined payload
//
//MIREA - Russian Technological University, 2020
//Author: Alexey M. Romanov
// 
//Distributed under the Creative Commons Attribution-ShareAlike license
//**********************************************************************

module udp_send #(parameter dst_addr = 48'hFF_FF_FF_FF_FF_FF,       //Destination MAC address (broadcast)
                            src_addr = 48'h00_12_34_56_78_90,       //Source MAC address
                            dst_ip   = {8'd192,8'd168,8'd0,8'd255}, //IP destination address (broadcast)
                            src_ip   = {8'd192,8'd168,8'd0,8'd2},   //IP source address
                            dst_port = 16'd1024,                    //Destination port
                            src_port = 16'd1024,                    //Source port
                            Nsz      = 7,                           //Transmitted byte counter bitsize. Nsz=ceil(log2(55+p_sz))
                            p_sz     = 32'd18                       //Payload size in bytes (minimum size is 18 to make valid 64 byte  Ethernet frame)
)(
	input	clk,					// Input clock
	input 	rst,					// Asyncrhonous reset
	input	start,					// Start strobe
	input   [7:0]payload,       	// Payload data
    output  [Nsz-1:0]addr,          // Payload byte number
	input   tx_rdy,					// RMII transmitter core rdy signal
	output reg [7:0] tx_data,		// RMII transmitter core data signal
	output reg tx_start,			// RMII transmitter core start strobe
	output reg rdy				    // Ready to send flag
	);

//IP header checksum evaluation
wire [15:0]ip_crc;          //IP header checksum
wire [31:0]ip_crc_step0;    
wire [31:0]ip_crc_step1;    

assign ip_crc_step0 = 32'h4500 + 32'd0028 + p_sz + 32'h0000 + 32'h0000 + 32'h4011 + 32'h0000 + {16'd0,src_ip[31:16]} + {16'd0,src_ip[15:0]} + {16'd0,dst_ip[31:16]} + {16'd0,dst_ip[15:0]};
assign ip_crc_step1 = {16'd0,ip_crc_step0[31:16]}+{16'd0,ip_crc_step0[15:0]};
assign ip_crc = ~(ip_crc_step1[31:16]+ip_crc_step1[15:0]); 

//Ethernet checksum evaluations
reg  [31:0]crc;	            //Previous value of checksum
wire [31:0]new_crc;         //Updatated checksum
												 
crc32 CRC32 (               
	.d({tx_data[0],tx_data[1],tx_data[2],tx_data[3],tx_data[4],tx_data[5],tx_data[6],tx_data[7]}),
	.c(crc),
	.newcrc(new_crc)
);

//Reversing Ethernve checksum bit order
reg [31:0]rev_crc;         
integer i;
always @*
begin
    for ( i=0; i < 32; i=i+1 )
        rev_crc[i] = new_crc[31-i];
end

reg [31:0]eth_crc;          //Final Ethernet frame CRC32 checksum

reg [Nsz-1:0] state_m;             //Transmitted byte number
parameter st_idle = (1<<Nsz)-1;    //Special idle state between trasnmissions

wire [15:0]ip_size;         //Size of IP part (header + payload)
assign ip_size = 28+p_sz;
wire [15:0]udp_size;        //Size of UDP part (header + payload)
assign udp_size = 8+p_sz;
				
assign addr = state_m-50;

always @(posedge clk or posedge rst)
    if(rst)
        tx_data <= 0;
    else case(state_m)
      st_idle  : tx_data <= 8'h55;               //Idle state (ready to start next preamble)
            0  : tx_data <= 8'h55;               //Preamble
            1  : tx_data <= 8'h55;
            2  : tx_data <= 8'h55;
            3  : tx_data <= 8'h55;
            4  : tx_data <= 8'h55;
            5  : tx_data <= 8'h55;
            6  : tx_data <= 8'h55;
            7  : tx_data <= 8'hD5;               //End of preamble
//--------------Ethernet checksum is evaluated from here----------//
            8  : tx_data <= dst_addr[47:40];     //Destination MAC address
            9  : tx_data <= dst_addr[39:32];
            10 : tx_data <= dst_addr[31:24];
            11 : tx_data <= dst_addr[23:16];
            12 : tx_data <= dst_addr[15: 8];
            13 : tx_data <= dst_addr[ 7: 0];
            14 : tx_data <= src_addr[47:40];     //Source MAC address
            15 : tx_data <= src_addr[39:32];
            16 : tx_data <= src_addr[31:24];
            17 : tx_data <= src_addr[23:16];
            18 : tx_data <= src_addr[15: 8];
            19 : tx_data <= src_addr[ 7: 0];
            20 : tx_data <= 8'h08;               //Protocol type - IP (0x0800)        
            21 : tx_data <= 8'h00;          
//-------------IP part starts here---------------------------------// 
            22 : tx_data <= 8'h45;               //IP protocol type (0x4500)
            23 : tx_data <= 8'h00;                    
            24 : tx_data <= ip_size[15:8];       //Datagram length (2 bytes)                   
            25 : tx_data <= ip_size[7:0];        
            26 : tx_data <= 8'h00;               //IPv4 service fields                  
            27 : tx_data <= 8'h00;
            28 : tx_data <= 8'h00;
            29 : tx_data <= 8'h00;
            30 : tx_data <= 8'h40;               //Datagram time to live (TTL)
            31 : tx_data <= 8'h11;               //IP protocol type - UDP (0x11)
            32 : tx_data <= ip_crc[15: 8];       //IP header CRC
            33 : tx_data <= ip_crc[ 7: 0];         
            34 : tx_data <= src_ip[31:24];       //Source IP         
            35 : tx_data <= src_ip[23:16];                
            36 : tx_data <= src_ip[15: 8];                
            37 : tx_data <= src_ip[ 7: 0];                
            38 : tx_data <= dst_ip[31:24];       //Destination IP        
            39 : tx_data <= dst_ip[23:16];                
            40 : tx_data <= dst_ip[15: 8];                
            41 : tx_data <= dst_ip[ 7: 0];  
//--------------UDP part start here--------------------------------//                 
            42 : tx_data <= src_port[15: 8];     //Source port              
            43 : tx_data <= src_port[ 7: 0];                
            44 : tx_data <= dst_port[15: 8];     //Destination port                
            45 : tx_data <= dst_port[ 7: 0];                
            46 : tx_data <= udp_size[15:8];      //UDP size           
            47 : tx_data <= udp_size[7:0];
            48 : tx_data <= 8'h00;               //UDP checksum (0x0000 - do not check)
            49 : tx_data <= 8'h00;   
//-------------------Payload---------------------------------------//            
       default : tx_data <= payload;             //Transmitting payload
//----------Ethernet checksum--------------------------------------//  
     st_idle-4 : tx_data <= eth_crc[ 7: 0];      
     st_idle-3 : tx_data <= eth_crc[15: 8];        
     st_idle-2 : tx_data <= eth_crc[23:16];      
     st_idle-1 : tx_data <= eth_crc[31:24];     
         endcase


	always @(posedge clk or posedge rst)
		if(rst)
			begin
				tx_start <= 0;	 
				state_m <= st_idle; 
				crc <= -1;          //0xFFFF_FFFF
                eth_crc <= 0;
				rdy <= 1;
			end
		else 
			begin		  
			   if(tx_rdy)
			   begin
                 if(state_m==st_idle)
                 begin
					 if (start)                    //In case of start strobe
					 begin			
                        rdy <= 0;                  
					    tx_start <= 1;
					    state_m <= 0;	
						crc <= -1;	   
					 end else
                         rdy <= 1;
                 end else
                     begin
                        state_m <= state_m + 1;            //Increasing byte number        
                        if(|state_m[6:3])                  //Starting СRC evaluation after preamble (from 8th byte)
                            crc <= new_crc;                
                        if(state_m == (50+p_sz-1))            //Fixing and reversing checksum
                        begin
                            eth_crc <= ~rev_crc;      
                            state_m <= st_idle-4;    
                        end
                        if(state_m == (st_idle-1))         //If everything is transmitted
                        begin                              
                            crc <= -1; 
                            tx_start <= 0;
                            state_m <= st_idle;
                        end                                               
                     end
               end
            end
	
	
endmodule
