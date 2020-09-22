yosys  -l synth.log -s project.scr
arachne-pnr  -d 1k -P tq144 -p ./pins.pcf project.blif -o project.asc
icetime project.asc -dhx1k -mit -r timing.log
icepack project.asc ws_logger_ice40.bit
