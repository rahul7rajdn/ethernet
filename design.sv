

// Code your design here

module fifo #(parameter FIFO_DEPTH = 5, parameter FIFO_WIDTH = 66 ) (
  clk, 
  resetN, 
  write_en, 
  read_en, 
  data_in, 
  data_out, 
  empty, 
  full,
  ram
); 

  input clk; 
  input resetN; 
  input write_en; 
  input read_en; 
  input  [FIFO_WIDTH-1:0] data_in; 
  output [FIFO_WIDTH-1:0] data_out; 
  output empty; 
  output full; 
  output [FIFO_WIDTH-1:0] ram [0:FIFO_DEPTH-1]; 

  wire clk; 
  wire write_en; 
  wire read_en; 
  wire [FIFO_WIDTH-1:0] data_in; 
  reg [FIFO_WIDTH-1:0] data_out; 
  wire empty; 
  wire full;
  reg [FIFO_WIDTH-1:0] ram [0:FIFO_DEPTH-1]; 
  reg tmp_empty; 
  reg tmp_full; 

  integer write_ptr; 
  integer read_ptr;
  integer new_count; 
bit new_flag;

  always@(negedge resetN)  begin
    data_out = 0;
    tmp_empty = 1'b1; 
    tmp_full = 1'b0; 
    write_ptr = 0; 
    read_ptr = 0;
    new_flag=0;
    new_count =0;
    for(integer j =0; j< FIFO_DEPTH; j++)begin
       ram[j] =0;
    end
  end 

  assign empty = tmp_empty; 
  assign full = tmp_full; 

  always @(posedge clk) begin 
    if ((write_en == 1'b1) && (tmp_full == 1'b0)) begin 
      ram[write_ptr] = data_in;
      //$display("time ==== %d ns: write_ptr = %d, ram[write_ptr] = %x ", $time, write_ptr, ram[write_ptr] );
      tmp_empty <= 1'b0; 
      write_ptr = (write_ptr + 1) % FIFO_DEPTH; 
      if ( read_ptr == write_ptr ) begin 
        tmp_full <= 1'b1; 
      end


    end 
    if ((read_en == 1'b1) && (tmp_empty == 1'b0)) begin 
      data_out = ram[read_ptr];
      //$display("time ^^^^^^^^^ %d ns: read_ptr = %d, ram[read_ptr] = %x ", $time, read_ptr, ram[read_ptr] );
      tmp_full <= 1'b0; 
      read_ptr = (read_ptr + 1) % FIFO_DEPTH; 
      if ( read_ptr == write_ptr ) begin 
        tmp_empty <= 1'b1; 
      end

      if(ram[read_ptr][65] == 1) begin
        for(integer i=0; i< FIFO_DEPTH; i++) begin
          ram[(i+2)%FIFO_DEPTH] <=0;
        end
      end

/*

      if(ram[read_ptr][64] == 1) begin
        new_flag =0;
      end
      if(new_flag) begin
        ram[new_count] =0;
        new_count = (new_count + 1) % FIFO_DEPTH;  
      end


      if(ram[read_ptr][65] == 1) begin
        new_flag =1;
        new_count = read_ptr;
      end
 */

    end 
  end 

endmodule //fifo 

module eth_rcv_fsm #(parameter FIFO_DEPTH = 5 ) (
  input clk,
  input resetN,
  input [63:0] inData, 
  input inSop,
  input inEop,
  input vld,
  output reg outWrEn,
  output reg [65:0] outData  //65:0 data and bit 64 indicating start and bit 65 indicating end

);



reg[2:0] nState;
reg[2:0] pState;

parameter IDLE = 3'b000;
parameter DEST_ADDR_RCVD = 3'b001;
parameter DATA_RCV = 3'b010;
parameter DONE = 3'b011;

reg[47:0] dest_addr;
reg[47:0] src_addr;

