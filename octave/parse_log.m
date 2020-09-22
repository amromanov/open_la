%%*********Logical analyzer for long-term jitter monitoring*************
%%MIREA - Russian Technological University, 2020
%%Author: Alexey M. Romanov
%% 
%%Distributed under the Creative Commons Attribution-ShareAlike license
%%**********************************************************************

%Parsing K12 capture from logic analyzer
%Passing MAC and IP addresses of the logica analyser to the fucntion
packs=parse_k12('logdump.txt',64,...
                [hex2dec('00'); hex2dec('12'); hex2dec('34'); hex2dec('56'); hex2dec('78'); hex2dec('90')],...
                [192; 168; 0; 2]);
                
ts=10;     %Timescale 10 ns per FPGA clock cycle (100 MHz clock)
freq=1000; %Master clock square wave frequency, Hz
      
%Extracting data from the packs      
N=length(packs);
pcnt=zeros(N,1);
j1=zeros(N,1);
j2=zeros(N,1);
j3=zeros(N,1);
j4=zeros(N,1);

for i=1:N
  pcnt(i)=typecast(uint8(packs(i).data(43:46)),'uint32');
  j1(i)=double(typecast(uint8(packs(i).data(47:48)),'int16'))*ts;
  j2(i)=double(typecast(uint8(packs(i).data(49:50)),'int16'))*ts;
  j3(i)=double(typecast(uint8(packs(i).data(51:52)),'int16'))*ts;
  j4(i)=double(typecast(uint8(packs(i).data(53:54)),'int16'))*ts;
end
t = (pcnt-pcnt(1))/freq/2;  %Converting into time (2 edges per period)

%Plotting resutls
figure(1);
subplot(4,1,1)
plot(t,j1)
title('Channel 1 - Channel 0 (trigger)');
ylim([-500 500]);
ylabel(sprintf('Synchronization\n error, ns'))
xlabel('Time, ms')
xlim([min(t) max(t)]);
grid on
subplot(4,1,2)
plot(t,j2)
title('Channel 2 - Channel 0 (trigger)');
ylim([-500 500]);
ylabel(sprintf('Synchronization\n error, ns'))
xlabel('Time, ms')
xlim([min(t) max(t)]);
grid on
subplot(4,1,3)
plot(t,j3)
title('Channel 3 - Channel 0 (trigger)');
ylim([-500 500]);
ylabel(sprintf('Synchronization\n error, ns'))
xlabel('Time, ms')
xlim([min(t) max(t)]);
grid on
subplot(4,1,4)
plot(t,j4)
title('Channel 4 - Channel 0 (trigger)');
ylim([-4000 0]);
ylabel(sprintf('Synchronization\n error, ns'))
xlabel('Time, ms')
xlim([min(t) max(t)]);
grid on

figure(2)
subplot(2,1,1)
plot(t,j2,[min(t) max(t)],[min(j2) min(j2)],'--k','LineWidth',2,...
             [min(t) max(t)],[max(j2) max(j2)],'--k','LineWidth',2);
ylim([-300 200]);
xlim([min(t) max(t)]);
title('Channel 2 - Channel 0 (trigger)');
ylabel(sprintf('Synchronization\n error, ns'))
xlabel('Time, ms')
grid on
subplot(2,1,2)
plot(t,j3,[min(t) max(t)],[min(j3) min(j3)],'--k','LineWidth',2,...
             [min(t) max(t)],[max(j3) max(j3)],'--k','LineWidth',2);
ylim([-300 200]);
xlim([min(t) max(t)]);
title('Channel 3 - Channel 0 (trigger)');
ylabel(sprintf('Synchronization\n error, ns'))
xlabel('Time, ms')
grid on

fprintf('Channel 2 - Channel 0. Min phase shift: %i ns. Max phase shift: %i ns; Jitter. %i ns.\n', min(j2), max(j2), max(j2) - min(j2));
fprintf('Channel 3 - Channel 0. Min phase shift: %i ns. Max phase shift: %i ns; Jitter. %i ns.\n', min(j3), max(j3), max(j3) - min(j3));

%Add titles units and printf