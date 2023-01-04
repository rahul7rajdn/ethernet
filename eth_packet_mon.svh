//---------------------
// Monitor class
`ifndef eth_packet_c
   `include "eth_packet.svh"
`endif
class eth_packet_mon_c;

 //Virtual interface to sample signals
 virtual interface eth_sw_if  rtl_intf;
 mailbox mbx_out[2];

 //constructor
   function new(mailbox mbx[2], virtual interface eth_sw_if rtl_intf);
   this.mbx_out = mbx;
   this.rtl_intf = rtl_intf;
 endfunction

 task run;
   $display("packet_mon::run called");
   fork
     sample_port_input_pkt();
     sample_port_output_pkt();
   join
 endtask

 task sample_port_input_pkt();
   eth_packet_c pkt;
   int count;
   reg[15:0] msb_src;
   count=0;
   forever @(posedge rtl_intf.clk) begin
     if(rtl_intf.eth_mon_cb.inSop) begin
       $display("time=%t packet_mon::seeing Sop on PortA input",$time);
       pkt = new();
       count=1;
       pkt.dst_addr=rtl_intf.eth_mon_cb.inData[63:16];
       msb_src = rtl_intf.eth_mon_cb.inData[15:0];
       $display("time=%t packet_mon::sample_port_input_pkt , pkt.dst_addr=%h", $time, pkt.dst_addr);
     end else if (count==1) begin
       pkt.src_addr= { msb_src, rtl_intf.eth_mon_cb.inData[63:32] } ;
       $display("time=%t packet_mon::sample_port_input_pkt , pkt.src_addr=%h", $time, pkt.src_addr);
       count++;
     end else if (rtl_intf.eth_mon_cb.inEop) begin
       pkt.pkt_crc=rtl_intf.eth_mon_cb.inData;
       $display("time=%t packet_mon::sample_port_input_pkt , pkt.pkt_crc=%h", $time, pkt.pkt_crc);
       $display("time=%0t packet_mon: Saw packet on port input: pkt=%s",$time, pkt.to_string());
       mbx_out[0].put(pkt);
       count=0;
     end else if(count >0) begin
       pkt.pkt_data.push_back(rtl_intf.eth_mon_cb.inData);
       // $display("time=%0t packet_mon: count = %d,  rtl_intf.eth_mon_cb.inData ==== %x", $time,count,  rtl_intf.eth_mon_cb.inData);
       count++;
     end
   end
 endtask

 task sample_port_output_pkt();
   eth_packet_c pkt;
   int count;
   reg[15:0] msb_src;
   count=0;
   forever @(posedge rtl_intf.clk) begin
     if(rtl_intf.eth_mon_cb.outSop) begin
       $display("time=%t packet_mon::seeing Sop on Port output",$time);
       pkt = new();
       count=1;
       pkt.dst_addr=rtl_intf.eth_mon_cb.outData[63:16];
       msb_src = rtl_intf.eth_mon_cb.outData[15:0];
       $display("time=%t packet_mon::sample_port_output_pkt, pkt.dst_addr= %h", $time,pkt.dst_addr);
     end else if (count==1) begin
       pkt.src_addr= {msb_src, rtl_intf.eth_mon_cb.outData[63:32] } ;
       $display("time=%t packet_mon::sample_port_output_pkt, pkt.src_addr= %h", $time,pkt.src_addr);

       count++;
     end else if (rtl_intf.eth_mon_cb.outEop) begin
       pkt.pkt_crc=rtl_intf.eth_mon_cb.outData;
       $display("time=%t packet_mon::sample_port_output_pkt , pkt.pkt_crc=%h", $time, pkt.pkt_crc);
       $display("time=%0t packet_mon: Saw packet on port A output: pkt=%s",$time, pkt.to_string());
       mbx_out[1].put(pkt);
       count=0;
     end else if(count >0) begin
       pkt.pkt_data.push_back(rtl_intf.eth_mon_cb.outData);
       count++;
     end
   end
 endtask


endclass
