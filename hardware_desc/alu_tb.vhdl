-- This file is part of the Nanda Devi project.
-- Nanda Devi is a simple CPU architecture which emerged from learning
-- VHDL.
--
-- Copyright (c) 2017 Jonas Deitmerg
--
-- For licensing information, please refer to the LICENSE file.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity alu_tb is
    -- Testbench has no ports
end alu_tb;

architecture arch of alu_tb is
    constant f_all : flags_t := X"f";
    constant f_io : flags_t := X"7"; -- ignore overflow flag
    type pattern_t is record
            -- inputs:
            arg0, arg1 : word_t;
            cmd : alu_op_t;
            flags_in : flags_t;
            --outputs:
            result : word_t;
            flags_out : flags_t;
            flags_mask : flags_t; -- which flags to check
        end record;
        type pattern_array is array (natural range <>) of pattern_t;
        constant patterns : pattern_array :=
    -- arg0,       arg1,        cmd, flags_in, result, flags_mask, flags
    (
     -- Addition
     (X"00000001", X"00000001", alu_add, X"0", X"00000002", f_all, X"0"), -- 0
     (X"ffffffff", X"00000002", alu_add, X"0", X"00000001", f_all, X"1"), -- 1
     -- Substraction
     (X"0000000a", X"00000005", alu_sub, X"0", X"00000005", f_all, X"0"), -- 2
     (X"00000001", X"00000002", alu_sub, X"0", X"ffffffff", f_all, X"1"), -- 3
     -- Logical or (and negative flag)
     (X"aaaa0000", X"00003333", alu_or, X"0", X"aaaa3333", f_all, X"4"),  -- 4
     -- Logical not (and zero flag)
     (X"ffffffff", X"00000000", alu_not, X"0", X"00000000", f_all, X"2"), -- 5
     -- Logical shift left
     (X"a000000f", X"00000008", alu_sll, X"0", X"00000f00", f_io, X"0"), -- 6
     (X"a000000f", X"00000003", alu_sll, X"0", X"00000078", f_io, X"1"), -- 7
     (X"00000001", X"00000002", alu_sll, X"0", X"00000004", f_io, X"0"), -- 8
     -- Logical shift right
     (X"a000000f", X"00000008", alu_slr, X"0", X"00a00000", f_io, X"0"), -- 9
     (X"a000000f", X"00000001", alu_slr, X"0", X"50000007", f_io, X"1") -- 10
    );

    signal testpattern: pattern_t;
    signal flags_out, flags_masked, flags_masked_test : flags_t;
    signal result : word_t;
begin
    dut : entity work.alu
        port map ( arg0 => testpattern.arg0,
                   arg1 => testpattern.arg1,
                   op => testpattern.cmd,
                   result => result,
                   flags_in => testpattern.flags_in,
                   flags_out => flags_out
                 );
    -- Value masked flags should have:
    flags_masked_test <= testpattern.flags_out and testpattern.flags_mask;
    -- Value masked flags actually have:
    flags_masked <= flags_out and testpattern.flags_mask;

    process
            begin
        for i in patterns'range loop
            testpattern <= patterns(i);
            wait for 1 ns;
            report "Running testpattern " & natural'image(i) severity note;
            assert result = testpattern.result
                report "ALU: Wrong result on 0x" &
                       to_hstring(unsigned(testpattern.arg0)) &
                       " op " & integer'image(to_integer(testpattern.cmd)) &
                       " 0x" & to_hstring(unsigned(testpattern.arg1)) &
                       " = 0x" & to_hstring(unsigned(testpattern.result)) &
                       " not 0x" & to_hstring(unsigned(result)) severity error;
            assert flags_masked = flags_masked_test
                report "ALU: Wrong output flags: 0x" &
                       to_hstring(unsigned(flags_masked)) severity error;
        end loop;
        report "All ALU tests done." severity note;
        wait;
    end process;

end arch;

