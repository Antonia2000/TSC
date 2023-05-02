/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
    // user-defined types are defined in instr_register_pkg.sv
  (tb_ifc.TEST tbintf);
 /* (input  logic        test_clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
  );
*/ 
  timeunit 1ns/1ns;
  import instr_register_pkg::*;
 
  parameter NUMBER_OF_TRANSACTION = 11;
  parameter randomcase = 0;
  int seed = 555;
  result_t exp_result;
  result_t result;
  int nr_error = 0;

  initial begin
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(    "***********************************************************");

    $display("\nReseting the instruction register..");
    tbintf.write_pointer  <= 5'h00;         // initialize write pointer
    tbintf.read_pointer   <= 5'h1F;         // initialize read pointer
    tbintf.load_en        <= 1'b0;          // initialize load control line
    tbintf.reset_n        <= 1'b0;          // assert reset_n (active low)
    repeat (2) @(posedge tbintf.test_clk) ;     // hold in reset for 2 clock cycles
    tbintf.reset_n        <= 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack..");
    @(posedge tbintf.test_clk) tbintf.load_en <= 1'b1;  // enable writing to register
    repeat (NUMBER_OF_TRANSACTION) begin
      @(posedge tbintf.test_clk) randomize_transaction;
      @(negedge tbintf.test_clk) print_transaction;
    end
    @(posedge tbintf.test_clk) tbintf.load_en <= 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written..");
    for (int i=0; i<NUMBER_OF_TRANSACTION; i++) begin
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
      
      //TODO read_pointer random 
      if(randomcase==0 || randomcase==2)
      @(posedge tbintf.test_clk) tbintf.read_pointer <= i;
      else if(randomcase==2 || randomcase==3)
      @(posedge tbintf) tbintf.read_pointer <= $unsigned($random)%32;
      
      @(negedge tbintf.test_clk) print_results;
      check_results();
    end

    
    
    @(posedge tbintf.test_clk) ;
     $display("\nErrors : %d", nr_error);
      if(nr_error)   $display("\n TEST FAILLED");
    else    $display("\n TEST PASSED");
    @(posedge tbintf.test_clk) ;
    $display("\n***********************************************************");
    $display(  "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(  "***********************************************************\n");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp = 0;//toate variabilele declarate de la oricate apeluri de functie, variabila static respectiva va pointa catre aceiasi zona
    tbintf.operand_a     <= $random(seed)%16;                 // between -15 and 15
    tbintf.operand_b     <= $unsigned($random)%16;            // between 0 and 15
    tbintf.opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
//TODO write pointer sa ia valori random intre 0 si 31
  if(randomcase== 0 || randomcase==1)
    tbintf.write_pointer <= temp++;
  else if(randomcase==2 || randomcase==3)
    tbintf.write_pointer <= $unsigned($random)%32; 
    
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", tbintf.write_pointer);
    $display("  opcode = %0d (%s)", tbintf.opcode, tbintf.opcode.name);
    $display("  operand_a = %0d",   tbintf.operand_a);
    $display("  operand_b = %0d\n", tbintf.operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", tbintf.read_pointer);
    $display("  opcode = %0d (%s)", tbintf.instruction_word.opc, tbintf.instruction_word.opc.name);
    $display("  operand_a = %0d",   tbintf.instruction_word.op_a);
    $display("  operand_b = %0d\n", tbintf.instruction_word.op_b);
    $display("  operand_result = %0d\n", tbintf.instruction_word.result);
  endfunction: print_results

  function void check_results();

      case(tbintf.instruction_word.opc) 
          ZERO  : exp_result = 'b0;
          PASSA : exp_result = tbintf.instruction_word.op_a;
          PASSB : exp_result = tbintf.instruction_word.op_b;
          ADD   : exp_result = tbintf.instruction_word.op_a + tbintf.instruction_word.op_b;
          SUB   : exp_result = tbintf.instruction_word.op_a - tbintf.instruction_word.op_b;
          MULT  : exp_result = tbintf.instruction_word.op_a * tbintf.instruction_word.op_b;
          DIV   : exp_result = tbintf.instruction_word.op_a / tbintf.instruction_word.op_b;
          MOD   : exp_result = tbintf.instruction_word.op_a % tbintf.instruction_word.op_b;
      endcase
    if(exp_result != tbintf.instruction_word.result) nr_error++;
  endfunction: check_results

endmodule: instr_register_test
