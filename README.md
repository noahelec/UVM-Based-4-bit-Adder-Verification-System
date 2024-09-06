# UVM-Based 4-bit Adder Verification System

## Overview
This project implements a **UVM-based verification system** for a 4-bit adder. The design includes a simple 4-bit adder, along with a UVM testbench to validate its functionality. The UVM environment ensures a modular, reusable, and scalable framework for testing the adder under various conditions and input scenarios.

## Design Files

### Adder Design
The `add` module is a simple 4-bit adder that takes two 4-bit inputs (`a`, `b`) and outputs a 5-bit sum (`sum`).

**File**: `add.sv`
```verilog
module add (
  input [3:0] a, b,
  output [4:0] sum
);

  assign sum = a + b;

endmodule

Interface Declaration
The add_if interface declares the signals used to connect the testbench to the adder module. It includes two 4-bit inputs (a, b) and a 5-bit output (sum).

File: adder_design.sv

verilog
Copy code
interface add_if();
  logic [3:0] a;
  logic [3:0] b;
  logic [4:0] sum;
endinterface
