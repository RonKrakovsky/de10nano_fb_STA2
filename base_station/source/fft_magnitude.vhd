library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity fft_magnitude is
    generic (
        FFT_WIDTH : integer := 16;
        PACKET_LEN : integer := 8192;
        AV_DATA_WIDTH : integer := 46 -- 1*FFT_WIDTH : real | 1*FFT_WIDTH : imag | ceil(log2(PACKET_LEN)) + 1 : fftpts/length
    );
    port (
        clk : in std_logic;
        reset_n : in std_logic;
        
        asi_fftout_data : in std_logic_vector(AV_DATA_WIDTH-1 downto 0);
        asi_fftout_valid : in std_logic;
        asi_fftout_ready : out std_logic;
        asi_fftout_sop, asi_fftout_eop : in std_logic;

        aso_fftmagnitude_data : out std_logic_vector(FFT_WIDTH-1 downto 0);
        aso_fftmagnitude_valid : out std_logic;
        aso_fftmagnitude_ready : in std_logic;
        aso_fftmagnitude_sop, aso_fftmagnitude_eop : out std_logic

    );
end entity fft_magnitude;

architecture rtl of fft_magnitude is
    constant c_packetwidth : integer := integer(ceil(log2(real(PACKET_LEN))));
    signal w_fftreal : signed(FFT_WIDTH-1 downto 0);
    signal w_fftimag : signed(FFT_WIDTH-1 downto 0);
    -- signal w_fftpts : std_logic_vector(c_packetwidth downto 0); -- only needed for dynamic packet len
    
    signal r_fftmagnitude_valid : std_logic;
    signal r_fftmagnitude : signed(2*FFT_WIDTH-1 downto 0); -- real^2 + imag^2

    signal r_index : std_logic_vector(c_packetwidth-1 downto 0);
    signal r_inversed_index : std_logic_vector(c_packetwidth-1 downto 0);

begin
    -- w_fftreal <= asi_fftout_data(FFT_WIDTH-1 downto 0);
    -- w_fftimag <= asi_fftout_data(2*FFT_WIDTH-1 downto FFT_WIDTH);
    -- w_fftpts <= asi_fftout_data(AV_DATA_WIDTH-1 downto 2*FFT_WIDTH);

    w_fftreal <= signed(asi_fftout_data(AV_DATA_WIDTH-1 downto AV_DATA_WIDTH-FFT_WIDTH));
    w_fftimag <= signed(asi_fftout_data(AV_DATA_WIDTH-FFT_WIDTH-1 downto AV_DATA_WIDTH-(2*FFT_WIDTH)));
    -- w_fftpts <= asi_fftout_data(c_packetwidth downto 0);
    calc_magnutude: process(clk, reset_n)
    begin
        if reset_n = '0' then
            r_fftmagnitude <= (others => '0');
            asi_fftout_ready <= '0';
            r_fftmagnitude_valid <= '0';
            aso_fftmagnitude_eop <= '0';
            aso_fftmagnitude_sop <= '0';
        elsif rising_edge(clk) then
            asi_fftout_ready <= '0';
            r_fftmagnitude_valid <= '0';

            if aso_fftmagnitude_ready = '0' then
                r_fftmagnitude_valid <= r_fftmagnitude_valid;
            end if;

            if asi_fftout_valid = '1' then
                if r_fftmagnitude_valid = '0' or aso_fftmagnitude_ready = '1' then
                    r_fftmagnitude_valid <= '1';
                    asi_fftout_ready <= '1';
                    r_fftmagnitude <= ((w_fftreal*w_fftreal) + (w_fftimag*w_fftimag));
                    aso_fftmagnitude_eop <= asi_fftout_eop;
                    aso_fftmagnitude_sop <= asi_fftout_sop;
                end if;
            else
                asi_fftout_ready <= '1';
            end if;
        end if;
    end process calc_magnutude;
    aso_fftmagnitude_valid <= r_fftmagnitude_valid;
    aso_fftmagnitude_data <= std_logic_vector(r_fftmagnitude(r_fftmagnitude'left downto r_fftmagnitude'length-FFT_WIDTH));
end architecture rtl;