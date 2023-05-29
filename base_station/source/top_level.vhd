library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity top_level is
	port (
		FPGA_CLK1_50 : in std_logic;
		FPGA_CLK2_50 : in std_logic;
		FPGA_CLK3_50 : in std_logic; 
		
		HDMI_I2C_SCL	:	 inout std_logic;
		HDMI_I2C_SDA	:	 inout std_logic;
		HDMI_I2S		:	 inout std_logic;
		HDMI_LRCLK		:	 inout std_logic;
		HDMI_MCLK		:	 inout std_logic;
		HDMI_SCLK		:	 inout std_logic;
		HDMI_TX_CLK		:	 out std_logic;
		HDMI_TX_D		:	 out std_logic_vector(23 downto 0);
		HDMI_TX_DE		:	 out std_logic;
		HDMI_TX_HS		:	 out std_logic;
		HDMI_TX_INT		:	 in std_logic;
		HDMI_TX_VS		:	 out std_logic;
		
		HPS_CONV_USB_N : inout std_logic;
		
		HPS_DDR3_ADDR	: out std_logic_vector(14 downto 0);
		HPS_DDR3_BA		: out std_logic_vector(2 downto 0);
		HPS_DDR3_CAS_N	: out std_logic;
		HPS_DDR3_CK_N	: out std_logic;
		HPS_DDR3_CK_P	: out std_logic;
		HPS_DDR3_CKE	: out std_logic;
		HPS_DDR3_CS_N 	: out std_logic;
		HPS_DDR3_DM		: out std_logic_vector(3 downto 0);
		HPS_DDR3_DQ		: inout std_logic_vector(31 downto 0);
		HPS_DDR3_DQS_N	: inout std_logic_vector(3 downto 0);
		HPS_DDR3_DQS_P	: inout std_logic_vector(3 downto 0);
		HPS_DDR3_ODT	: out std_logic;
		HPS_DDR3_RAS_N	: out std_logic;
		HPS_DDR3_RESET_N: out std_logic;
		HPS_DDR3_RZQ	: in std_logic;
		HPS_DDR3_WE_N	: out std_logic;
		
		HPS_ENET_GTX_CLK	: out std_logic;
		HPS_ENET_INT_N		: inout std_logic;
		HPS_ENET_MDC		: out std_logic;
		HPS_ENET_MDIO		: inout std_logic;
		HPS_ENET_RX_CLK		: in std_logic;
		HPS_ENET_RX_DATA	: in std_logic_vector(31 downto 0);
		HPS_ENET_RX_DV		: in std_logic;
		HPS_ENET_TX_DATA	: out std_logic_vector(3 downto 0);
		HPS_ENET_TX_EN		: out std_logic;
		
		HPS_GSENSOR_INT	: inout std_logic;
		
		HPS_I2C0_SCLK	: inout std_logic;
		HPS_I2C0_SDAT	: inout std_logic;
		HPS_I2C1_SCLK	: inout std_logic;
		HPS_I2C1_SDAT	: inout std_logic;
		
		HPS_KEY			: inout std_logic;
		HPS_LED			: inout std_logic;
		HPS_LTC_GPIO	: inout std_logic;
		
		HPS_SD_CLK	: out std_logic;
		HPS_SD_CMD	: inout std_logic;
		HPS_SD_DATA	: inout std_logic_vector(3 downto 0);
		
		HPS_SPIM_CLK	: out std_logic;
		HPS_SPIM_MISO	: in std_logic;
		HPS_SPIM_MOSI	: out std_logic;
		HPS_SPIM_SS		: inout std_logic;
		
		HPS_UART_RX	: in std_logic;
		HPS_UART_TX	: out std_logic;
		
		HPS_USB_CLKOUT 	: in std_logic;
		HPS_USB_DATA	: inout std_logic_vector(7 downto 0);
		HPS_USB_DIR		: in std_logic;
		HPS_USB_NXT		: in std_logic;
		HPS_USB_STP		: out std_logic;
		
		
		KEY	: in std_logic_vector(1 downto 0);
		LED : out std_logic_vector(7 downto 0);
		SW	: in std_logic_vector(3 downto 0)
	);
end entity;
	
