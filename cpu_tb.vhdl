-- file cpu_tb.vhdl
--
-- Testbench for CPU
-- Simulates RAM and ROM, generates clock signal

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity cpu_tb is

end cpu_tb;

architecture arch of cpu_tb is
    constant RAMSIZE : natural := 1024*4;
    constant ROMSIZE : natural := 1024*4;

    signal clk : std_logic;
    signal ram_addr, ram_read, ram_write : word_t;
    signal ram_we : std_logic;
    signal rom_addr, rom_data : word_t;
    signal rom_clk : std_logic;


    -- RAM and ROM:
    subtype byte_t is std_logic_vector(7 downto 0);
    type ram_t is array(0 to RAMSIZE-1) of byte_t;
    type rom_t is array(0 to ROMSIZE-1) of byte_t;
    signal ram : ram_t;
    signal rom : rom_t;

    signal ram_addr_u : unsigned(WORDWIDTH-1 downto 0);
    signal rom_addr_u : unsigned(WORDWIDTH-1 downto 0);

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

    -- Asynchronous reading of RAM:
    ram_read <= ram(to_integer(ram_addr_u+3)) &
                ram(to_integer(ram_addr_u+2)) &
                ram(to_integer(ram_addr_u+1)) &
                ram(to_integer(ram_addr_u+0));

    -- Synchronous reading of ROM:
    process(rom_clk)
    begin
        if rising_edge(rom_clk) then
            --rom_data <= rom(to_integer(rom_addr_u+3)) &
            --            rom(to_integer(rom_addr_u+2)) &
            --            rom(to_integer(rom_addr_u+1)) &
            --            rom(to_integer(rom_addr_u+0));
            rom_data <= "00100000000000000000000000010011"; -- NOP for now
        end if;
    end process;

    -- Synchronous writing of RAM:
    process(clk)
    begin
        if rising_edge(clk) and (ram_we = '1') then
            ram(to_integer(ram_addr_u+3)) <= ram_write(31 downto 24);
            ram(to_integer(ram_addr_u+2)) <= ram_write(23 downto 16);
            ram(to_integer(ram_addr_u+1)) <= ram_write(15 downto  8);
            ram(to_integer(ram_addr_u+0)) <= ram_write( 7 downto  0);
        end if;
    end process;

    -- Clock simulation
    process
    begin
        for i in 0 to 7 loop
            clk <= '1';
            wait for 1 us;
            clk <= '0';
            wait for 1 us;
        end loop;
        wait;
    end process;

end arch;

