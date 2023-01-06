//----------------
//Packet driver class
//----------------
`ifndef eth_packet_c
   `include "eth_packet.svh"
`endif
`timescale 1ps/1ps
class eth_packet_drv_c;

  virtual interface eth_sw_if  rtl_intf;
  mailbox mbx_input;

  function new (mailbox mbx, virtual interface eth_sw_if intf);
     mbx_input = mbx;
     this.rtl_intf = intf;
  endfunction


  task run;
    eth_packet_c pkt;
    $display("packet_drv::run");
    forever begin
      mbx_input.get(pkt);
    $display("packet_drv::Got packet = %s,Total Size =  %d", pkt.to_string(), pkt.pkt_size_bytes);
      drive_pkt(pkt);
    end
  endtask

  task drive_pkt(eth_packet_c pkt);
    //Drive signals as per protocol on that packet
    int count;
    int numDwords;
    bit[63:0] cur_dword;
    count=0;
    numDwords= pkt.pkt_size_bytes/8;
    $display("packet_drv::drive_pkt: numDwords=%0d ",numDwords);
    #1602;
    forever @(posedge rtl_intf.clk) begin
      rtl_intf.eth_drv_cb.inSop <=1'b0;
      rtl_intf.eth_drv_cb.inEop <=1'b0;
      cur_dword[63:56] = pkt.pkt_full[8*count];
      cur_dword[55:48] = pkt.pkt_full[8*count+1];
      cur_dword[47:40] = pkt.pkt_full[8*count+2];
      cur_dword[39:32] = pkt.pkt_full[8*count+3];
      cur_dword[31:24] = pkt.pkt_full[8*count+4];
      cur_dword[23:16] = pkt.pkt_full[8*count+5];
      cur_dword[15:8] = pkt.pkt_full[8*count+6];
      cur_dword[7:0] = pkt.pkt_full[8*count+7];
      
      if(count==0) begin
        rtl_intf.eth_drv_cb.inSop <=1'b1;
        rtl_intf.eth_drv_cb.inData <= cur_dword;
        count = count+1;
      end else if (count== numDwords-1) begin
        rtl_intf.eth_drv_cb.inEop <=1'b1;
        rtl_intf.eth_drv_cb.inData <= cur_dword;
        count = count+1;
      end else if (count== numDwords) begin
        count =0;
        break;
      end else begin
        rtl_intf.eth_drv_cb.inData <= cur_dword;
        count= count+1;
      end
      //$display("time=%t packet_drv::drive_pkt_port:count=%0d cur_dword=%h",$time,count,cur_dword);
      //$display("time=%t packet_drv::drive_pkt_port:count=%0d, rtl_intf.eth_drv_cb.inData ==== %x", $time,count, rtl_intf.eth_drv_cb.inData);
    end
  endtask



endclass
