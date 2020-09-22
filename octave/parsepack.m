%% parsepack - supplimentary function for parsing K12 frame captures
% Usage: [pack_data, src_mac, src_ip] = parsepack(str)
%   str - sring with frame data from K12 file
%   pack_data - byte array of frame data
%   src_mac   - MAC address of the source device
%   src_ip    - IP address of the source device
%
%%*********Logical analyzer for long-term jitter monitoring*************
%%MIREA - Russian Technological University, 2020
%%Author: Alexey M. Romanov
%% 
%%Distributed under the Creative Commons Attribution-ShareAlike license
%%**********************************************************************

function [pack_data, src_mac, src_ip] = parsepack(str)
  strc=str(7:end);
  strr=strrep(strc,"|","");
  strr=strrep(strr," ","");
  strr=strrep(strr,sprintf("\n"),"");
  strr=strrep(strr,sprintf("\r"),"");
  pack_data=hex2dec(reshape(strr',2,[])');
  src_mac=pack_data(7:12);;
  src_ip=pack_data(27:30);;
end

