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
        result : out word_t;
        flags_in : in flags_t;
        flags_out : out flags_t
    );
end alu;

architecture arch of alu is
    -- To get the carry output, we need to add another bit to the first
    -- (left) argument. All other arguments will be extended to the same
    -- width automatically.
    subtype word_carry is unsigned(WORDWIDTH downto 0);
    signal arg0_ext : word_carry; -- first argument with a carry of 0
    signal res_ext  : word_carry; -- result and output carry
    -- For setting the carry to 0 where it wouldn't make any sense:
    signal carry_mask : word_carry :=
                        not unsigned('1' & resize(unsigned'("0"), WORDWIDTH));
    signal carry_in_cast : unsigned(0 downto 0);
    signal arg1_cast : unsigned(WORDWIDTH-1 downto 0);
begin
    -- Helper variables
    arg0_ext <= unsigned('0' & arg0);
    carry_in_cast(0) <= flags_in(flagpos_c);
    arg1_cast <= unsigned(arg1);
    -- Outputs
    result <= std_logic_vector(res_ext(WORDWIDTH-1 downto 0));
    flags_out(flagpos_c) <= res_ext(WORDWIDTH);
    flags_out(flagpos_n) <= res_ext(WORDWIDTH-1);
    flags_out(flagpos_z) <= '1' when res_ext(WORDWIDTH-1 downto 0) = 0
                                                                else '0';

    res_ext <=  arg0_ext + arg1_cast
                    when (op = alu_add) else
                arg0_ext - arg1_cast
                    when (op = alu_sub) else
                arg0_ext + arg1_cast + carry_in_cast
                    when (op = alu_addc) else
                arg0_ext - arg1_cast - carry_in_cast
                    when (op = alu_subc) else
                (arg0_ext or arg1_cast) and carry_mask
                    when (op = alu_or) else
                (arg0_ext xor arg1_cast) and carry_mask
                    when (op = alu_xor) else
                (arg0_ext and arg1_cast) and carry_mask
                    when (op = alu_and) else
                (not arg0_ext) and carry_mask
                    when (op = alu_not) else
                -- This nicely shifts into the carry bit.
                arg0_ext sll to_integer(arg1_cast)
                    when (op = alu_sll) else
                -- Put the carry on the right, then rotate everything to
                -- put it where it belongs.
                (unsigned(arg0 & '0') srl to_integer(arg1_cast)) ror 1
                    when (op = alu_slr) else
                (arg0_ext) and carry_mask
                    when (op = alu_tst) else
                (others => '0');

end arch;

