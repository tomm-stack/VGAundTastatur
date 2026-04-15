library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity vga_gen is
    generic(
    -- VGA 1920x1080 sync parameters 50MHz Clock 3.5 pixels at once -> 548 x 1080 bad ok
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
end vga_gen;
architecture Behavioral of vga_gen is
    -- 50 MHz Clock input
    -- sync counters
    signal v_count: std_logic_vector(11 downto 0);
    signal h_count: std_logic_vector(11 downto 0);
begin
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            v_count <= (others => '0');
            h_count <= (others => '0');
        elsif clk'event and clk = '0' then
            if (h_count < (HD + HF + HB + HR)) then
                h_count <= h_count+1;
            else
                h_count <= (others => '0');
            end if;
            if (h_count = (HD + HF -1)) then
                if (v_count < (VD + VF + VB + VR)) then
                    v_count <= v_count +1;
                else
                    v_count <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    -- horizontal and vertical sync
    hsync <= '0' when (h_count >= (HD + HF)) and
                      (h_count <= (HD + HF + HR - 1)) else
             '1';
    vsync <= '1' when (v_count > (VD + VF)) and
                      (v_count <= (VD + VF + VR)) else
             '0';
    -- video on/off
    video_on <= '1' when (h_count < HD) and (v_count < VD) else '0';
    -- output signal
    pixel_x <= h_count;
    pixel_y <= v_count;
    p_tick <= clk;
end Behavioral;