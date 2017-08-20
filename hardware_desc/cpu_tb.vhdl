-- This file is part of the Nanda Devi project.
-- Nanda Devi is a simple CPU architecture which emerged from learning
-- VHDL.
--
-- Copyright (c) 2017 Jonas Deitmerg
--
-- For licensing information, please refer to the LICENSE file.

-- file cpu_tb.vhdl
--
-- Testbench for CPU
-- Simulates RAM and ROM, generates clock signal

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use STD.textio.all;
use work.common.all;

entity cpu_tb is

end cpu_tb;

architecture arch of cpu_tb is

    signal clk : std_logic;
    signal ram_addr, ram_read, ram_write : word_t;
    signal ram_we : std_logic;
    signal rom_addr, rom_data : word_t;
    signal rom_clk : std_logic;

    -- RAM and ROM:
    constant RAMSIZE : natural := 1024*4;
    constant ROMSIZE : natural := 1024*4;

    -- Memory mapped writing to stdout:
    constant STDOUT_ADDR : unsigned(WORDWIDTH-1 downto 0) := X"01000000";
    constant DEBUG0_ADDR : unsigned(WORDWIDTH-1 downto 0) := X"01000004";
    constant DEBUG1_ADDR : unsigned(WORDWIDTH-1 downto 0) := X"01000008";

    subtype byte_t is std_logic_vector(7 downto 0);
    type ram_t is array(0 to RAMSIZE-1) of byte_t;
    type rom_t is array(0 to ROMSIZE-1) of byte_t;


    impure function ReadROMFile(FileName : STRING) return rom_t is
      file FileHandle       : TEXT open READ_MODE is FileName;
      variable CurrentLine  : LINE;
      variable TempWord     : word_t;
      variable Result       : rom_t    := (others => (others => '0'));

    begin
      for i in 0 to (ROMSIZE/4) - 1 loop
        exit when endfile(FileHandle);

        readline(FileHandle, CurrentLine);
        hread(CurrentLine, TempWord);
        Result(4*i+0)    := TempWord( 7 downto  0);
        Result(4*i+1)    := TempWord(15 downto  8);
        Result(4*i+2)    := TempWord(23 downto 16);
        Result(4*i+3)    := TempWord(31 downto 24);
      end loop;

      return Result;
    end function;

    signal ram : ram_t;
    signal rom : rom_t := ReadROMFile("ROM.hex");

    -- Addresses cast to unsiged
    signal ram_addr_u : unsigned(WORDWIDTH-1 downto 0);
    signal rom_addr_u : unsigned(WORDWIDTH-1 downto 0);

    -- Addresses limited to maximum values
    signal ram_addr_lim_u : unsigned(WORDWIDTH-1 downto 0);

    signal prev_rom_addr : unsigned(WORDWIDTH-1 downto 0) := ('1' others => '0');

begin
    dut : entity work.cpu
        port map ( clk => clk,
                   ram_addr => ram_addr,
                   ram_read => ram_read,
                   ram_write => ram_write,
                   ram_we => ram_we,
                   rom_addr => rom_addr,
                   rom_read => rom_data,
                   rom_clk => rom_clk
                 );

        rom_addr_u <= unsigned(rom_addr);
        ram_addr_u <= unsigned(ram_addr);

        ram_addr_lim_u <= ram_addr_u when ram_addr_u <= (RAMSIZE-4)
                                     else (others => '0');

    -- Asynchronous reading of RAM:
    ram_read <= ram(to_integer(ram_addr_lim_u+3)) &
                ram(to_integer(ram_addr_lim_u+2)) &
                ram(to_integer(ram_addr_lim_u+1)) &
                ram(to_integer(ram_addr_lim_u+0));

    -- Synchronous reading of ROM:
    process(rom_clk)
    begin
        if rising_edge(rom_clk) then
            if rom_addr_u <= (ROMSIZE-4) then
                -- Comment this in for debugging
                -- very helpful on crashes!
                --report "ROM addr: " &
                --      integer'image(to_integer(rom_addr_u));
                rom_data <= rom(to_integer(rom_addr_u+3)) &
                            rom(to_integer(rom_addr_u+2)) &
                            rom(to_integer(rom_addr_u+1)) &
                            rom(to_integer(rom_addr_u+0));
            else
                rom_data <= x"10000210"; -- mv pc, pc; hang instruction
            end if;
        end if;
    end process;

    -- Synchronous writing of RAM:
    process(clk)
    begin
        if rising_edge(clk) and (ram_we = '1') then
            -- If writing outside of RAM area, that may
            -- be handled elsewhere. It may also not
            -- be handled at all.
            if ram_addr_u <= (RAMSIZE-4) then
                ram(to_integer(ram_addr_lim_u+3))
                    <= ram_write(31 downto 24);
                ram(to_integer(ram_addr_lim_u+2))
                    <= ram_write(23 downto 16);
                ram(to_integer(ram_addr_lim_u+1))
                    <= ram_write(15 downto  8);
                ram(to_integer(ram_addr_lim_u+0))
                    <= ram_write( 7 downto  0);
            end if;
        end if;
    end process;

    -- Clock simulation
    process
        variable clkcnt : integer := 0;
    begin
        -- Run simulation until pc doesn't change anymore
        -- ("hang instruction" mv pc, pc)
        while rom_addr_u /= prev_rom_addr loop
            prev_rom_addr <= rom_addr_u;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
            wait for 1 ns;
            clkcnt := clkcnt+1;
        end loop;
        report "Simulation ended after " & integer'image(clkcnt)
               & " cycles.";
        wait;
    end process;

    -- Memory mapped writing to stdout
    process(clk)
        -- byte to print:
        alias pbyte : byte_t is ram_write(7 downto 0);
        variable outstr : string(1 to 1);
    begin
        if rising_edge(clk)
            and (ram_we = '1')
            and (ram_addr_u = STDOUT_ADDR)
        then
            outstr(1) := character'val(to_integer(unsigned(pbyte)));
            write(output, outstr);
        end if;
        -- Debug output (print values by writing to RAM)
        if rising_edge(clk)
            and (ram_we = '1')
            and (ram_addr_u = DEBUG0_ADDR)
        then
            report "Debug 0: 0x" & to_hstring(unsigned(ram_write));
        end if;
        if rising_edge(clk)
            and (ram_we = '1')
            and (ram_addr_u = DEBUG1_ADDR)
        then
            report "Debug 1: 0x" & to_hstring(unsigned(ram_write));
        end if;

    end process;
end arch;

