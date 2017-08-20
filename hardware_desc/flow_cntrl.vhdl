-- This file is part of the Nanda Devi project.
-- Nanda Devi is a simple CPU architecture which emerged from learning
-- VHDL.
--
-- Copyright (c) 2017 Jonas Deitmerg
--
-- For licensing information, please refer to the LICENSE file.

-- file flow_cntrl.vhdl
--
-- Flow controller
-- Updates the program counter based on the current instruction and the
-- flags register.
--
-- If flag_inv is '1', skips if the flag specified by command is '0',
-- else if it's '1'.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity flow_cntrl is
    port ( flags      : in flags_t;
           pc_current : in word_t;
           fc_input   : in flow_control_t;
           pc_next    : out word_t
         );
end flow_cntrl;

architecture arch of flow_cntrl is
    -- Helper signals
    signal flag_c, flag_z, flag_n : std_logic;
begin
    -- Invert flags if necessary:
    flag_c <= flags(flagpos_c) xor fc_input.inv;
    flag_z <= flags(flagpos_z) xor fc_input.inv;
    flag_n <= flags(flagpos_n) xor fc_input.inv;

    pc_next <= word_t(unsigned(pc_current) + 12) when
                   -- Skip 2 instructions if condition is met:
                   (((fc_input.command = flowc_skipc) and (flag_c = '1')) or
                    ((fc_input.command = flowc_skipz) and (flag_z = '1')) or
                    ((fc_input.command = flowc_skipn) and (flag_n = '1')))
               -- Default: increment by one instruction
               else word_t(unsigned(pc_current) + 4);
end arch;

