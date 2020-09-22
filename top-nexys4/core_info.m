%% Core information file for COREBase toolbox
function [ info ] = core_info(  )
info.name = 'ws_logger'; %Core name. Should be same as name of top-module filename
info.deps = {};  %List of core names, required by current core. Example: info.deps={'core_name_1','core_name_2'};
info.files = {'../cores/crc32.v','../cores/udp_send.v','../cores/ws_log_ch.v',...
              '../cores/ws_log_max.v','../cores/ws_trigger_ch.v','../cores/rmii_send_byte.v'}; %List of other core files, that should be included during build. Put '@' after filepath if file have to be copied into the build directory. Example: info.files={'filename2.vhd','filename2.v@'};
%info.init = 'core_init'; %uncomment to run core_init.m script during build procedure. (core_init.m should be created separatly); 
info.part_code = 'xc7a100t-1csg324'; %FPGA part code according to Xilinx ISE
info.prom_code = 'xcf04s'; %PROM device part code according to Xilinx ISE
info.opt_level = 1; %XST synthesis optimization effort level: 1 - normal optimization, 2 - higher optimization
info.opt_mode = 'Speed'; %XST optimization goal: Speed, Area
info.xst_synth_params = ''; %XST synthesis parameters. Example: info.xst_synth_params = '-mult_style block -ram_style distributed';
info.bit_gen_flags= '-g UnconstrainedPins:Allow -g TdoPin:PULLNONE -g DonePin:PULLUP -g CRC:enable -g StartUpClk:CCLK'; %Bitstream generation flags
info.ucf_filename= 'pins.ucf'; %path to UCF file
info.prom_device_num=2; %PROM device number in JTAG chain
info.fpga_device_num=1; %FPGA device number in JTAG chain
end