//compute next state
  always @(pState or inSop or vld or inEop or inData ) begin
  case(pState) 
    IDLE: begin
      if(inSop ==1 && vld) begin
        nState = DEST_ADDR_RCVD;
      end else begin
        nState = IDLE;
      end
    end
    DEST_ADDR_RCVD: begin
      nState=DATA_RCV;
    end
    DATA_RCV: begin
      if(inEop && vld) begin //last dword -> CRC
        nState = DONE;
      end else begin
        nState = DATA_RCV;
      end
    end
    DONE: begin
        nState = IDLE;
    end
  endcase
end

//assign next state to present state on clk
always @(posedge clk) begin
  if(!resetN || !vld)
    pState <= IDLE;
  else begin
    pState <= nState;
  end
  
    
end
  
always @(posedge clk) begin
  if(!resetN || !vld) begin
    outWrEn =1'b0;
  end else if(nState != IDLE) begin
    outWrEn =1'b1;
    outData = {inEop, inSop, inData};
  end else begin
    outWrEn =1'b0;
  end
end


endmodule



//Ethernet Send FSM

module eth_send_fsm #(parameter FIFO_DEPTH = 5 )(input clk,
  input resetN,
  input [65:0] inData[0:FIFO_DEPTH-1],
  output reg outSop,
  output reg outEop,
  output reg outRdEn,
  output reg [63:0] outData,
  output reg outvld
);

reg[2:0] nState;
reg[2:0] pState;

parameter IDLE = 3'b000;
parameter DEST_ADDR_RCVD = 3'b001;
parameter DATA_RCV = 3'b010;
parameter DONE = 3'b011;

reg[47:0] dest_addr;
reg[47:0] src_addr;

integer read_ptr, read_ptr2;

  reg [65:0]inData_d[0:FIFO_DEPTH-1];
  reg[47:0] swap_var;  
  bit my_flag;
integer i =0;
//compute next state
  always @(pState or inData[0] or inData[1] or inData[2]  ) begin
  case(pState) 
    IDLE: begin
      // $display("%d ns inData[read_ptr] == %x", $time, inData[read_ptr]);
      // $display("read_ptr = %d", read_ptr);
      
      if(inData[read_ptr][64] == 1) begin
        nState = DEST_ADDR_RCVD;
        read_ptr = (read_ptr + 1) % FIFO_DEPTH;
        outvld =1;
      end else begin
        nState = IDLE;
      end
    end
    DEST_ADDR_RCVD: begin
      // $display("%d ns inData[read_ptr] === %x", $time, inData[read_ptr]);
      // $display("read_ptr = %d", read_ptr);
      nState=DATA_RCV;
      read_ptr = (read_ptr + 1) % FIFO_DEPTH;
    end
    DATA_RCV: begin
      // $display("%d ns inData[read_ptr] ==== %x", $time, inData[read_ptr]);
      // $display("read_ptr = %d", read_ptr);
      if(inData[read_ptr][65] == 1) begin //last dword -> CRC
        nState = DONE;
        outvld =0;
      end else begin
        nState = DATA_RCV;
      end
      read_ptr = (read_ptr + 1) % FIFO_DEPTH;

    end
    DONE: begin
        nState = IDLE;
    end
  endcase
end

//assign next state to present state on clk
always @(posedge clk) begin
  if(resetN==0) begin
    read_ptr = 0;
    read_ptr2 = 0;
    outRdEn = 0;
    pState = IDLE;
    outvld =0;
  end else begin
    pState <= nState;
    // read_ptr = (read_ptr + 1) % FIFO_DEPTH;
  end
end
  
always @(posedge clk) begin
  if(resetN==0) begin
    inData_d[0] <= 0;
    inData_d[1] <= 0;
    inData_d[2] <= 0;
    inData_d[3] <= 0;
    outvld =0;
  end else begin
// $display(" [%d ns] : i = %d, inData[i] = %x, inData_d[i] = %x",$time, i,  inData[i], inData_d[i]);
    inData_d[i] <= inData[i];
    i = (i+1) % FIFO_DEPTH;
/*
    for(integer i =0; i< FIFO_DEPTH; i=i+1)
      begin
        $display(" [%d ns] : i = %d, inData[i] = %x, inData_d[i] = %x",$time, i,  inData[i], inData_d[i]);
        $display(" ------------- read_ptr2 = %d, my_flag = %b ", read_ptr2, my_flag);
        inData_d[i] <= inData[i];
      end
*/    
  end
