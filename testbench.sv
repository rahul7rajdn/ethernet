//----------------------
//Top level module
//----------------------
`include "packet_tb_env.svh"
`include "eth_sw_if.svh"

import packet_tb_env_pkg::*; 

module packet_tb_top;

  reg clk;
  reg resetN;
  wire [63:0] inData; // input data, start and end of packet pulses
  wire inSop;
  wire inEop;
  reg vld;
  wire [63:0] outData; //output Data and Sop and Eop packet pulses
  wire outSop;
  wire outEop;
  wire outvld;

  //Instantiate DUT
  eth_sw eth_sw1(
  .clk(clk),
  .resetN(resetN),
  .inDataA(inData), 
  .inSopA(inSop),
  .inEopA(inEop),
  .vld(vld),
  .outDataA(outData),
  .outSopA(outSop),
  .outEopA(outEop),
  .outvld(outvld)
 );

  //Instantiate the interface
  eth_sw_if  eth_sw_if1(
  .clk(clk),
  .resetN(resetN),
  .inData(inData), 
  .inSop(inSop),
  .inEop(inEop),
  .vld(vld),
  .outData(outData),
  .outSop(outSop),
  .outEop(outEop),
  .outvld(outvld)
);

  //Instantiate top level env class
  packet_tb_env_c packet_tb_env;

  always begin
    #1.5ps clk = ~clk;
  end

  initial begin
    resetN=0;
    vld =0;
    clk=0;
    repeat (5) @(posedge clk);
    resetN=1;
    vld =1;

    packet_tb_env = new("Ethernet Project", eth_sw_if1);
    $display("Created Packet TB Env");
    fork
      begin
        packet_tb_env.run();
      end
    join
  end

  initial begin
    $dumpfile("test_pkt.vcd");
    $dumpvars(0,packet_tb_top);
  end

  
endmodule