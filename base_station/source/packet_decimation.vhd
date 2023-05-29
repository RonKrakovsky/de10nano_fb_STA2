library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity packet_decimation is
    generic (
        CLK_FREQ : integer := 50000000;
        PACKET_RATE : integer := 60;
        PACKET_LEN : integer := 8192;
        DATA_WIDTH : integer := 8;
        ADDRESS_WIDTH : integer := 13
    );
    port (
        clk : in std_logic;
        reset_n : in std_logic;
        
        asi_fftin_data : in std_logic_vector(DATA_WIDTH-1 downto 0);
        asi_fftin_valid : in std_logic;
        asi_fftin_ready : out std_logic;
        asi_fftin_sop, asi_fftin_eop : in std_logic;

        avm_mem_address : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        avm_mem_waitrequest : in std_logic;
        avm_mem_writedata : out std_logic_vector(DATA_WIDTH-1 downto 0);
        avm_mem_write : out std_logic;
        
        ins_csr_interrupt : out std_logic;
        avs_csr_address : in std_logic_vector(3 downto 0);
        avs_csr_writedata : in std_logic_vector(31 downto 0);
        avs_csr_write : in std_logic;
        avs_csr_readdata : out std_logic_vector(31 downto 0);
        avs_csr_read : in std_logic

    );
end entity packet_decimation;

