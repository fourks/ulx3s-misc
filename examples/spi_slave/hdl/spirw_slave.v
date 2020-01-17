// SPI RW slave

// AUTHOR=EMARD
// LICENSE=BSD

// read with dummy byte which should be discarded

// write 00 <MSB_addr> <LSB_addr> <byte0> <byte1>
// read  01 <MSB_addr> <LSB_addr> <dummy_byte> <byte0> <byte1>

module spirw_slave
#(
  parameter C_sclk_capable_pin = 1'b0 //, // 0-sclk is generic pin, 1-sclk is clock capable pin
)
(
  input  wire clk, // faster than SPI clock
  input  wire sclk, mosi, csn, // SPI lines to be sniffed
  inout  wire miso, // 3-state line, active when csn=0
  // BRAM interface
  output wire rd, wr,
  output wire [15:0] addr,
  input  wire [8-1:0] data_in,
  output wire [8-1:0] data_out
);
  reg [16:0] R_raddr;
  //reg [8-1:0] R_MISO;
  //reg [8-1:0] R_MOSI;
  reg [8-1:0] R_byte;
  reg R_request_read;
  reg R_request_write;
  reg [5:0] R_bit_count;
  generate
    if(C_sclk_capable_pin)
    begin
      // sclk is clock capable pin
      always @(posedge sclk or posedge csn)
      begin
        if(csn)
        begin
          R_request_write <= 1'b0;
          R_bit_count <= 6'd23; // 24 bits = 3 bytes to read cmd/addr, then data
        end
        else // csn == 0
          begin
            R_byte <= { R_byte[8-2:0], mosi };
            if(R_bit_count[5] == 1'b0) // first 3 bytes
            begin
              R_raddr <= { R_raddr[15:0], mosi };
              R_bit_count <= R_bit_count - 1;
            end
            else // after first 3 bytes
            begin
              if(R_bit_count[3:0] == 4'd7) // first bit in new byte, increment address from 5th SPI byte on
                R_raddr[15:0] <= R_raddr[15:0] + 1;
              if(R_bit_count[2:0] == 3'd3)
                R_request_read <= 1'b1;
              if(R_bit_count[2:0] == 3'd0) // last bit in byte
              begin
                if(R_raddr[16])
                begin
                  R_request_read <= 1'b0;
                  R_byte <= data_in; // read
                end
                else
                  R_request_write <= 1'b1; // write
                R_bit_count[3] <= 1'b0; // allow to inc address from 5th SPI byte on
              end
              else
                R_request_write <= 1'b0;
              R_bit_count[2:0] <= R_bit_count[2:0] - 1;
            end // after 1st 3 bytes
          end // csn = 0, rising sclk edge
      end // always
    end // generate
    else // sclk is not CLK capable pin
    begin
      // sclk is generic pin
      // it needs clock synchronous edge detection
      reg R_mosi;
      reg [1:0] R_sclk;
      always @(posedge clk)
      begin
        R_sclk <= {R_sclk[0], sclk};
        R_mosi <= mosi;
      end
      always @(posedge clk)
      begin
        if(csn)
        begin
          R_request_write <= 1'b0;
          R_bit_count <= 6'd23; // 24 bits = 3 bytes to read cmd/addr, then data
        end
        else // csn == 0
        begin
          if(R_sclk == 2'b01) // rising edge
          begin
            R_byte <= { R_byte[8-2:0], R_mosi };
            if(R_bit_count[5] == 1'b0) // first 3 bytes
            begin
              R_raddr <= { R_raddr[15:0], R_mosi };
              R_bit_count <= R_bit_count - 1;
            end
            else // after first 3 bytes
            begin
              if(R_bit_count[3:0] == 4'd7) // first bit in new byte, increment address from 5th SPI byte on
                R_raddr[15:0] <= R_raddr[15:0] + 1;
              if(R_raddr[16])
              begin
                if(R_bit_count[2:0] == 3'd1)
                  R_request_read <= 1'b1;
              end
              if(R_bit_count[2:0] == 3'd0) // last bit in byte
              begin
                R_request_read <= 1'b0;
                if(R_raddr[16])
                  R_byte <= data_in; // read
                else
                  R_request_write <= 1'b1; // write
                R_bit_count[3] <= 1'b0; // allow to inc address from 5th SPI byte on
              end
              else
                R_request_write <= 1'b0;
              R_bit_count[2:0] <= R_bit_count[2:0] - 1;
            end // after 1st 3 bytes
          end // sclk rising edge
        end // csn=0
      end // always
    end // generate
  endgenerate
  assign rd   = R_request_read;
  assign wr   = R_request_write;
  assign addr = R_raddr[15:0];
  assign miso = csn ? 1'bz : R_byte[8-1];
  assign data_out = R_byte;
endmodule
