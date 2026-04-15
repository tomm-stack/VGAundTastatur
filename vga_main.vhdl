library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity vga_Main is
    port(
        clk, not_reset: in std_logic;
        sw:std_logic_vector(3 downto 2);
        hsync, vsync: out std_logic;
        vgaRed: out std_logic_vector(2 downto 0);
        vgaGreen: out std_logic_vector(2 downto 0);
        vgaBlue: out std_logic_vector(2 downto 1);
        led: out std_logic_vector(7 downto 0)
        );
end vga_Main;
architecture Behavioral of vga_Main is
 -- sw(7) not_reset should be '1' for normal operation
 -- sw(3,2) "11" 1024x768 otherwise 800x600
	COMPONENT CLK_Manager
	PORT(
		CLK_IN1 : IN std_logic;
		RESET : IN std_logic;          
		CLK_OUT1 : OUT std_logic;
		LOCKED : OUT std_logic
		);
	END COMPONENT;
    COMPONENT vga_gen
    generic(
	    HD: integer := 548; -- horizontal display area 640;  800
        HF: integer := 34;  -- h. front porch          (8) 16;     40
        HB: integer := 93;  -- h. back porch           (56) 48;    88 
        HR: integer := 59;  -- h. retrace              96;    128
	    -- VD+VF+VB+VR-1 -> 1087
        VD: integer := 1080; -- vertical display area   480;   600
        VF: integer := 1;  -- v. front porch          (2) 11;    4
        VB: integer := 32;  -- v. back porch           (41) 31;    23
        VR: integer := 3   -- v. retrace               (2) 2;    1
	 );
    port(
        clk, not_reset: in std_logic;
        hsync, vsync: out std_logic;
        video_on, p_tick: out std_logic;
        pixel_x, pixel_y: out std_logic_vector (11 downto 0)
    );
    END COMPONENT;
    signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
    signal video_on,video_on0,video_on2: std_logic;
    signal px_x, px_y,px_x0, px_y0,px_x2, px_y2: std_logic_vector(11 downto 0);
    signal hsync0,vsync0,hsync2,vsync2: std_logic;
    signal clkx:std_logic;
    signal en,reset, p_tick,p_tick0, p_tick2: std_logic;
    signal sbtn: std_logic_vector(3 downto 0);
    signal graph_rgb: std_logic_vector(7 downto 0);
begin
	 reset<=not(not_reset);
    
	 led(7) <= not_reset;
	 led(6) <= px_y(6);
	 led(5) <= px_y(5);
	 led(4) <= reset;
	 led(3) <= p_tick;
	 led(2) <= video_on;
	 led(1) <= px_x(8);
	 led(0) <= px_x(8);
	 
	vgaRed <=graph_rgb(7 downto 5);
	vgaGreen <=graph_rgb(4 downto 2);
	vgaBlue <=graph_rgb(1 downto 0);
        
	vga0:
        vga_gen
        generic map(
		    HD => 681, HF => 16, HB=> 96, HR=> 90,  -- (1024) 681x 768 70Hz
		    VD=> 768, VF=> 3, VB=> 29, VR=> 6   
		  )
        port map(
            clk => clkx, not_reset => not_reset,
            hsync => hsync0, vsync => vsync0,
            video_on => video_on0, p_tick => p_tick0,
            pixel_x => px_x0, pixel_y => px_y0
        );
	vga2:
        vga_gen
        generic map(
		    HD => 800, HF => 56, HB=> 64, HR=> 120,  -- 800x600
		    VD=> 600, VF=> 37, VB=> 23, VR=> 6   
		)
        port map(
            clk => clkx, not_reset => not_reset,
            hsync => hsync2, vsync => vsync2,
            video_on => video_on2, p_tick => p_tick2,
            pixel_x => px_x2, pixel_y => px_y2
        );
   ----------------------------------------------
   -- Clock to pixel frequency with Clocking Wizard
   ----------------------------------------------
	Inst_CLK_y: CLK_Manager PORT MAP(
		CLK_IN1 => clk,
		CLK_OUT1 => clkx,
		RESET => reset,
		LOCKED => locked 
	);
	-- Alternative 1) Fixed external clock
	-- clkx <= clk;
	-- Alternative 2) Half external clock
    -- process(clk, not_reset) --- NEXYS3 100MHz transfers clk to 50MHz clkx
    -- begin
	--   if not_reset = '0' then
	--      clkx <='0';
	-- 	 elsif clk'event and clk='1' then -- generate clkx 50 MHz from clk 100MHz NEXYS3 board
	--	    clkx <= not(clkx);
    --   end if;
    -- end process;
	
   ----------------------------------------------
   -- signal multiplexing circuit
   ----------------------------------------------
  	hsync <= hsync0 when sw(3 downto 2)="11" else
           hsync2;
  	vsync <= vsync0 when sw(3 downto 2)="11" else
           vsync2;				
  	video_on <= video_on0 when sw(3 downto 2)="11" else
           video_on2;
  	p_tick <= p_tick0 when sw(3 downto 2)="11" else
           p_tick2;
  	px_x <= px_x0 when sw(3 downto 2)="11" else
           px_x2;
  	px_x <= px_x0 when sw(3 downto 2)="11" else
           px_x2;
	px_y <= px_y0 when sw(3 downto 2)="11" else
           px_y2;
   ----------------------------------------------
   -- rgb multiplexing circuit
   ----------------------------------------------
   process(video_on,px_x,px_y)
   begin
      if video_on='0' then
          graph_rgb <= "00000000"; --blank
      else
         if (px_x(4 downto 0) = px_y(4 downto 0)) or (px_x(4 downto 0) = not(px_y(4 downto 0)) ) then
            graph_rgb <= "00000011"; -- blue lines
         else
            graph_rgb <= "11111111";-- white background
         end if;
      end if;
   end process;
end Behavioral;