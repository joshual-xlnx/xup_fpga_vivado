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
//  Module   : uart_tx.v
//  Parent   : wave_gen.v 
//  Children : uart_tx_ctl.v uart_baud_gen.v .v
//
//  Description: 
//     Top level of the UART transmitter.
//     Brings together the baudrate generator and the actual UART transmit
//     controller
//
//  Parameters:
//     BAUD_RATE : Baud rate - set to 57,600bps by default
//     CLOCK_RATE: Clock rate - set to 50MHz by default
//
//  Local Parameters:
//
//  Notes       : 
//
//  Multicycle and False Paths
//     The uart_baud_gen module generates a 1-in-N pulse (where N is
//     determined by the baud rate and the system clock frequency), which
//     enables all flip-flops in the uart_tx_ctl module. Therefore, all paths
//     within uart_tx_ctl are multicycle paths, as long as N > 2 (which it
//     will be for all reasonable combinations of Baud rate and system
//     frequency).
//

`timescale 1ns/1ps


module uart_tx (
  input        clk_tx,          // Clock input
  input        rst_clk_tx,      // Active HIGH reset - synchronous to clk_tx

  input        char_fifo_empty, // Empty signal from char FIFO (FWFT)
  input  [7:0] char_fifo_dout,  // Data from the char FIFO
  output       char_fifo_rd_en, // Pop signal to the char FIFO

  output       txd_tx           // The transmit serial signal
);


//***************************************************************************
// Parameter definitions
//***************************************************************************

  parameter BAUD_RATE    = 57_600;              // Baud rate

  parameter CLOCK_RATE   = 50_000_000;

//***************************************************************************
// Reg declarations
//***************************************************************************

//***************************************************************************
// Wire declarations
//***************************************************************************

  wire             baud_x16_en;  // 1-in-N enable for uart_rx_ctl FFs
  
//***************************************************************************
// Code
//***************************************************************************

  uart_baud_gen #
  ( .BAUD_RATE  (BAUD_RATE),
    .CLOCK_RATE (CLOCK_RATE)
  ) uart_baud_gen_tx_i0 (
    .clk         (clk_tx),
    .rst         (rst_clk_tx),
    .baud_x16_en (baud_x16_en)
  );

  uart_tx_ctl uart_tx_ctl_i0 (
    .clk_tx	        (clk_tx),          // Clock input
    .rst_clk_tx	        (rst_clk_tx),      // Active HIGH reset

    .baud_x16_en        (baud_x16_en),     // 16x oversample enable

    .char_fifo_empty	(char_fifo_empty), // Empty signal from char FIFO (FWFT)
    .char_fifo_dout	(char_fifo_dout),  // Data from the char FIFO
    .char_fifo_rd_en	(char_fifo_rd_en), // Pop signal to the char FIFO

    .txd_tx	        (txd_tx)           // The transmit serial signal
  );

endmodule
