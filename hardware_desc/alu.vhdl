-- file alu.vhdl
--
-- This ALU provides only some basic operations, it cannot multiply
-- or divide.
-- In order to use the same instructions for signed in two's complement and
-- unsigned operands, the operands are extended by two bits. This is not
-- a textbook example of handling unsigned and signed numbers and their
-- flags, but it works nicely and can easily be implemented in VHDL.
-- To show how the flags can be read from the extension bits, let's have a
-- look at some two bit (who needs 32 bits anyways?) examples:
--
--    bit h0: extension by 0 on the left, carry of result
--   / bit h1: signed extension of operand
--   |/  bit h2: negative flag
--   || /
--   vv v
--   00|00 unsigned "0" / signed "0"
-- + 01|10 unsigned "2" / signed "-2"
--   ------------------
--   01|10 unsigned "2" / signed "-2"
--
-- ## Addition ##
--
-- Below is a table of all possible addition results. The operands
-- are extended as described above. For every result, the flags are
-- "c" for carry out, "u" for signed underflow, "o" for signed overflow.
--
--           | 0000 0/0 | 0001 1/1 | 0110 2/-2| 0111 3/-1
-- ----------|----------|----------|----------|----------
-- 0000 0/0  | 0000 --- | 0001 --- | 0110 --- | 0111 ---
-- 0001 1/1  | 0001 --- | 0010 --o | 0111 --- | 1000 c--
-- 0110 2/-2 | 0110 --- | 0111 --- | 1100 cu- | 1101 cu-
-- 0111 3/-1 | 0111 --- | 1000 c-- | 1101 cu- | 1110 c--
--
-- As you can see, the bits of the result have the following meaning:
--  * the negative bit works as expeced
--  * the carry flag indicates an unsigned overflow
--  * if h1=0 and h2=1, a signed overflow occured, the carry(h0)is 0
--  * if h1=1 and h2=0, a signed underflow occured, the carry(h0) is 1
-- In short: h1 xor h2 indicates an overflow, the carry indicates the
-- direction (underflow if carry=1, overflow if carry=0).
--
-- ## Substraction ##
--
-- The table for all substraction results (row - column):
--
--           | 0000 0/0 | 0001 1/1 | 0110 2/-2| 0111 3/-1
-- ----------|----------|----------|----------|----------
-- 0000 0/0  | 0000 --- | 1111 c-- | 1010 c-o | 1001 c--
-- 0001 1/1  | 0001 --- | 0000 --- | 1011 c-o | 1010 c-o
-- 0110 2/-2 | 0110 --- | 0101 -u- | 0000 --- | 1111 c--
-- 0111 3/-1 | 0111 --- | 0110 --- | 0001 --- | 0000 ---
--
-- Look at that symmetry!
-- As you can see, the bits of the result have the following meaning:
--  * the negative bit works as expeced
--  * the carry flag indicates an unsigned underflow
--  * if h1=0 and h2=1, a signed overflow occured, the carry(h0)is 1
--  * if h1=1 and h2=0, a signed underflow occured, the carry(h0) is 0
-- In short: h1 xor h2 indicates an overflow, the carry indicates the
-- direction (overflow if carry=1, underflow if carry=0).
--
-- For the "substract carry" instruction (that should only be used for
-- unsigned operands, we need to invert the carry before substraction.
--
-- This scheme also works for longer (32 bit) numbers.
--
-- NOTE: Logic operations set the following flags:
--        * Carry to 0 (except for shift operations)
--        * Negative if result is (signed) negative.
--        * Zero flag if result is zero.
--        * Overflow flag to an undefined value.

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
    -- Extended arguments and result, as described above
    subtype word_ext_t is signed(WORDWIDTH+1 downto 0);
    signal arg0_ext : word_ext_t;
    signal arg1_ext : word_ext_t;
    signal res_ext  : word_ext_t;

    signal carry_in_cast : signed(0 downto 0);
    signal arg1_shift : integer range 0 to 31;
    -- For masking out the carry bit:
    signal carry_mask : word_ext_t := ('0' others => '1');
begin
    -- Helper variables
    arg0_ext <= '0' & resize(signed(arg0), WORDWIDTH+1);
    arg1_ext <= '0' & resize(signed(arg1), WORDWIDTH+1);
    carry_in_cast(0) <= flags_in(flagpos_c);
    -- Use only lowest 5 bits as argument for shift operations
    arg1_shift <= to_integer(unsigned(arg1(4 downto 0)));
    -- Outputs
    result <= std_logic_vector(res_ext(WORDWIDTH-1 downto 0));
    flags_out(flagpos_c) <= res_ext(WORDWIDTH+1);
    flags_out(flagpos_n) <= res_ext(WORDWIDTH-1);
    flags_out(flagpos_z) <= '1' when res_ext(WORDWIDTH-1 downto 0) = 0
                                                                else '0';
    flags_out(flagpos_o) <= res_ext(WORDWIDTH) xor res_ext(WORDWIDTH-1);

    res_ext <=  arg0_ext + arg1_ext
                    when (op = alu_add) else
                arg0_ext - arg1_ext
                    when (op = alu_sub) else
                arg0_ext + arg1_shift + carry_in_cast
                    when (op = alu_addc) else
                arg0_ext - arg1_shift + '1' - carry_in_cast
                    when (op = alu_subc) else
                arg0_ext or arg1_ext
                    when (op = alu_or) else
                arg0_ext xor arg1_ext
                    when (op = alu_xor) else
                arg0_ext and arg1_ext
                    when (op = alu_and) else
                not arg0_ext
                    when (op = alu_not) else
                -- For a left shift, bit h1 (see above) is in the way.
                -- Resizing as signed value copies the carry from h1 to the
                -- correct position.
                resize(signed('0' & arg0) sll arg1_shift, WORDWIDTH+2)
                    when (op = alu_sll) else
                -- Put the carry on the right, then rotate everything to
                -- put it where it belongs.
                (word_ext_t('0' & arg0 & '0') srl arg1_shift) ror 1
                --arg0_ext srl arg1_shift
                    when (op = alu_slr) else
                arg0_ext -- carry and overflow are set to 0
                    when (op = alu_tst) else
                (others => '0');
end arch;

