library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity nco_controller is
    generic (
        NCO_PHASE_WIDTH : integer := 32;
        NCO_WIDTH : integer := 16;
        FFT_WIDTH : integer := 16;
        PACKET_LEN : integer := 8192;
        FIFO_DEPTH : integer := 8192;

        AV_DATA_WIDTH : integer := 47; -- 1*FFT_WIDTH : real | 1*FFT_WIDTH : imag | ceil(log2(PACKET_LEN)) + 1 : fftpts/length | 1 : inverse
        
        CLK_FREQ : integer := 50000000
    );
    port (
        clk : in std_logic;
        reset_n : in std_logic;
        
        aso_ncoin_data : out std_logic_vector(NCO_PHASE_WIDTH-1 downto 0);
        aso_ncoin_valid : out std_logic;

        asi_ncoout_data : in std_logic_vector(NCO_WIDTH-1 downto 0);
        asi_ncoout_valid : in std_logic;

        aso_fftin_data : out std_logic_vector(AV_DATA_WIDTH-1 downto 0);
        aso_fftin_valid : out std_logic;
        aso_fftin_ready : in std_logic;
        aso_fftin_sop, aso_fftin_eop : out std_logic;

        avs_csr_address : in std_logic_vector(3 downto 0);
        avs_csr_writedata : in std_logic_vector(31 downto 0);
        avs_csr_write : in std_logic;
        avs_csr_readdata : out std_logic_vector(31 downto 0);
        avs_csr_read : in std_logic

    );
end entity nco_controller;

architecture rtl of nco_controller is
--------    fifo        --------
    type mem_t is array (0 to FIFO_DEPTH-1) of std_logic_vector(NCO_WIDTH-1 downto 0);
    signal mem_fifo : mem_t;
    attribute ram_init_file : string;
    attribute ram_init_file of mem_fifo : signal is ""; -- used to create mem out of memory blocks

    signal r_fifoInIdx : integer range 0 to FIFO_DEPTH-1;
    signal r_fifoOutIdx : integer range 0 to FIFO_DEPTH-1;
    signal w_fillcount : integer range 0 to FIFO_DEPTH-1;

    signal r_prefetch_data : std_logic_vector(NCO_WIDTH-1 downto 0);
    signal r_prefetch_valid : std_logic;
    signal r_prefetch_ready : std_logic;
--------    end fifo    --------

    type packet_t is (idle_s, work_s);
    signal r_packet_s : packet_t;
    
    constant c_packetwidth : integer := integer(ceil(log2(real(PACKET_LEN))));
    signal r_fftreal : std_logic_vector(FFT_WIDTH-1 downto 0);
    signal r_fftimag : std_logic_vector(FFT_WIDTH-1 downto 0);
    signal r_fftpts : std_logic_vector(c_packetwidth downto 0);
    signal r_fftinverse : std_logic;
    signal r_fftvalid : std_logic;

    signal r_packetcounter : std_logic_vector(c_packetwidth downto 0);

    signal r_en : std_logic;
    signal r_fcw : std_logic_vector(NCO_PHASE_WIDTH-1 downto 0);
    signal r_diviation : std_logic_vector(NCO_PHASE_WIDTH-1 downto 0);
    signal r_diviation_step : std_logic_vector(NCO_PHASE_WIDTH-1 downto 0);
    signal r_rate : std_logic_vector(31 downto 0);

    signal r_rate_counter : integer range 0 to CLK_FREQ-1;
    signal r_nco_pha : std_logic_vector(NCO_PHASE_WIDTH-1 downto 0);

