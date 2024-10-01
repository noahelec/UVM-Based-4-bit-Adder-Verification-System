
`timescale 1ns / 1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

// Define transaction class
class transaction extends uvm_sequence_item;
  rand bit [3:0] a;
  rand bit [3:0] b;
  bit [4:0] sum;

  function new(string name = "transaction");
    super.new(name);
  endfunction

  `uvm_object_utils_begin(transaction)
    `uvm_field_int(a, UVM_DEFAULT)
    `uvm_field_int(b, UVM_DEFAULT)
  `uvm_field_int(sum, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

// Generator class
class generator extends uvm_sequence #(transaction);
  `uvm_object_utils(generator)

  transaction t;
  integer i;

  function new(string name = "generator");
    super.new(name);
  endfunction

  virtual task body();
    t = transaction::type_id::create("t");
    repeat(10) begin
      start_item(t);
      t.randomize();
      `uvm_info("GEN", $sformatf("Sending to Driver: a=%0d, b=%0d", t.a, t.b), UVM_NONE);
      finish_item(t);
    end
  endtask
endclass

// Driver class
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)

  transaction tc;
  virtual add_if aif;

  function new(string name = "driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tc = transaction::type_id::create("tc");

    if (!uvm_config_db #(virtual add_if)::get(this, "", "aif", aif))
      `uvm_error("DRV", "Failed to access uvm_config_db");
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(tc);
      aif.a <= tc.a;
      aif.b <= tc.b;
      `uvm_info("DRV", $sformatf("DUT triggered with a=%0d, b=%0d", tc.a, tc.b), UVM_NONE);
      seq_item_port.item_done();
      #10;
    end
  endtask
endclass

// Monitor class
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)

  uvm_analysis_port #(transaction) send;

  function new(string name = "monitor", uvm_component parent = null);
    super.new(name, parent);
    send = new("send", this);
  endfunction

  transaction t;
  virtual add_if aif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");

    if (!uvm_config_db #(virtual add_if)::get(this, "", "aif", aif))
      `uvm_error("MON", "Failed to access uvm_config_db");
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      #10;
      t.a = aif.a;
      t.b = aif.b;
      t.sum = aif.sum;
      `uvm_info("MON", $sformatf("Data sent to Scoreboard: a=%0d, b=%0d, sum%0d", t.a, t.b, t.sum), UVM_NONE);
      send.write(t);
    end
  endtask
endclass

// Scoreboard class
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  uvm_analysis_imp #(transaction, scoreboard) recv;

  transaction tr;

  function new(string name = "scoreboard", uvm_component parent = null);
    super.new(name, parent);
    recv = new("recv", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
  endfunction

  virtual function void write(transaction t);
    tr = t;
    `uvm_info("SCO", $sformatf("Monitor received: a=%0d, b=%0d, sum=%0d", tr.a, tr.b, tr.sum), UVM_NONE);

    if (tr.sum == (tr.a + tr.b))
      `uvm_info("SCO", "Test Passed", UVM_NONE)
    else
      `uvm_info("SCO", "Test Failed", UVM_NONE);
  endfunction
endclass

// Agent class
class agent extends uvm_agent;
  `uvm_component_utils(agent)

  function new(string name = "AGENT", uvm_component parent);
    super.new(name, parent);
  endfunction

  monitor m;
  driver d;
  uvm_sequencer #(transaction) seqr;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m = monitor::type_id::create("m", this);
    d = driver::type_id::create("d", this);
    seqr = uvm_sequencer #(transaction)::type_id::create("seqr", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

// Environment class
class env extends uvm_env;
  `uvm_component_utils(env)

  function new(string name = "ENV", uvm_component parent);
    super.new(name, parent);
  endfunction

  scoreboard s;
  agent a;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    s = scoreboard::type_id::create("s", this);
    a = agent::type_id::create("a", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.recv);
  endfunction
endclass

// Test class
class test extends uvm_test;
  `uvm_component_utils(test)

  function new(string name = "TEST", uvm_component parent);
    super.new(name, parent);
  endfunction

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

// Module add_tb
module add_tb();

  add_if aif();

  add_comb dut(.a(aif.a), .b(aif.b), .sum(aif.sum));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

  initial begin
    uvm_config_db #(virtual add_if)::set(null, "uvm_test_top.e.a*", "aif", aif);
    run_test("test");
  end

endmodule
