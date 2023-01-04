
module new_ethernet;
  wire [63:0] DATAOUT;
  reg clock, reset;
  reg [63:0] DATAIN;
  reg inSOP, inEOP, vld;
  wire outSOP, outEOP, outvld;
  
  
  eth_sw my_ethernet(clock, reset, DATAIN, inSOP, inEOP,vld, DATAOUT, outSOP, outEOP,outvld);
    
  //enabling the wave dump
  initial begin 
    $dumpfile("dump.vcd"); $dumpvars;
  end

 always 
  #5 clock = ~clock;
 
  initial
  begin
    clock = 0;
    inSOP = 0;
    inEOP = 0;
 
    DATAIN = 64'd0;
    reset = 1; vld =0; #3;
     reset = 0;
vld =1;
     #3; reset = 1;

    $display("Start testing");
  #5;
    inSOP = 1;
    DATAIN = $random;
    #10;
    inSOP = 0;
    DATAIN = $random;
    
    repeat(160)
      begin
      DATAIN = $random;
        $display("DATAIN %x ", DATAIN);
        $display("outEOP %b ", outEOP);
        $display("outSOP %b ", outSOP);
        $display("DATAOUT %x ", DATAOUT);

        #10;
      end
    
    inEOP = 1;
    DATAIN = $random;
    #5; inEOP = 0;
    #135; $finish;
  end
  

  
endmodule