
//interface 


interface eth_sw_if (
  input clk,
  input resetN,
  input [63:0] inData, //input data, start and end of packet pulses
  input inSop,
  input inEop,
  input vld,
  input [63:0] outData, //input Data and Sop and Eop packet pulses
  input outSop,
  input outEop,
  input outvld

);



// Default clocking block

default clocking  eth_mon_cb @(posedge clk);
  default input #0.8ps output #0.8ps;
  input clk;
  input resetN;
  input inData; //input data, start and end of packet pulses
  input inSop;
  input inEop;
  input vld;
  input outData; //input Data and Sop and Eop packet pulses
  input outSop;
  input outEop;
  input outvld;

endclocking: eth_mon_cb

//Modport for monitor

modport monitor_mp (
  clocking eth_mon_cb
);


// clocking block for output signals used by driver

clocking  eth_drv_cb @(posedge clk);
  default input #0.8ps output #0.8ps;
  input clk;
  input resetN;
  output inData; //input data, start and end of packet pulses
  output inSop;
  output inEop;

endclocking: eth_drv_cb

modport driver_mp (
  clocking eth_drv_cb
);

endinterface