architecture rtl of packet_decimation is
    constant c_packetwidth : integer := integer(ceil(log2(real(PACKET_LEN))));
    signal r_inversed_index : std_logic_vector(c_packetwidth-1 downto 0);

    constant c_bytes : integer := DATA_WIDTH/8;

    signal r_base_address : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal r_en : std_logic;

    type buff_t is array (0 to PACKET_LEN-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal buff : buff_t;
    attribute ram_init_file : string;
    attribute ram_init_file of buff : signal is ""; -- used to create mem out of memory blocks

    type stream_states_t is (idle_s, write_s, delay_s);
    signal r_stream_states : stream_states_t;

    constant c_decimation_factor : integer := CLK_FREQ/PACKET_RATE;
    signal r_decimation_counter : integer range 0 to c_decimation_factor-1;
    signal r_write_buff_idx : std_logic_vector(c_packetwidth-1 downto 0);
    signal r_write_buff_idx_resized : std_logic_vector(c_packetwidth downto 0);
    signal r_packet_len : std_logic_vector(c_packetwidth downto 0);

    type mm_t is (idle_s, write_s, done_s);
    signal r_mm_state : mm_t;

    signal r_address : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal r_read_buff_idx : integer range 0 to PACKET_LEN;
    signal r_mm_we : std_logic;

    signal r_clear : std_logic;
    signal r_done : std_logic;

begin

    gen_inverse:
    for i in 0 to c_packetwidth-1 generate
        r_inversed_index(i) <= r_write_buff_idx((c_packetwidth-1)-i);
    end generate gen_inverse;
    
    r_write_buff_idx_resized <= "0" & r_write_buff_idx;

    csr_config: process(clk, reset_n)
    begin
            if reset_n = '0' then
                r_base_address <= (others => '0');
                r_en <= '0';
                avs_csr_readdata <= (others => '0');
                r_clear <= '0';
            elsif rising_edge(clk) then
                if avs_csr_write = '1' then
                    case to_integer(unsigned(avs_csr_address)) is
                        when 0 =>
                            r_en <= avs_csr_writedata(0);
                            r_clear <= avs_csr_writedata(1);
                        when 1 =>
                            r_base_address <= avs_csr_writedata(ADDRESS_WIDTH-1 downto 0);
                    
                        when others =>
                    end case;
                elsif avs_csr_read = '1' then
                    case to_integer(unsigned(avs_csr_address)) is
                        when 0 =>
                            avs_csr_readdata(0) <= r_en;
                            avs_csr_readdata(1) <= r_done;
                        when 1 =>
                            avs_csr_readdata <= (others => '0');
                            avs_csr_readdata(ADDRESS_WIDTH-1 downto 0) <= r_base_address;
                        when 2 =>
                            avs_csr_readdata <= (others => '0');
                            avs_csr_readdata(c_packetwidth downto 0) <= r_packet_len;
                        when 3 =>
                            avs_csr_readdata <= std_logic_vector(to_unsigned(r_read_buff_idx, 32));
                        when others =>
                            avs_csr_readdata <= (others => '0');
                    end case;
                end if;
            end if;
    end process csr_config;
    
    write_to_buff: process(clk, reset_n)
    begin
        if reset_n = '0' then
            r_stream_states <= idle_s;
            r_decimation_counter <= 0;
            r_write_buff_idx <= (others => '0');
            asi_fftin_ready <= '0';
            r_packet_len <= (others => '0');
        elsif rising_edge(clk) then
            asi_fftin_ready <= '1';
            case r_stream_states is
                when idle_s =>
                    if asi_fftin_sop = '1' and asi_fftin_valid = '1' and r_en = '1' then
                        buff(to_integer(unsigned(r_inversed_index))) <= asi_fftin_data;
                        r_write_buff_idx <= r_write_buff_idx + 1;
                        r_decimation_counter <= r_decimation_counter + 1;
                        r_stream_states <= write_s;
                    end if;
                    
                when write_s =>
                    r_decimation_counter <= r_decimation_counter + 1;

                    if asi_fftin_valid = '1' then
                        buff(to_integer(unsigned(r_inversed_index))) <= asi_fftin_data;
                        r_write_buff_idx <= r_write_buff_idx + 1;
                    end if;
                    if asi_fftin_eop = '1' then
                        r_stream_states <= delay_s;
                        r_packet_len <= r_write_buff_idx_resized + 1;
                        r_write_buff_idx <= (others => '0');
                    end if;

                when delay_s =>
                    if r_decimation_counter < c_decimation_factor-1 then
                        r_decimation_counter <= r_decimation_counter + 1;
                    elsif r_mm_state = done_s and r_clear = '1' then
                        r_decimation_counter <= 0;
                        r_stream_states <= idle_s;
                        r_packet_len <= (others => '0');
                    end if;

                when others =>
            end case;
        end if;
    end process write_to_buff;

    write_to_mem: process(clk, reset_n)
    begin
        if reset_n = '0' then
            r_mm_state <= idle_s;
            r_read_buff_idx <= 0;
            r_address <= (others => '0');
            r_mm_we <= '0';
            avm_mem_writedata <= (others => '0');
            avm_mem_address <= (others => '0');
            r_done <= '0';
            ins_csr_interrupt <= '0';
        elsif rising_edge(clk) then

            case r_mm_state is
                when idle_s =>
                    if r_stream_states = delay_s then
                        r_mm_state <= write_s;
                        r_read_buff_idx <= r_read_buff_idx + 1;
                        r_address <= r_address + c_bytes;
                        avm_mem_writedata <= buff(r_read_buff_idx);
                        avm_mem_address <= r_base_address;
                        r_mm_we <= '1';
                    end if;

                when write_s =>
                    if r_mm_we = '0' or avm_mem_waitrequest = '0' then
                        if r_read_buff_idx < r_packet_len then
                            r_mm_we <= '1';
                            r_read_buff_idx <= r_read_buff_idx + 1;
                            r_address <= r_address + c_bytes;
                            avm_mem_writedata <= buff(r_read_buff_idx);
                            avm_mem_address <= r_address + r_base_address;
                        else
                            r_mm_state <= done_s;
                            r_read_buff_idx <= 0;
                            r_address <= (others => '0');
                            r_mm_we <= '0';
                        end if;
                    end if;
                
                when done_s =>
                    r_done <= '1';
                    ins_csr_interrupt <= '1';
                    if r_stream_states = idle_s then
                        r_mm_state <= idle_s;
                        r_done <= '0';
                        ins_csr_interrupt <= '0';
                    end if;

                when others =>
            end case;
        end if;
    end process write_to_mem;
    avm_mem_write <= r_mm_we;
    
end architecture rtl;