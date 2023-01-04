//--------------
//Packet checker class


`ifndef eth_packet_c
   `include "eth_packet.svh"
`endif
typedef eth_packet_c ;
class eth_packet_chk_c ;


  mailbox mbx_in[2];


  eth_packet_c exp_pkt_A_q[$];

  function new(mailbox mbx[2]);
    for(int i=0;i<2;i++) begin
      this.mbx_in[i] = mbx[i];
    end
  endfunction


  task run;
    $display("packet_chk::run() called");
      fork
         get_and_process_pkt(0);
         get_and_process_pkt(1);
      join_none
  endtask

  task get_and_process_pkt(int port);
    eth_packet_c pkt;
    $display("packet_chk::process_pkt on port=%0d called", port);
    forever begin
      mbx_in[port].get(pkt);
      $display("time=%0t packet_chk::got packet on port=%0d packet=%s",$time, port, pkt.to_string());
      if(port == 0) begin //input packets
        gen_exp_packet_q(pkt);
      end else begin //output packets
        chk_exp_packet_q(port, pkt);
      end
    end
  endtask

  function void gen_exp_packet_q(eth_packet_c pkt);
    exp_pkt_A_q.push_back(pkt);
   endfunction

   function void chk_exp_packet_q(int port, eth_packet_c pkt);
     eth_packet_c exp;
	   exp = exp_pkt_A_q.pop_front();
     if(pkt.compare_pkt(exp)) begin
       $display("Packet on port 1 (output A) matches");
     end else begin
       $display("Packet on port 1 (output A) mismatches");
     end
   endfunction

endclass
