/***********************************************************************
 * A SystemVerilog RTL model of an instruction regisgter
 *
 * An error can be injected into the design by invoking compilation with
 * the option:  +define+FORCE_LOAD_ERROR
 *
 **********************************************************************/



module instr_register(tb_ifc intf);
 // user-defined types are defined in instr_register_pkg.sv

timeunit 1ns/1ns;
import instr_register_pkg::*; 
  logic signed [63:0] result_t;
  instruction_t  iw_reg [0:31];  // an array of instruction_word structures

  // write to the register
  always@(posedge intf.clk, negedge intf.cb.reset_n)   // write into register
    if (!intf.cb.reset_n) begin
      foreach (iw_reg[i])
        iw_reg[i] = '{opc:ZERO,default:0};  // reset to all zeros
    end
    else if (intf.cb.load_en) begin
      case(intf.cb.opcode)
        ZERO: result_t = 0;
        PASSA: result_t = intf.cb.operand_a;
        PASSB: result_t = intf.cb.operand_b;
        ADD: result_t = intf.cb.operand_a + intf.cb.operand_b;
        SUB: result_t = intf.cb.operand_a - intf.cb.operand_b;
        MULT: result_t = intf.cb.operand_a*intf.cb.operand_b;
        DIV: result_t = intf.cb.operand_a / intf.cb.operand_b;
        MOD: result_t = intf.cb.operand_a % intf.cb.operand_b;
      endcase
      iw_reg[intf.cb.write_pointer] = '{intf.cb.opcode, intf.cb.operand_a, intf.cb.operand_b, result_t};
    end

  // read from the register
  always@(posedge intf.clk, negedge intf.cb.reset_n) begin
   intf.cb.instruction_word <= iw_reg[intf.cb.read_pointer];  // continuously read from register
  end
// compile with +define+FORCE_LOAD_ERROR to inject a functional bug for verification to catch
`ifdef FORCE_LOAD_ERROR
initial begin
  force intf.cb.operand_b = intf.cb.operand_a; // cause wrong value to be loaded into operand_b
end
`endif

endmodule: instr_register
