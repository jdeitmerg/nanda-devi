-- file regile.vhdl
--
-- Defines a set of registers:
--  * 16 general purpose registers r0 - r15
--  *  1 program counter
--  *  1 stack pointer
--  *  1 flags register
--
-- There are two asynchronous read and one synchronous write ports for
-- general purpose usage.
-- The value on the write port is written to the selected register (0 to 18)
-- on the rising edge of the clock input. Selecting the register 19 for
-- writing discards the data.
--
-- Additionally, there is an asynchronous read and synchronous write
-- port to the pc register. If the general purpose write port also has the
-- pc selected, it always takes precedence over the dedicated pc port.
--
-- Another read/write port combination is available for the flags register.
-- It is only written if the flags_we signal is high. Again the general
-- purpose port takes precedence over the dedicated port.

library ieee;
use ieee.std_logic_1164.all;
use work.common.all;

entity regfile is
    port ( clk : in std_logic;
           write_select : in regnum_t;
           write_data : in word_t;
           read_select0, read_select1 : in regnum_t;
           read_data0, read_data1 : out word_t;
           read_pc : out word_t;
           read_flags : out flags_t;
           write_pc : in word_t;
           write_flags : in flags_t;
           flags_we : in std_logic -- Write enable to flags register. Not
                                   -- needed for write_select and
                                   -- write_data.
         );
end regfile;

architecture arch of regfile is
    type regfile_t is array (18 downto 0) of word_t;
    signal registers : regfile_t := (others => (others => '0'));

begin
    read_data0 <= registers(read_select0)
                    when read_select0 <= reg_max else (others => '0');
    read_data1 <= registers(read_select1)
                    when read_select1 <= reg_max else (others => '0');
    read_pc    <= registers(reg_pc);
    read_flags <= flags_t(registers(reg_flags)(numflags-1 downto 0));
    
    process(clk)
    begin
        if rising_edge(clk) then
            if write_select <= reg_max then
                registers(write_select) <= write_data;
            end if;
            if write_select /= reg_pc then
                registers(reg_pc) <= write_pc;
            end if;
            if write_select /= reg_flags and flags_we = '1' then
                registers(reg_flags)(numflags-1 downto 0) <= write_flags;
            end if;
        end if;
    end process;
end arch;