end
  

always @(posedge clk) begin
  if(resetN==0) begin
    outRdEn <=0;
    outvld <=0;
    outEop <=0;
    outSop <=0;
    outRdEn <=0;
  end else if(pState == DATA_RCV) begin // (nState == DATA_RCV | nState == DEST_ADDR_RCVD ) begin
     my_flag = 0;
    if(inData_d[read_ptr2][64] == 1) begin
      $display("inData_d[read_ptr2] = %x", inData_d[read_ptr2]);
      $display("inData_d[read_ptr2 + 1] = %x", inData_d[((read_ptr2 + 1)  % FIFO_DEPTH)]);
      
      swap_var = { inData_d[read_ptr2][15:0], inData_d[((read_ptr2 + 1)  % FIFO_DEPTH)][63:32]};
      { inData_d[read_ptr2][15:0], inData_d[((read_ptr2 + 1)  % FIFO_DEPTH)][63:32]} = inData_d[read_ptr2][63:16];
      inData_d[read_ptr2][63:16] = swap_var;

      my_flag =1;
      /*
      { inData_d[read_ptr2][15:0], inData_d[read_ptr2 + 1][63:32]} <= inData_d[read_ptr2][63:16];
      inData_d[read_ptr2][63:16] <= { inData_d[read_ptr2][15:0], inData_d[read_ptr2 + 1][63:32]};
*/ 
     $display("AFTER SWAP, \n inData_d[read_ptr2] = %x", inData_d[read_ptr2]);
      $display("inData_d[read_ptr2 + 1] = %x", inData_d[((read_ptr2 + 1)  % FIFO_DEPTH)]);

    end

    outRdEn <=1'b1;
    outEop <= inData_d[read_ptr2][65];
    outSop <= inData_d[read_ptr2][64];
    outData <= inData_d[read_ptr2][63:0];
    read_ptr2 <= (read_ptr2 + 1) % FIFO_DEPTH ;
    
    if(inData_d[read_ptr2][64]) begin
      outvld =1;
    end else begin
      outvld <= outEop ? 0 : outvld;
    end
  end else begin
    outRdEn =1'b0;
  end
end

endmodule : eth_send_fsm


//-------------------------
// DUT for testing an ethernet frame
//-------------------------

module eth_sw(
  input clk,
  input resetN,
  input [63:0] inDataA,
  input inSopA,
  input inEopA,
  input vld,
  output reg [63:0] outDataA, //output Data and Sop and Eop packet pulses
  output reg outSopA,
  output reg outEopA,
  output outvld
);


wire fifo_wr_en;
wire[65:0] fifo_wr_data;
wire[65:0] fifo_rddata;
wire fifo_empty;
wire fifo_full;
reg fifo_rd_en;
reg [6:0]counter;

  reg [65:0]fifo_queue[0:4];
  
  
  fifo #(.FIFO_DEPTH(5), .FIFO_WIDTH(66)) inA_queue(
  .clk(clk),
  .resetN(resetN),
  .write_en(fifo_wr_en),
  .read_en(fifo_rd_en),
  .data_in(fifo_wr_data),
  .data_out(fifo_rddata),
  .empty(fifo_empty),
  .full(fifo_full),
  .ram(fifo_queue)
);

eth_rcv_fsm #(.FIFO_DEPTH(5)) portA_rcv_fsm(
  .clk(clk),
  .resetN(resetN),
  .inData(inDataA),
  .inSop(inSopA),
  .inEop(inEopA),
  .vld(vld),
  .outWrEn(fifo_wr_en),
  .outData(fifo_wr_data)
);

eth_send_fsm #(.FIFO_DEPTH(5)) portA_send_fsm(
  .clk(clk),
  .resetN(resetN),
  .inData(fifo_queue),
  .outSop(outSopA),
  .outEop(outEopA),
  .outRdEn(fifo_rd_en),
  .outData(outDataA),
  .outvld(outvld)
);
    
  
  
endmodule : eth_sw