begin
    
    csr_config: process(clk, reset_n)
    begin
        if reset_n = '0' then
            r_en <= '0';
            avs_csr_readdata <= (others => '0');
            r_fcw <= (others => '0');
            r_diviation <= (others => '0');
            r_diviation_step <= (others => '0');
            r_rate <= (others => '0');
        elsif rising_edge(clk) then
            if avs_csr_write = '1' then
                case to_integer(unsigned(avs_csr_address)) is
                    when 0 =>
                        r_en <= avs_csr_writedata(0);
                    when 1 =>
                        r_fcw <= avs_csr_writedata(NCO_PHASE_WIDTH-1 downto 0);
                    when 2 =>
                        r_diviation <= avs_csr_writedata(NCO_PHASE_WIDTH-1 downto 0);
                    when 3 =>
                        r_rate <= avs_csr_writedata;
                    when 4 =>
                        r_diviation_step <= avs_csr_writedata(NCO_PHASE_WIDTH-1 downto 0);
                    when others =>
                end case;
            elsif avs_csr_read = '1' then
                case to_integer(unsigned(avs_csr_address)) is
                    when 0 =>
                        avs_csr_readdata(0) <= r_en;
                    when 1 =>
                        avs_csr_readdata <= (others => '0');
                        avs_csr_readdata(NCO_PHASE_WIDTH-1 downto 0) <= r_fcw;
                    when 2 =>
                        avs_csr_readdata <= (others => '0');
                        avs_csr_readdata(NCO_PHASE_WIDTH-1 downto 0) <= r_diviation;
                    when 3 =>
                        avs_csr_readdata <= r_rate;
                    when others =>
                        avs_csr_readdata <= (others => '0');
                end case;
            end if;
        end if;
    end process csr_config;

    nco_control: process(clk, reset_n)
    begin
        if reset_n = '0' then
            r_nco_pha <= (others => '0');
            aso_ncoin_valid <= '0';
            r_rate_counter <= 0;
        elsif rising_edge(clk) then
            if r_en = '1' then
                aso_ncoin_valid <= '1';
                if r_rate_counter < r_rate then
                    r_rate_counter <= r_rate_counter + 1;
                    r_nco_pha <= r_nco_pha + r_diviation_step;
                else
                    r_rate_counter <= 0;
                    r_nco_pha <= r_fcw - r_diviation;
                end if;
            else
                aso_ncoin_valid <= '0';
            end if;
        end if;
    end process nco_control;

    aso_ncoin_data <= r_nco_pha;
    
    fill_count : process(r_fifoInIdx, r_fifoOutIdx)
    begin
        if r_fifoInIdx < r_fifoOutIdx then
            w_fillcount <= r_fifoInIdx - r_fifoOutIdx + FIFO_DEPTH;
        else
            w_fillcount <= r_fifoInIdx - r_fifoOutIdx;
        end if;
    end process fill_count;

    fifo: process(clk, reset_n)
    begin
        if reset_n = '0' then
            r_fifoInIdx <= 0;
            r_fifoOutIdx <= 0;
            r_prefetch_valid <= '0';
            r_prefetch_data <= (others => '0');
        elsif rising_edge(clk) then
            if w_fillcount < FIFO_DEPTH-1 then
                if asi_ncoout_valid = '1' then
                    mem_fifo(r_fifoInIdx) <= asi_ncoout_data;
                    if r_fifoInIdx < FIFO_DEPTH-1 then
                        r_fifoInIdx <= r_fifoInIdx + 1;
                    else
                        r_fifoInIdx <= 0;
                    end if;
                end if;
            end if;

            if r_prefetch_ready = '0' then
                r_prefetch_valid <= r_prefetch_valid;
            else
                r_prefetch_valid <= '0';
            end if;
            if w_fillcount > 0 then
                if r_prefetch_valid = '0' or r_prefetch_ready = '1' then
                    r_prefetch_valid <= '1';
                    r_prefetch_data <= mem_fifo(r_fifoOutIdx);
                    if r_fifoOutIdx < FIFO_DEPTH-1 then
                        r_fifoOutIdx <= r_fifoOutIdx + 1;
                    else
                        r_fifoOutIdx <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process fifo;

    cntrl: process(clk, reset_n)
    begin
        if reset_n = '0' then
            r_fftreal   <= (others => '0');
            r_fftimag   <= (others => '0');
            r_fftpts    <= (others => '0');
            r_fftinverse <= '0';
            r_prefetch_ready <= '0';
            r_packetcounter <= (others => '0');
            r_packet_s <= idle_s;
            aso_fftin_eop <= '0';
            aso_fftin_sop <= '0';
            r_fftvalid <= '0';
        elsif rising_edge(clk) then
            r_fftimag <= (others => '0');

            aso_fftin_eop <= '0';
            aso_fftin_sop <= '0';
            r_fftvalid <= '0';
            r_packet_s <= r_packet_s;
            r_prefetch_ready <= '0';

            case r_packet_s is
                when idle_s =>
                    if r_prefetch_valid = '1' then
                        r_fftreal <= r_prefetch_data;
                        r_prefetch_ready <= '1';
                        r_fftpts <= std_logic_vector(to_unsigned(PACKET_LEN, c_packetwidth+1));
                        r_fftinverse <= '0';

                        aso_fftin_sop <= '1';
                        r_fftvalid <= '1';
                        
                        r_packetcounter <= r_packetcounter + 1;
                        r_packet_s <= work_s;
                    end if;

                when work_s =>
                    if aso_fftin_ready = '0' then
                        r_fftvalid <= r_fftvalid;
                    end if;
                    if aso_fftin_ready = '1' or r_fftvalid = '0' then
                        if r_prefetch_valid = '1' then
                            r_fftreal <= r_prefetch_data;
                            r_fftvalid <= '1';
                            r_prefetch_ready <= '1';

                            if r_packetcounter < PACKET_LEN-1 then
                                r_packetcounter <= r_packetcounter + 1;
                            else
                                r_packetcounter <= (others => '0');
                                aso_fftin_eop <= '1';
                                r_packet_s <= idle_s;
                            end if;
                        end if;
                    end if;
                when others =>
            end case;
        end if;
    end process cntrl;
    
    aso_fftin_data <= r_fftreal & r_fftimag & r_fftpts & r_fftinverse;
    aso_fftin_valid <= r_fftvalid;
end architecture rtl;