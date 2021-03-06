LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

-- Top-level entity for the Duke 550 processor system
-- Author unknown, for Duke ECE550
-- Updated Fall 2016 by Tyler Bletsch

ENTITY skeleton IS
	PORT (	inclock, resetn, ps2_clock, ps2_data	: IN STD_LOGIC;
			VGA_CLK2, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC: OUT STD_LOGIC;
			VGA_R, VGA_G, VGA_B: OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END skeleton;

ARCHITECTURE Structure OF skeleton IS
	SIGNAL score_write_en, ps2_acknowledge, DLY_RST, VGA_CLK, VGA_CTRL_CLK, AUD_CTRL_CLK	: STD_LOGIC;
	SIGNAL score_write_data, ps2_ascii	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL vga_data : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL vga_addr : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL block_wren : STD_LOGIC;
	SIGNAL clock	: STD_LOGIC;
	SIGNAL random_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
	COMPONENT ps2 IS
		PORT (	clock, reset, acknowledge, ps2_clock, ps2_data	: IN STD_LOGIC;
				output	: OUT STD_LOGIC_VECTOR(8 DOWNTO 0) );
	END COMPONENT;
	COMPONENT processor IS
		PORT (	clock, reset	: IN STD_LOGIC;
				keyboard_in	: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
				keyboard_ack, score_write	: OUT STD_LOGIC;
				score_data	: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
				vga_data : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
				vga_addr : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
				block_wren : OUT STD_LOGIC;
				random_data: IN STD_LOGIC_VECTOR(31 DOWNTO 0));
	END COMPONENT;
	COMPONENT vga_controller IS
		PORT (	iRST_n : IN STD_LOGIC;
                      iVGA_CLK : IN STD_LOGIC;
                      oBLANK_n : OUT STD_LOGIC;				 
                      oHS : OUT STD_LOGIC;
                      oVS : OUT STD_LOGIC;							 
                      b_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
                      g_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
                      r_data	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
							 vga_data : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
							 vga_addr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
							 write_clk : IN STD_LOGIC;
							 block_wren : IN STD_LOGIC;
							 inscore: IN STD_LOGIC_VECTOR;
							 enscore: IN STD_LOGIC);			
	END COMPONENT;
	COMPONENT VGA_Audio_PLL IS
		PORT ( areset: IN STD_LOGIC;
		inclk0 : IN STD_LOGIC;
		c0,	c1,	c2: OUT STD_LOGIC);
	END COMPONENT;
	COMPONENT pll IS
		PORT (	inclk0	: IN STD_LOGIC;
				c0	: OUT STD_LOGIC);
	END COMPONENT;
		COMPONENT Keep_timer IS
		PORT (	iCLK	: IN STD_LOGIC;
				oRESET	: OUT STD_LOGIC);
	END COMPONENT;
	COMPONENT random_number IS
		PORT (	clk : IN STD_LOGIC;
					data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
	END COMPONENT;
	
	SIGNAL reset : STD_LOGIC;
BEGIN
	--clock divider
	div:	pll PORT MAP (inclock, clock);

	reset <= NOT resetn;
	myprocessor: processor PORT MAP (clock, reset, ps2_ascii, ps2_acknowledge, score_write_en, score_write_data,
												vga_data, vga_addr, block_wren, random_data);
	myps2:	ps2 PORT MAP (clock, reset, ps2_acknowledge, ps2_clock, ps2_data, ps2_ascii(8 DOWNTO 0));
	ps2_ascii(31 DOWNTO 9) <= (OTHERS => '0');
	timekeeper: Keep_timer PORT MAP (inclock, DLY_RST);
	mypll: VGA_Audio_PLL PORT MAP( NOT DLY_RST, inclock, VGA_CTRL_CLK, AUD_CTRL_CLK, VGA_CLK);
	vga: vga_controller PORT MAP (DLY_RST,
								 VGA_CLK,
								 VGA_BLANK,
								 VGA_HS,
								 VGA_VS,
								 VGA_B(7 DOWNTO 0),
								 VGA_G(7 DOWNTO 0),
								 VGA_R(7 DOWNTO 0),
								 vga_data,
								 vga_addr,
								 NOT clock,
								 block_wren,
								 score_write_data,
								 score_write_en);
	
	VGA_CLK2 <= VGA_CLK;
	ran_number: random_number PORT MAP (inclock, random_data);
END Structure;