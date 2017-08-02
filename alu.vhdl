library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity alu is
    generic (
        WIDTH : positive := 32
    );
    port (
        arg0, arg1 : in word_t;
        op : in alu_op_t;
        result : out word_t
    );
end alu;

architecture arch of alu is
begin
    result <= word_t (unsigned(arg0) + unsigned(arg1))
                when (op = alu_uadd) else
              word_t (unsigned(arg0) - unsigned(arg1))
                when (op = alu_usub) else
              word_t (signed(arg0) + signed(arg1))
                when (op = alu_sadd) else
              word_t (signed(arg0) - signed(arg1))
                when (op = alu_ssub) else
              arg0 or arg1
                when (op = alu_or) else
              (others => '0');

end arch;

