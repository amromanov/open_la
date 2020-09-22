%% parse_k12 - function, which parses K12 frame captures from logical
%              analyser.
%
% Usage: packs = parse_k12(filename,iN,s_mac, s_ip)
%   filename  - K12-format filename
%   iN        - Total number of captured frames (used to speed up memory
%               (initialization, can be set to 1);
%   s_mac     - MAC address of the logica analyzer (to filter its frames)
%   s_ip      - IP address  of the logica analyzer (to filter its frames)
%   packs     - output packs with data from logic analyzer
%
%%*********Logical analyzer for long-term jitter monitoring*************
%%MIREA - Russian Technological University, 2020
%%Author: Alexey M. Romanov
%% 
%%Distributed under the Creative Commons Attribution-ShareAlike license
%%**********************************************************************

function packs = parse_k12(filename,iN,s_mac, s_ip)
  f=fopen(filename);
  state=0;
  i = 0;
  n = 0;
  packs(iN).data=0;
  tic;
  while(~feof(f))
    s=fgets(f);
    if(mod(n,1024*4)==0)
      toc
      fprintf('Parsing pack %i\n',i)
      tic
    end
    n=n+1;
    switch(state)
      case 0
           if(s(1)=="+")  %Start of frame
                state = 1;
           end
      case 1  
           state = 2;   %Timestamp
%           Commented to increase performance           
%           hh=str2double(s(1:2));
%           mm=str2double(s(4:5));
%           ss=str2double(s(7:8));
%           ms=str2double(s(10:12));
%           us=str2double(s(14:16));
%           pack.time=hh*60*60+mm*60+ss+ms/1000+us/1000000; 
      case 2            %Frame data
           i=i+1;
           [packs(i).data src_mac, src_ip]=parsepack(s);
           if((src_mac~=s_mac)||(src_ip~=s_ip))
              i=i-1;            
           end
           state = 0;
    endswitch
  end
  packs=packs(1:i);
  fclose(f);
  toc
end