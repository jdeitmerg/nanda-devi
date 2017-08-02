library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is
    constant WORDWIDTH : positive := 32;
    subtype word_t is std_logic_vector(WORDWIDTH-1 downto 0);

    -- Possible ALU operations. Enum is not an option, as these have to
    -- be known to the assembler.
    subtype alu_op_t is unsigned(3 downto 0);
    constant alu_uadd   : alu_op_t := X"0"; -- unsigned addition
    constant alu_usub   : alu_op_t := X"1"; -- unsigned substractionl
    constant alu_sadd   : alu_op_t := X"2"; -- signed addition
    constant alu_ssub   : alu_op_t := X"3"; -- signed substraction
    constant alu_or     : alu_op_t := X"4"; -- bitwise logical or

end common;
  
