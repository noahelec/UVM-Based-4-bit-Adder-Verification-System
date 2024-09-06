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
```

### Interface Declaration
The add_if interface declares the signals used to connect the testbench to the adder module. It includes two 4-bit inputs (a, b) and a 5-bit output (sum).

**File**: `add.sv`
```verilog
module add (
  input [3:0] a, b,
  output [4:0] sum
);

  assign sum = a + b;

endmodule
```

**File**: `add.sv`
```verilog
interface add_if();
  logic [3:0] a;
  logic [3:0] b;
  logic [4:0] sum;
endinterface
```

## UVM Testbench
The UVM-based testbench is designed to rigorously validate the functionality of the 4-bit adder using the Universal Verification Methodology (UVM). It includes the following components:
### 1. Transaction
Defines the data that will be passed to the adder for verification.
```
class transaction extends uvm_sequence_item;
  rand bit [3:0] a;
  rand bit [3:0] b;
  bit [4:0] sum;

  function new(input string path = "transaction");
    super.new(path);
  endfunction
`uvm_object_utils_begin(transaction)
  `uvm_field_int(a, UVM_DEFAULT)
  `uvm_field_int(b, UVM_DEFAULT)
  `uvm_field_int(sum, UVM_DEFAULT)
`uvm_object_utils_end
endclass
```
### 2. Generator
```
class generator extends uvm_sequence #(transaction);
  transaction t;
  function new(input string path = "generator");
    super.new(path);
  endfunction

  virtual task body();
    t = transaction::type_id::create("t");
    repeat(10) begin
      start_item(t);
      t.randomize();
      `uvm_info("GEN",$sformatf("Data send to Driver a: %0d, b: %0d", t.a, t.b), UVM_NONE);
      finish_item(t);
    end
  endtask
endclass
```

### 3. Driver
```
class driver extends uvm_driver #(transaction);
  virtual add_if aif;
  transaction tc;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual add_if)::get(this, "", "aif", aif)) 
      `uvm_error("DRV", "Unable to access uvm_config_db");
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(tc);
      aif.a <= tc.a;
      aif.b <= tc.b;
      `uvm_info("DRV", $sformatf("Driving DUT: a=%0d, b=%0d", tc.a, tc.b), UVM_NONE);
      seq_item_port.item_done();
      #10;
    end
  endtask
endclass
```

### 4. Monitor
Observes the inputs and outputs of the adder and forwards the data to the scoreboard for comparison.
```
class monitor extends uvm_monitor;
  uvm_analysis_port #(transaction) send;
  virtual add_if aif;
  transaction t;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual add_if)::get(this, "", "aif", aif)) 
      `uvm_error("MON", "Unable to access uvm_config_db");
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      #10;
      t.a = aif.a;
      t.b = aif.b;
      t.sum = aif.sum;
      `uvm_info("MON", $sformatf("Monitor: a=%0d, b=%0d, sum=%0d", t.a, t.b, t.sum), UVM_NONE);
      send.write(t);
    end
  endtask
endclass
```

### 5. Scoreboard
Compares the actual output of the adder with the expected output and reports pass or fail.
```class scoreboard extends uvm_scoreboard;
  transaction tr;

  virtual function void write(transaction t);
    tr = t;
    `uvm_info("SCO", $sformatf("Scoreboard received: a=%0d, b=%0d, sum=%0d", tr.a, tr.b, tr.sum), UVM_NONE);
    if (tr.sum == tr.a + tr.b)
      `uvm_info("SCO", "Test Passed", UVM_NONE);
    else
      `uvm_info("SCO", "Test Failed", UVM_NONE);
  endfunction
endclass
```

### 6. Test
Runs the entire UVM environment by starting the generator and connecting the components.
```class test extends uvm_test;
  generator gen;
  env e;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    gen = generator::type_id::create("gen");
    e = env::type_id::create("e", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    gen.start(e.a.seqr);
    #50;
    phase.drop_objection(this);
  endtask
endclass
```

## Testbench Module
**File**: `uvm_adder_tb.sv`
```
module add_tb();
  add_if aif();
  add dut (.a(aif.a), .b(aif.b), .sum(aif.sum));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

  initial begin  
    uvm_config_db #(virtual add_if)::set(null, "uvm_test_top.e.a*", "aif", aif);
    run_test("test");
  end
endmodule
```

### Running the Project
https://www.edaplayground.com/x/drww
