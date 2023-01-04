
//Package for Top level env class

package packet_tb_env_pkg;

`include "eth_packet_gen.svh"
`include "eth_packet_drv.svh"
`include "eth_packet_mon.svh"
`include "eth_packet_chk.svh"

//Top level env class
class packet_tb_env_c;

  //A name for the env
  string env_name;

  //packet generator object
  eth_packet_gen_c packet_gen;

  //Packet driver
  eth_packet_drv_c packet_driver;

  //Packet Monitor - monitors all ports 
  eth_packet_mon_c packet_mon;

  //Packet checker object
  eth_packet_chk_c packet_checker;
  // mailbox gen to driver
  mailbox mbx_gen_drv;
  //Mail boxes from monitor to checker
  mailbox mbx_mon_chk[2];
  //Virtual interface
  virtual interface eth_sw_if  rtl_intf;

  //Constructor
  function new(string name , virtual interface eth_sw_if intf);
    this.env_name = name;
    this.rtl_intf = intf;

    mbx_gen_drv =new();
    packet_gen = new(mbx_gen_drv);
    packet_driver = new(mbx_gen_drv,intf);

    for(int i=0; i < 2; i++) begin
      mbx_mon_chk[i] = new();
      $display("Create mailbox =%0d for mon-check",i);
    end
    packet_mon = new (mbx_mon_chk,intf);

    packet_checker = new(mbx_mon_chk);
  endfunction

  task run();
    $display("packet_tb_env::run() called");
    fork 
      packet_gen.run();
      packet_driver.run();
      packet_mon.run();
      packet_checker.run();
    join
  endtask

endclass : packet_tb_env_c

endpackage: packet_tb_env_pkg
