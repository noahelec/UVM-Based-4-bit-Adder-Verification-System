// Design Implementation
module add (
    input [3:0] a, b,
    output [4:0] sum
  );
  
    assign sum = a + b;
  
  endmodule
  
  ////////////////////////////////////////////////////////////
  // Interface Declaration
  interface add_if();
    logic [3:0] a;
    logic [3:0] b;
    logic [4:0] sum;
  endinterface
  