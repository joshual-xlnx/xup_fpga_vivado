//-----------------------------------------------------------------------------
//  
// MIT License
// Copyright (c) 2022 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// SOFTWARE.
//
//  Project  : Programmable Wave Generator
//  Module   : debouncer.v
//  Parent   : lb_ctl
//  Children : meta_harden.v
//
//  Description: 
//     Simple switch debouncer. Filters out any transition that lasts less
//     than FILTER clocks long
//
//  Parameters:
//     FILTER:     Number of consecutive clocks of the same data required for
//                 a switch in the output
//
//  Notes       : 
//
//  Multicycle and False Paths
//     None

`timescale 1ns/1ps


module debouncer (
  input            clk,          // Clock input
  input            rst,          // Active HIGH reset - synchronous to clk
  
  input            signal_in,    // Undebounced signal
  output           signal_out    // Debounced signal
);

//***************************************************************************
// Function definitions
//***************************************************************************

`include "clogb2.txt"

//***************************************************************************
// Parameter definitions
//***************************************************************************

  parameter 
    FILTER = 200_000_000;     // Number of clocks required for a switch

  localparam
    RELOAD = FILTER - 1,
    FILTER_WIDTH = clogb2(FILTER);
    

//***************************************************************************
// Reg declarations
//***************************************************************************

  reg                    signal_out_reg; // Current output
  reg [FILTER_WIDTH-1:0] cnt;            // Counter

//***************************************************************************
// Wire declarations
//***************************************************************************

  wire signal_in_clk; // Synchronized to clk

//***************************************************************************
// Code
//***************************************************************************

  // signal_in is not synchronous to clk - use a metastability hardener to
  // synchronize it
  meta_harden meta_harden_signal_in_i0 (
    .clk_dst       (clk),
    .rst_dst       (rst),
    .signal_src    (signal_in),
    .signal_dst    (signal_in_clk)
  );

  always @(posedge clk)
  begin
    if (rst)
    begin
      signal_out_reg <= signal_in_clk;
      cnt            <= RELOAD;
    end
    else // !rst
    begin
      if (signal_in_clk == signal_out_reg)
      begin
        // The input is not different then the current filtered value.
        // Reload the counter so that it is ready to count down in case
        // it is different during the next clock
        cnt <= RELOAD;
      end
      else if (cnt == 0) // The counter expired and we are still not equal
      begin
        // Take the new value, and reload the counter
        signal_out_reg <= signal_in_clk;
        cnt            <= RELOAD;
      end
      else // The counter is not 0
      begin
        cnt <= cnt - 1'b1; // decrement it
      end
    end // if rst
  end // always

  assign signal_out = signal_out_reg;

endmodule
