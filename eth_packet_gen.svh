//Packet generator class

`ifndef eth_packet_c
   `include "eth_packet.svh"
`endif
class eth_packet_gen_c;

  int num_pkts;
  mailbox mbx_out;

  function new (mailbox mbx);
    mbx_out =  mbx;
  endfunction

  //Method
  task run; 
    eth_packet_c pkt;
    num_pkts = 4; // $urandom_range(2,3);
    for (int i=0; i < num_pkts; i++) begin
      pkt = new();
      pkt.build_custom_random();
      mbx_out.put(pkt);

    end
    

    $display("packet_gen::run called");
    $display("packet as string = %s", pkt.to_string());

      
  endtask

endclass
