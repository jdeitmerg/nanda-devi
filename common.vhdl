library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is
    -- General stuff: Width of architectures words
    constant WORDWIDTH : positive := 32;
    subtype word_t is std_logic_vector(WORDWIDTH-1 downto 0);

    -- Possible ALU operations. Enum is not an option, as these have to
    -- be known to the assembler.
    subtype alu_op_t is unsigned(4 downto 0);
    constant alu_add    : alu_op_t := "00000"; -- addition
    constant alu_sub    : alu_op_t := "00001"; -- substractionl
    constant alu_addc   : alu_op_t := "00010"; -- addition with carry
    constant alu_subc   : alu_op_t := "00011"; -- substraction with carry
    constant alu_or     : alu_op_t := "00100"; -- bitwise logical or
    constant alu_xor    : alu_op_t := "00101"; -- bitwise logical xor
    constant alu_and    : alu_op_t := "00110"; -- bitwise logical and
    constant alu_not    : alu_op_t := "00111"; -- bitwise logical not
    constant alu_sll    : alu_op_t := "01000"; -- shift logical left
    constant alu_slr    : alu_op_t := "01001"; -- shift logical right
    constant alu_tst    : alu_op_t := "01010"; -- test (only set flags)


    -- Indices of special registers in regfile
    constant reg_pc    : integer range 0 to 18 := 16;
    constant reg_sp    : integer range 0 to 18 := 17;
    constant reg_flags : integer range 0 to 18 := 18;

end common;
  
