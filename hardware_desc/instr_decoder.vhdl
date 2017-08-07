library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity instr_decoder is
    port ( clk : in std_logic;
           instruction : in word_t;
           alu_op : out alu_op_t;
           flow_control : out flow_control_t;
           -- Selects which data is actually applied to the register inputs:
           data_src : out dsrc_t;
           immediate : out word_t;
           reg_dest, reg_src0, reg_src1 : out regnum_t;
           flags_we, mem_we : out std_logic
         );
end instr_decoder;

architecture arch of instr_decoder is
    signal instr_group : instrg_t;
    -- Helper variables:
    signal immediate_shift : integer range 0 to 15;
    signal immediate_sgn_ext : signed(WORDWIDTH-1 downto 0);
    signal mvcp : mvcp_t;
begin

    instr_group <= instruction(31 downto 27);
    
    -- The instruction set is designed to allow this:
    reg_dest <= to_integer(unsigned(instruction(4 downto 0)));
    -- Setting the source registers to any value shouldn't break anything
    reg_src0 <= to_integer(unsigned(instruction(9 downto 5)));
    reg_src1 <= to_integer(unsigned(instruction(14 downto 10)));
    -- The ALU should also behave sensibly on illegal opcodes
    alu_op <= alu_op_t(instruction(19 downto 15));
    -- The immediate generator is included in the instruction decoder:
    immediate_sgn_ext <= resize(signed(instruction(21 downto 5)), WORDWIDTH);
    immediate_shift <= to_integer(unsigned(instruction(25 downto 22)));
    immediate <= word_t(immediate_sgn_ext sll immediate_shift);

    -- At some point, we have to decide based on the instruction group:
    flow_control <= flow_control_t(instruction(8 downto 5))
                        when (instr_group = instrg_cond) else flowc_normal;

    -- For the different kinds of instructions, the data has to come from
    -- different sources:
    -- * ALU instructions: ALU output, that's easy
    -- * Load immediate instruction: Immediate output of this entity
    -- * Conditional jumps/skips: The data is discarded anyway, source
    --                            doesn't matter
    -- * Memory and copy instructions
    --  * mv: First ALU argument
    --  * ldm: Memory read port
    --  * stm: Discarded anyway, doesn't matter
    mvcp <= instruction(16 downto 15); -- Actual move/copy command
    data_src <= dsrc_immediate when (instr_group = instrg_ldi) else
                dsrc_arg0 when ((instr_group = instrg_cpy)
                                and (mvcp = mvcp_mv)) else
                dsrc_mem when ((instr_group = instrg_cpy)
                               and (mvcp = mvcp_ldm))
                else dsrc_ALU; -- seems like a sane default

    -- Only update flags if ALU operation is performed
    flags_we <= '1' when (instr_group = instrg_ALU) else '0';

    -- Only write memory on stm instruction:
    mem_we <= '1' when ((instr_group = instrg_cpy) and (mvcp = mvcp_stm)) else '0';

end arch;

