library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity packet_decimation_cntrl is
    port (
        clk : in std_logic;
        reset_n : in std_logic;

        i_start : in std_logic;

        avm_csr_address     : out std_logic_vector(3 downto 0);
        avm_csr_writedata   : out std_logic_vector(31 downto 0);
        avm_csr_write       : out std_logic;
        avm_csr_readdata    : in std_logic_vector(31 downto 0);
        avm_csr_read        : out std_logic
    );
end entity packet_decimation_cntrl;

architecture rtl of packet_decimation_cntrl is
    signal r_prev_start : std_logic;
begin
    send_command: process(clk, reset_n)
    begin
        if reset_n = '0' then
            avm_csr_address <= (others => '0');
            avm_csr_read <= '0';
            avm_csr_write <= '0';
            avm_csr_writedata <= (others => '0');
        elsif rising_edge(clk) then
            r_prev_start <= i_start;
            avm_csr_write <= '0';
            avm_csr_read <= '0';
            if i_start = '1' and r_prev_start = '0' then
                avm_csr_address <= (others => '0');
                avm_csr_write <= '1';
                avm_csr_writedata <= (others => '0');
                avm_csr_writedata(0) <= '1';
            end if;
        end if;
    end process send_command;
end architecture rtl;