architecture rtl_top_level of top_level is
	component soc_system is
		port (
			clk_clk                               : in    std_logic                     := '0';             --                            clk.clk
			reset_reset_n                         : in    std_logic                     := '0';             --                          reset.reset_n
			
			memory_mem_a                          : out   std_logic_vector(14 downto 0);                    --                         memory.mem_a
			memory_mem_ba                         : out   std_logic_vector(2 downto 0);                     --                               .mem_ba
			memory_mem_ck                         : out   std_logic;                                        --                               .mem_ck
			memory_mem_ck_n                       : out   std_logic;                                        --                               .mem_ck_n
			memory_mem_cke                        : out   std_logic;                                        --                               .mem_cke
			memory_mem_cs_n                       : out   std_logic;                                        --                               .mem_cs_n
			memory_mem_ras_n                      : out   std_logic;                                        --                               .mem_ras_n
			memory_mem_cas_n                      : out   std_logic;                                        --                               .mem_cas_n
			memory_mem_we_n                       : out   std_logic;                                        --                               .mem_we_n
			memory_mem_reset_n                    : out   std_logic;                                        --                               .mem_reset_n
			memory_mem_dq                         : inout std_logic_vector(31 downto 0) := (others => '0'); --                               .mem_dq
			memory_mem_dqs                        : inout std_logic_vector(3 downto 0)  := (others => '0'); --                               .mem_dqs
			memory_mem_dqs_n                      : inout std_logic_vector(3 downto 0)  := (others => '0'); --                               .mem_dqs_n
			memory_mem_odt                        : out   std_logic;                                        --                               .mem_odt
			memory_mem_dm                         : out   std_logic_vector(3 downto 0);                     --                               .mem_dm
			memory_oct_rzqin                      : in    std_logic                     := '0';             --                               .oct_rzqin
			
			hps_0_hps_io_hps_io_emac1_inst_TX_CLK : out   std_logic;                                        --                   hps_0_hps_io.hps_io_emac1_inst_TX_CLK
			hps_0_hps_io_hps_io_emac1_inst_TXD0   : out   std_logic;                                        --                               .hps_io_emac1_inst_TXD0
			hps_0_hps_io_hps_io_emac1_inst_TXD1   : out   std_logic;                                        --                               .hps_io_emac1_inst_TXD1
			hps_0_hps_io_hps_io_emac1_inst_TXD2   : out   std_logic;                                        --                               .hps_io_emac1_inst_TXD2
			hps_0_hps_io_hps_io_emac1_inst_TXD3   : out   std_logic;                                        --                               .hps_io_emac1_inst_TXD3
			hps_0_hps_io_hps_io_emac1_inst_RXD0   : in    std_logic                     := '0';             --                               .hps_io_emac1_inst_RXD0
			hps_0_hps_io_hps_io_emac1_inst_MDIO   : inout std_logic                     := '0';             --                               .hps_io_emac1_inst_MDIO
			hps_0_hps_io_hps_io_emac1_inst_MDC    : out   std_logic;                                        --                               .hps_io_emac1_inst_MDC
			hps_0_hps_io_hps_io_emac1_inst_RX_CTL : in    std_logic                     := '0';             --                               .hps_io_emac1_inst_RX_CTL
			hps_0_hps_io_hps_io_emac1_inst_TX_CTL : out   std_logic;                                        --                               .hps_io_emac1_inst_TX_CTL
			hps_0_hps_io_hps_io_emac1_inst_RX_CLK : in    std_logic                     := '0';             --                               .hps_io_emac1_inst_RX_CLK
			hps_0_hps_io_hps_io_emac1_inst_RXD1   : in    std_logic                     := '0';             --                               .hps_io_emac1_inst_RXD1
			hps_0_hps_io_hps_io_emac1_inst_RXD2   : in    std_logic                     := '0';             --                               .hps_io_emac1_inst_RXD2
			hps_0_hps_io_hps_io_emac1_inst_RXD3   : in    std_logic                     := '0';             --                               .hps_io_emac1_inst_RXD3
			
			hps_0_hps_io_hps_io_sdio_inst_CMD     : inout std_logic                     := '0';             --                               .hps_io_sdio_inst_CMD
			hps_0_hps_io_hps_io_sdio_inst_D0      : inout std_logic                     := '0';             --                               .hps_io_sdio_inst_D0
			hps_0_hps_io_hps_io_sdio_inst_D1      : inout std_logic                     := '0';             --                               .hps_io_sdio_inst_D1
			hps_0_hps_io_hps_io_sdio_inst_CLK     : out   std_logic;                                        --                               .hps_io_sdio_inst_CLK
			hps_0_hps_io_hps_io_sdio_inst_D2      : inout std_logic                     := '0';             --                               .hps_io_sdio_inst_D2
			hps_0_hps_io_hps_io_sdio_inst_D3      : inout std_logic                     := '0';             --                               .hps_io_sdio_inst_D3
			
			hps_0_hps_io_hps_io_usb1_inst_D0      : inout std_logic                     := '0';             --                               .hps_io_usb1_inst_D0
			hps_0_hps_io_hps_io_usb1_inst_D1      : inout std_logic                     := '0';             --                               .hps_io_usb1_inst_D1
			hps_0_hps_io_hps_io_usb1_inst_D2      : inout std_logic                     := '0';             --                               .hps_io_usb1_inst_D2
			hps_0_hps_io_hps_io_usb1_inst_D3      : inout std_logic                     := '0';             --                               .hps_io_usb1_inst_D3
			hps_0_hps_io_hps_io_usb1_inst_D4      : inout std_logic                     := '0';             --                               .hps_io_usb1_inst_D4
			hps_0_hps_io_hps_io_usb1_inst_D5      : inout std_logic                     := '0';             --                               .hps_io_usb1_inst_D5
			hps_0_hps_io_hps_io_usb1_inst_D6      : inout std_logic                     := '0';             --                               .hps_io_usb1_inst_D6
			hps_0_hps_io_hps_io_usb1_inst_D7      : inout std_logic                     := '0';             --                               .hps_io_usb1_inst_D7
			hps_0_hps_io_hps_io_usb1_inst_CLK     : in    std_logic                     := '0';             --                               .hps_io_usb1_inst_CLK
			hps_0_hps_io_hps_io_usb1_inst_STP     : out   std_logic;                                        --                               .hps_io_usb1_inst_STP
			hps_0_hps_io_hps_io_usb1_inst_DIR     : in    std_logic                     := '0';             --                               .hps_io_usb1_inst_DIR
			hps_0_hps_io_hps_io_usb1_inst_NXT     : in    std_logic                     := '0';             --                               .hps_io_usb1_inst_NXT
			
			hps_0_hps_io_hps_io_spim1_inst_CLK    : out   std_logic;                                        --                               .hps_io_spim1_inst_CLK
			hps_0_hps_io_hps_io_spim1_inst_MOSI   : out   std_logic;                                        --                               .hps_io_spim1_inst_MOSI
			hps_0_hps_io_hps_io_spim1_inst_MISO   : in    std_logic                     := '0';             --                               .hps_io_spim1_inst_MISO
			hps_0_hps_io_hps_io_spim1_inst_SS0    : out   std_logic;                                        --                               .hps_io_spim1_inst_SS0
			
			hps_0_hps_io_hps_io_uart0_inst_RX     : in    std_logic                     := '0';             --                               .hps_io_uart0_inst_RX
			hps_0_hps_io_hps_io_uart0_inst_TX     : out   std_logic;                                        --                               .hps_io_uart0_inst_TX
			
			hps_0_hps_io_hps_io_i2c0_inst_SDA     : inout std_logic                     := '0';             --                               .hps_io_i2c0_inst_SDA
			hps_0_hps_io_hps_io_i2c0_inst_SCL     : inout std_logic                     := '0';             --                               .hps_io_i2c0_inst_SCL
			hps_0_hps_io_hps_io_i2c1_inst_SDA     : inout std_logic                     := '0';             --                               .hps_io_i2c1_inst_SDA
			hps_0_hps_io_hps_io_i2c1_inst_SCL     : inout std_logic                     := '0';             --                               .hps_io_i2c1_inst_SCL
			
			hps_0_hps_io_hps_io_gpio_inst_GPIO09  : inout std_logic                     := '0';             --                               .hps_io_gpio_inst_GPIO09
			hps_0_hps_io_hps_io_gpio_inst_GPIO35  : inout std_logic                     := '0';             --                               .hps_io_gpio_inst_GPIO35
			hps_0_hps_io_hps_io_gpio_inst_GPIO40  : inout std_logic                     := '0';             --                               .hps_io_gpio_inst_GPIO40
			hps_0_hps_io_hps_io_gpio_inst_GPIO53  : inout std_logic                     := '0';             --                               .hps_io_gpio_inst_GPIO53
			hps_0_hps_io_hps_io_gpio_inst_GPIO54  : inout std_logic                     := '0';             --                               .hps_io_gpio_inst_GPIO54
			hps_0_hps_io_hps_io_gpio_inst_GPIO61  : inout std_logic                     := '0';             --                               .hps_io_gpio_inst_GPIO61
			
			alt_vip_cl_cvo_0_clocked_video_vid_clk       : in    std_logic                     := '0';             -- alt_vip_cl_cvo_0_clocked_video.vid_clk
			alt_vip_cl_cvo_0_clocked_video_vid_data      : out   std_logic_vector(31 downto 0);                    --                               .vid_data
			alt_vip_cl_cvo_0_clocked_video_underflow     : out   std_logic;                                        --                               .underflow
			alt_vip_cl_cvo_0_clocked_video_vid_datavalid : out   std_logic;                                        --                               .vid_datavalid
			alt_vip_cl_cvo_0_clocked_video_vid_v_sync    : out   std_logic;                                        --                               .vid_v_sync
			alt_vip_cl_cvo_0_clocked_video_vid_h_sync    : out   std_logic;                                        --                               .vid_h_sync
			alt_vip_cl_cvo_0_clocked_video_vid_f         : out   std_logic;                                        --                               .vid_f
			alt_vip_cl_cvo_0_clocked_video_vid_h         : out   std_logic;                                        --                               .vid_h
			alt_vip_cl_cvo_0_clocked_video_vid_v         : out   std_logic;                                        --                               .vid_v
			
			hdmi_clk_clk                                 : out   std_logic;                                        --                       clk_hdmi.clk
			
			led_pio_external_connection_export    : out   std_logic_vector(6 downto 0);                     --    led_pio_external_connection.export
			dipsw_pio_external_connection_export  : in    std_logic_vector(3 downto 0)  := (others => '0'); --  dipsw_pio_external_connection.export
			button_pio_external_connection_export : in    std_logic_vector(1 downto 0)  := (others => '0'); -- button_pio_external_connection.export
			
			hps_0_h2f_reset_reset_n               : out   std_logic;                                        --                hps_0_h2f_reset.reset_n
			hps_0_f2h_cold_reset_req_reset_n      : in    std_logic                     := '0';             --       hps_0_f2h_cold_reset_req.reset_n
			hps_0_f2h_debug_reset_req_reset_n     : in    std_logic                     := '0';             --      hps_0_f2h_debug_reset_req.reset_n
			hps_0_f2h_stm_hw_events_stm_hwevents  : in    std_logic_vector(27 downto 0) := (others => '0'); --        hps_0_f2h_stm_hw_events.stm_hwevents
			hps_0_f2h_warm_reset_req_reset_n      : in    std_logic                     := '0';             --       hps_0_f2h_warm_reset_req.reset_n
			
			f2h_pio_external_connection_export    : in    std_logic_vector(31 downto 0) := (others => '0'); --    f2h_pio_external_connection.export
			h2f_pio_external_connection_export    : out   std_logic_vector(31 downto 0)                     --    h2f_pio_external_connection.export
			
		);
	end component soc_system;
	
	component altera_edge_detector
		generic ( PULSE_EXT : integer := 0; EDGE_TYPE : integer := 0; IGNORE_RST_WHILE_BUSY : integer := 0 );
		port
		(
			clk			:	 in std_logic;
			rst_n		:	 in std_logic;
			signal_in	:	 in std_logic;
			pulse_out	:	 out std_logic
		);
	end component;
	
	component debounce
		generic ( DATA_WIDTH : integer := 32; POLARITY : string := "HIGH"; TIMEOUT : integer := 50000; TIMEOUT_WIDTH : integer := 16 );
			
		port
		(
			clk			:	 in std_logic;
			reset_n		:	 in std_logic;
			data_in		:	 in std_logic_vector(DATA_WIDTH-1 downto 0);
			data_out	:	 out std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component;
	
	component i2c_hdmi_config
		generic ( CLK_Freq : integer := 50000000; I2C_Freq : integer := 20000; LUT_SIZE : integer := 31 );
		port
		(
			iCLK			:	 in std_logic;
			iRST_N			:	 in std_logic;
			I2C_SCLK		:	 out std_logic;
			I2C_SDAT		:	 inout std_logic;
			HDMI_TX_INT		:	 in std_logic;
			READY			:	 out std_logic
		);
	end component;

	signal hps_fpga_reset_n : std_logic;
	signal fpga_debounced_buttons : std_logic_vector(1 downto 0);
	signal fpga_led_internal : std_logic_vector(6 downto 0);
	signal hps_reset_req : std_logic_vector(2 downto 0);
	signal hps_cold_reset : std_logic;
	signal hps_warm_reset : std_logic;
	signal hps_debug_reset : std_logic;
	signal stm_hw_events : std_logic_vector(27 downto 0);
	signal fpga_clk_50 : std_logic;
	
	signal counter : std_logic_vector(25 downto 0);
	signal led_level : std_logic;
	
	signal f2h_pio, h2f_pio : std_logic_vector(31 downto 0);
	
	signal hdmi_clk : std_logic;
	signal w_hdmi_tx_data : std_logic_vector(31 downto 0);
begin
	fpga_clk_50					<= FPGA_CLK1_50;
	LED(7 downto 1) 			<= fpga_led_internal;
	stm_hw_events(27 downto 13) <= (others => '0');
	stm_hw_events(12 downto 9) 	<= SW;
	stm_hw_events(8 downto 2) 	<= fpga_led_internal;
	stm_hw_events(1 downto 0) 	<= fpga_debounced_buttons;
	
	u_I2C_HDMI_Config: component I2C_HDMI_Config
	port map (
		iCLK => FPGA_CLK2_50,
		iRST_N => hps_fpga_reset_n,
		I2C_SCLK => HDMI_I2C_SCL,
		I2C_SDAT => HDMI_I2C_SDA,
		HDMI_TX_INT => HDMI_TX_INT
	);

	u0: component soc_system
	port map (
		clk_clk                               => FPGA_CLK1_50,
		reset_reset_n                         => hps_fpga_reset_n,

		memory_mem_a                          => HPS_DDR3_ADDR,
		memory_mem_ba                         => HPS_DDR3_BA,
		memory_mem_ck                         => HPS_DDR3_CK_P,
		memory_mem_ck_n                       => HPS_DDR3_CK_N,
		memory_mem_cke 						  => HPS_DDR3_CKE,
		memory_mem_cs_n                       => HPS_DDR3_CS_N,
		memory_mem_ras_n                      => HPS_DDR3_RAS_N,
		memory_mem_cas_n                      => HPS_DDR3_CAS_N,
		memory_mem_we_n                       => HPS_DDR3_WE_N,
		memory_mem_reset_n                    => HPS_DDR3_RESET_N,
		memory_mem_dq                         => HPS_DDR3_DQ,
		memory_mem_dqs                        => HPS_DDR3_DQS_P,
		memory_mem_dqs_n                      => HPS_DDR3_DQS_N,
		memory_mem_odt                        => HPS_DDR3_ODT,
		memory_mem_dm                         => HPS_DDR3_DM,
		memory_oct_rzqin                      => HPS_DDR3_RZQ,
		
		hps_0_hps_io_hps_io_emac1_inst_TX_CLK => HPS_ENET_GTX_CLK,
		hps_0_hps_io_hps_io_emac1_inst_TXD0   => HPS_ENET_TX_DATA(0),
		hps_0_hps_io_hps_io_emac1_inst_TXD1   => HPS_ENET_TX_DATA(1),
		hps_0_hps_io_hps_io_emac1_inst_TXD2   => HPS_ENET_TX_DATA(2),
		hps_0_hps_io_hps_io_emac1_inst_TXD3   => HPS_ENET_TX_DATA(3),
		hps_0_hps_io_hps_io_emac1_inst_RXD0   => HPS_ENET_RX_DATA(0),
		hps_0_hps_io_hps_io_emac1_inst_MDIO   => HPS_ENET_MDIO,
		hps_0_hps_io_hps_io_emac1_inst_MDC    => HPS_ENET_MDC,
		hps_0_hps_io_hps_io_emac1_inst_RX_CTL => HPS_ENET_RX_DV,
		hps_0_hps_io_hps_io_emac1_inst_TX_CTL => HPS_ENET_TX_EN,
		hps_0_hps_io_hps_io_emac1_inst_RX_CLK => HPS_ENET_RX_CLK,
		hps_0_hps_io_hps_io_emac1_inst_RXD1   => HPS_ENET_RX_DATA(1),
		hps_0_hps_io_hps_io_emac1_inst_RXD2   => HPS_ENET_RX_DATA(2),
		hps_0_hps_io_hps_io_emac1_inst_RXD3   => HPS_ENET_RX_DATA(3),
		
		hps_0_hps_io_hps_io_sdio_inst_CMD     => HPS_SD_CMD,
		hps_0_hps_io_hps_io_sdio_inst_D0      => HPS_SD_DATA(0),
		hps_0_hps_io_hps_io_sdio_inst_D1      => HPS_SD_DATA(1),
		hps_0_hps_io_hps_io_sdio_inst_CLK     => HPS_SD_CLK,
		hps_0_hps_io_hps_io_sdio_inst_D2      => HPS_SD_DATA(2),
		hps_0_hps_io_hps_io_sdio_inst_D3      => HPS_SD_DATA(3),
		
		hps_0_hps_io_hps_io_usb1_inst_D0      => HPS_USB_DATA(0),
		hps_0_hps_io_hps_io_usb1_inst_D1      => HPS_USB_DATA(1),
		hps_0_hps_io_hps_io_usb1_inst_D2      => HPS_USB_DATA(2),
		hps_0_hps_io_hps_io_usb1_inst_D3      => HPS_USB_DATA(3),
		hps_0_hps_io_hps_io_usb1_inst_D4      => HPS_USB_DATA(4),
		hps_0_hps_io_hps_io_usb1_inst_D5      => HPS_USB_DATA(5),
		hps_0_hps_io_hps_io_usb1_inst_D6      => HPS_USB_DATA(6),
		hps_0_hps_io_hps_io_usb1_inst_D7      => HPS_USB_DATA(7),
		hps_0_hps_io_hps_io_usb1_inst_CLK     => HPS_USB_CLKOUT,
		hps_0_hps_io_hps_io_usb1_inst_STP     => HPS_USB_STP,
		hps_0_hps_io_hps_io_usb1_inst_DIR     => HPS_USB_DIR,
		hps_0_hps_io_hps_io_usb1_inst_NXT     => HPS_USB_NXT,
		
		hps_0_hps_io_hps_io_spim1_inst_CLK    => HPS_SPIM_CLK,
		hps_0_hps_io_hps_io_spim1_inst_MOSI   => HPS_SPIM_MOSI,
		hps_0_hps_io_hps_io_spim1_inst_MISO   => HPS_SPIM_MISO,
		hps_0_hps_io_hps_io_spim1_inst_SS0    => HPS_SPIM_SS,
		
		hps_0_hps_io_hps_io_uart0_inst_RX     => HPS_UART_RX,
		hps_0_hps_io_hps_io_uart0_inst_TX     => HPS_UART_TX,
		
		hps_0_hps_io_hps_io_i2c0_inst_SDA     => HPS_I2C0_SDAT,
		hps_0_hps_io_hps_io_i2c0_inst_SCL     => HPS_I2C0_SCLK,
		hps_0_hps_io_hps_io_i2c1_inst_SDA     => HPS_I2C1_SDAT,
		hps_0_hps_io_hps_io_i2c1_inst_SCL     => HPS_I2C1_SCLK,
		
		hps_0_hps_io_hps_io_gpio_inst_GPIO09  => HPS_CONV_USB_N,
		hps_0_hps_io_hps_io_gpio_inst_GPIO35  => HPS_ENET_INT_N,
		hps_0_hps_io_hps_io_gpio_inst_GPIO40  => HPS_LTC_GPIO,
		hps_0_hps_io_hps_io_gpio_inst_GPIO53  => HPS_LED,
		hps_0_hps_io_hps_io_gpio_inst_GPIO54  => HPS_KEY,
		hps_0_hps_io_hps_io_gpio_inst_GPIO61  => HPS_GSENSOR_INT,
		
		hdmi_clk_clk	=> hdmi_clk,
		
		alt_vip_cl_cvo_0_clocked_video_vid_clk       => hdmi_clk,
		alt_vip_cl_cvo_0_clocked_video_vid_data      => w_hdmi_tx_data,
		alt_vip_cl_cvo_0_clocked_video_underflow     => open,
		alt_vip_cl_cvo_0_clocked_video_vid_datavalid => HDMI_TX_DE,
		alt_vip_cl_cvo_0_clocked_video_vid_v_sync    => HDMI_TX_VS,
		alt_vip_cl_cvo_0_clocked_video_vid_h_sync    => HDMI_TX_HS,
		alt_vip_cl_cvo_0_clocked_video_vid_f         => open,
		alt_vip_cl_cvo_0_clocked_video_vid_h         => open,
		alt_vip_cl_cvo_0_clocked_video_vid_v         => open,
	  
		led_pio_external_connection_export    => fpga_led_internal,
		dipsw_pio_external_connection_export  => SW,
		button_pio_external_connection_export => fpga_debounced_buttons,
		
		hps_0_h2f_reset_reset_n               => hps_fpga_reset_n,
		hps_0_f2h_cold_reset_req_reset_n      => not hps_cold_reset,
		hps_0_f2h_debug_reset_req_reset_n     => not hps_debug_reset,
		hps_0_f2h_stm_hw_events_stm_hwevents  => stm_hw_events,
		hps_0_f2h_warm_reset_req_reset_n      => not hps_warm_reset,
		
		
		f2h_pio_external_connection_export    => f2h_pio,
		h2f_pio_external_connection_export    => h2f_pio
		
	);
	HDMI_TX_CLK <= hdmi_clk;
	HDMI_TX_D <= w_hdmi_tx_data(23 downto 0);
	debounce_inst : component debounce
	generic map (DATA_WIDTH => 2, POLARITY => "LOW", TIMEOUT => 50000, TIMEOUT_WIDTH => 16)
	port map (
		clk => fpga_clk_50,
		reset_n => hps_fpga_reset_n,
		data_in => KEY,
		data_out => fpga_debounced_buttons
	);
	
	pulse_cold_reset: component altera_edge_detector
	generic map (PULSE_EXT => 6, EDGE_TYPE => 1, IGNORE_RST_WHILE_BUSY => 1)
	port map (
		clk => fpga_clk_50,
		rst_n => hps_fpga_reset_n,
		signal_in => hps_reset_req(0),
		pulse_out => hps_cold_reset
	);
	
	pulse_warm_reset: component altera_edge_detector
	generic map (PULSE_EXT => 2, EDGE_TYPE => 1, IGNORE_RST_WHILE_BUSY => 1)
	port map (
		clk => fpga_clk_50,
		rst_n => hps_fpga_reset_n,
		signal_in => hps_reset_req(1),
		pulse_out => hps_warm_reset
	);
	
	pulse_debug_reset: component altera_edge_detector
	generic map (PULSE_EXT => 2, EDGE_TYPE => 1, IGNORE_RST_WHILE_BUSY => 1)
	port map (
		clk => fpga_clk_50,
		rst_n => hps_fpga_reset_n,
		signal_in => hps_reset_req(2),
		pulse_out => hps_debug_reset
	);

	f2h_pio(3 downto 0) <= SW;
	f2h_pio(5 downto 4) <= KEY;
	f2h_pio(31 downto 6) <= (others => '0');
	
	process(fpga_clk_50, hps_fpga_reset_n)
	begin
		if hps_fpga_reset_n = '0' then
			counter <= (others => '0');
			led_level <= '0';
		elsif rising_edge(fpga_clk_50) then
			if counter < 24999999 then
				counter <= counter + 1;
			else
				counter <= (others => '0');
				led_level <= not led_level;
			end if;
		end if;
	end process;
	
	LED(0) <= led_level;

end architecture;