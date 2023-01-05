
// packet class

`ifndef ETH_PACKET_C_SVH
   `define ETH_PACKET_C_SVH

class eth_packet_c;

  bit[47:0]  src_addr;
  bit[47:0]  dst_addr;
  byte pkt_data[$];
  bit [31:0]  pkt_crc;

  int pkt_size_bytes;
  byte pkt_full[$];

/*
  constraint addr_c {
    src_addr inside {'hABCD_1234_5678, 'hEE11_FF22_DD33};
    dst_addr inside {'hABCD_1234_5678, 'hEE11_FF22_DD33};
  }

  constraint pkt_data_c {
    pkt_data.size() == 1264;
  }
*/
  bit [47:0]  src_addr_copy;
  bit [47:0]  dst_addr_copy;
  bit [31:0]  pkt_crc_copy;
 function new();
 endfunction

 function void build_custom_random();
   int rand_num;
   rand_num = $urandom_range(0,3);
   case (rand_num)
     0: begin
       src_addr= 'hABCD_1234_5678; dst_addr='hEE11_FF22_DD33;
     end
     1: begin
       src_addr= 'h85B4_5286_1DF7; dst_addr='hE428_3B6D_73C2;
     end
     2: begin
       src_addr= 'h8DB7_B087_9A8B; dst_addr='hE098_C18C_5E98;
     end
     3: begin
       src_addr= 'h658D_C1F7_6BC6; dst_addr='h70C3_0985_A9F8;
     end
   endcase
   src_addr_copy = src_addr;
   dst_addr_copy = dst_addr;
   fill_pkt_data();
   append_data_packet();
 endfunction

 function void fill_pkt_data();
   for(int i=0; i < 1264;i++) begin
     pkt_data.push_back($urandom());
   end
 endfunction

 function bit[31:0] compute_crc();

   int rand_num;
   rand_num = $urandom_range(0,3);
   case (rand_num)
     0: begin
       return 'h5CA3_1C3D;
     end
     1: begin
       return 'hD3F8_57E2;
     end
     2: begin
       return 'h3AB9_04B5;
     end
     3: begin
       return 'h2B89_34A6;
     end
    endcase

   // return 'hABCD_AEFD;
 endfunction

 function void append_data_packet();
   pkt_crc =  compute_crc();
   pkt_crc_copy = pkt_crc;
   pkt_size_bytes = pkt_data.size() +6+6+4; //data byes + 6B src +6B dest + 4B CRC
   $display("packet :: entered append_data_packet");
   for(integer i=0; i < 6; i++) begin
     pkt_full.push_back( dst_addr_copy[47:40]);
     dst_addr_copy = dst_addr_copy << 8;
   end
   for(integer j=0; j < 6; j++) begin     
     pkt_full.push_back(src_addr_copy[47:40]);
     src_addr_copy = src_addr_copy << 8;
   end
   //Actual Data bytes
   for(integer k=0; k < 1264; k++) begin
       pkt_full.push_back(pkt_data[k]);
       //$display("packet ::append_data_packet pkt_data at k = %d = %x", k, pkt_data[k] );  
   end
   for(integer l=0; l < 4; l++) begin

       pkt_full.push_back(pkt_crc_copy[31:24]);
       pkt_crc_copy = pkt_crc_copy <<  8;
   end
   $display("packet ::append_data_packet pkt_full size  = %d", pkt_full.size());
 endfunction

 //return a string that prints all fields
 function string to_string();
   string msg;
   msg = $psprintf("dst_addr=%x, src_addr =%x, crc=%x",dst_addr,src_addr, pkt_crc);
   return msg;
 endfunction

 function bit compare_pkt(eth_packet_c pkt);
   if((this.dst_addr==pkt.src_addr) &&
     (this.src_addr==pkt.dst_addr) &&
     (this.pkt_crc==pkt.pkt_crc) &&
     is_data_match(this.pkt_data, pkt.pkt_data)) begin
      return 1'b1;
   end
      return 1'b0;
 endfunction

 function bit is_data_match(byte data1[], byte data2[]);
   return 1'b1;
 endfunction

endclass : eth_packet_c
`endif