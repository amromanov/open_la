%% Core information file for COREBase toolbox
function [ info ] = core_info_ice(  )
info.name = 'ws_logger_ice40'; %Core name. Should be same as name of top-module filename
info.deps = {};  %List of core names, required by current core. Example: info.deps={'core_name_1','core_name_2'};
info.files = {'../cores/crc32.v','../cores/udp_send.v','../cores/ws_log_ch.v',...
              '../cores/ws_log_max.v','../cores/ws_trigger_ch.v','../cores/rmii_send_byte_v2.v'}; %List of other core files, that should be included during build. Put '@' after filepath if file have to be copied into the build directory. Example: info.files={'filename2.vhd','filename2.v@'};
info.part_code = 'tq144'; %FPGA part code according to http://www.clifford.at/icestorm/
info.part_size = '1k'; %FPGA size
info.synth_opts = '-abc2'; %Yosys synthesis parameters;
info.yosys_opts = ''; %Yosys command string parameters;
info.par_opts= ''; %Arachne-pnr PAR 
info.pcf_filename= 'pins.pcf'; %path to PCF file
info.timing_report= 1; %Generate timing report
info.tmr_model= 'hx1k'; %Chip model for timing analysis
info.tmr_opts= '-mit'; %Timing analysis parameters
end
