library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity packet_decimation_avg is
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
end entity packet_decimation_avg;

architecture rtl of packet_decimation_avg is
    constant c_packetwidth : integer := integer(ceil(log2(real(PACKET_LEN))));
    constant c_bytes : integer := DATA_WIDTH/8;

    signal r_base_address : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal r_en : std_logic;

    type control_t is (first_packet_s, other_packets_s,wait_for_send_s);
    signal r_control_state : control_t;

    type stream_states_t is (idle_s, write_s);
    signal r_stream_states : stream_states_t;

    constant c_decimation_factor : integer := CLK_FREQ/PACKET_RATE;
    signal r_decimation_factor : std_logic_vector(31 downto 0);
    signal r_decimation_counter : integer range 0 to 2*CLK_FREQ;

    type mm_t is (idle_s, write_s, done_s);
    signal r_mm_state : mm_t;

    signal r_address : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    signal r_mm_we : std_logic;

    signal r_clear : std_logic;
    signal r_done : std_logic;

    type buff_t is array (0 to PACKET_LEN-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal buff : buff_t;
    attribute ram_init_file : string;
    attribute ram_init_file of buff : signal is ""; -- used to create mem out of memory blocks

    signal w_inversed_index : std_logic_vector(c_packetwidth-1 downto 0);

    signal r_write_buff_idx : std_logic_vector(c_packetwidth-1 downto 0);
    signal w_write_buff_idx : integer range 0 to PACKET_LEN;

    signal r_read_buff_idx : integer range 0 to PACKET_LEN;
    signal w_read_buff_idx : integer range 0 to PACKET_LEN;

    signal r_prev_index : std_logic_vector(c_packetwidth-1 downto 0);
    signal r_prev_data : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal r_prev_buff_data : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal r_read_buff_data : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal w_write_buff_data : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal r_write_needed : std_logic;

    signal r_write : std_logic;

begin

    ram_process: process(clk, reset_n)
    begin
        if rising_edge(clk) then
            if r_write = '1' then
                buff(w_write_buff_idx) <= w_write_buff_data;
            end if;
            r_read_buff_data <= buff(w_read_buff_idx);
        end if;
    end process ram_process;


    gen_inverse:
    for i in 0 to c_packetwidth-1 generate
        w_inversed_index(i) <= r_write_buff_idx((c_packetwidth-1)-i);
    end generate gen_inverse;
    
    csr_config: process(clk, reset_n)
    begin
            if reset_n = '0' then
                r_base_address <= (others => '0');
                r_en <= '0';
                avs_csr_readdata <= (others => '0');
                r_clear <= '0';
                r_decimation_factor <= std_logic_vector(to_unsigned(c_decimation_factor, 32));
            elsif rising_edge(clk) then
                if avs_csr_write = '1' then
                    case to_integer(unsigned(avs_csr_address)) is
                        when 0 =>
                            r_en <= avs_csr_writedata(0);
                            r_clear <= avs_csr_writedata(1);
                        when 1 =>
                            r_base_address <= avs_csr_writedata(ADDRESS_WIDTH-1 downto 0);
                        when 2 =>
                            r_decimation_factor <= avs_csr_writedata;
                    
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
                            -- avs_csr_readdata(c_packetwidth downto 0) <= PACKET_LEN;
                        when 3 =>
                            avs_csr_readdata <= std_logic_vector(to_unsigned(r_read_buff_idx, 32));
                        when others =>
                            avs_csr_readdata <= (others => '0');
                    end case;
                end if;
            end if;
    end process csr_config;
    

    w_read_buff_idx <= to_integer(unsigned(w_inversed_index)) when r_control_state = other_packets_s else r_read_buff_idx;
    w_write_buff_idx <= to_integer(unsigned(w_inversed_index)) when r_control_state = first_packet_s else to_integer(unsigned(r_prev_index));
    
    w_write_buff_data <= asi_fftin_data when r_control_state = first_packet_s else r_prev_data + r_read_buff_data;
    
    avm_mem_writedata <= r_read_buff_data; --when r_control_state = wait_for_send_s else (others => '0'); 
    -- r_prev_buff_data <= r_read_buff_data when r_control_state = other_packets_s else (others => '0');
    write_to_buff: process(clk, reset_n)
    begin
        if reset_n = '0' then
            r_stream_states <= idle_s;
            r_decimation_counter <= 0;
            r_write_buff_idx <= (others => '0');
            asi_fftin_ready <= '0';
            r_control_state <= first_packet_s;

            r_write_needed <= '0';
            r_prev_data <= (others => '0');
            r_prev_index <= (others => '0');
            -- r_prev_buff_data <= (others => '0');
        elsif rising_edge(clk) then
            asi_fftin_ready <= '1';
            r_write <= '0';

            case r_control_state is
            when first_packet_s =>
                case r_stream_states is
                when idle_s =>
                    if asi_fftin_sop = '1' and asi_fftin_valid = '1' and r_en = '1' then
                        -- buff(w_write_buff_idx) <= asi_fftin_data;
                        -- buff(w_write_buff_idx) <= w_write_buff_data;
                        r_write <= '1';

                        r_write_buff_idx <= r_write_buff_idx + 1;
                        r_decimation_counter <= r_decimation_counter + 1;
                        r_stream_states <= write_s;
                    end if;
                    
                when write_s =>
                    r_decimation_counter <= r_decimation_counter + 1;

                    if asi_fftin_valid = '1' then
                        -- buff(w_write_buff_idx) <= asi_fftin_data;
                        -- buff(w_write_buff_idx) <= w_write_buff_data;
                        r_write <= '1';
                        r_write_buff_idx <= r_write_buff_idx + 1;
                    end if;
                    if asi_fftin_eop = '1' and asi_fftin_valid = '1' then
                        r_stream_states <= idle_s;
                        r_control_state <= other_packets_s;
                        r_write_buff_idx <= (others => '0');
                    end if;
                when others =>
                end case;
            
            when other_packets_s =>
                if r_write_needed = '1' then
                    -- buff(w_write_buff_idx) <= r_prev_data + r_prev_buff_data;
                    -- buff(w_write_buff_idx) <= w_write_buff_data;
                    r_write <= '1';
                    r_write_needed <= '0';
                end if;

                case r_stream_states is
                when idle_s =>
                    if asi_fftin_sop = '1' and asi_fftin_valid = '1' then
                        -- r_prev_buff_data <= buff(w_read_buff_idx);
                        -- r_read_buff_data <= buff(w_read_buff_idx);
                        r_prev_data <= asi_fftin_data;
                        r_prev_index <= w_inversed_index;
                        r_write_needed <= '1';
                        
                        r_write_buff_idx <= r_write_buff_idx + 1;
                        r_decimation_counter <= r_decimation_counter + 1;
                        r_stream_states <= write_s;
                    end if;
                    
                when write_s =>
                    r_decimation_counter <= r_decimation_counter + 1;

                    if asi_fftin_valid = '1' then
                        -- r_prev_buff_data <= buff(w_read_buff_idx);
                        -- r_read_buff_data <= buff(w_read_buff_idx);
                        r_prev_data <= asi_fftin_data;
                        r_prev_index <= w_inversed_index;
                        r_write_needed <= '1';

                        r_write_buff_idx <= r_write_buff_idx + 1;
                    end if;
                    if asi_fftin_eop = '1' and asi_fftin_valid = '1' then
                        r_stream_states <= idle_s;
                        r_write_buff_idx <= (others => '0');

                        if r_decimation_counter < r_decimation_factor-1 then
                            r_decimation_counter <= r_decimation_counter + 1;
                        else
                            r_decimation_counter <= 0;
                            r_control_state <= wait_for_send_s;
                        end if;
                    end if;

                when others =>
                end case;
                
            when wait_for_send_s =>
                if r_mm_state = done_s and r_clear = '1' then
                    r_control_state <= first_packet_s;
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
            -- avm_mem_writedata <= (others => '0');
            avm_mem_address <= (others => '0');
            r_done <= '0';
            ins_csr_interrupt <= '0';
        elsif rising_edge(clk) then

            case r_mm_state is
                when idle_s =>
                    if r_control_state = wait_for_send_s then
                        r_mm_state <= write_s;
                        r_read_buff_idx <= r_read_buff_idx + 1;
                        r_address <= r_address + c_bytes;
                        -- avm_mem_writedata <= buff(w_read_buff_idx);
                        -- r_read_buff_data <= buff(w_read_buff_idx);
                        avm_mem_address <= r_base_address;
                        r_mm_we <= '1';
                    end if;

                when write_s =>
                    if r_mm_we = '0' or avm_mem_waitrequest = '0' then
                        if r_read_buff_idx < PACKET_LEN then
                            r_mm_we <= '1';
                            r_read_buff_idx <= r_read_buff_idx + 1;
                            r_address <= r_address + c_bytes;
                            -- avm_mem_writedata <= buff(w_read_buff_idx);
                            -- r_read_buff_data <= buff(w_read_buff_idx);
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
                    if r_control_state = first_packet_s then
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