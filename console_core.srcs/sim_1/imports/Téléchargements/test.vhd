library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity test is
end test; 

architecture Behavioral of test is

component console_core is
  port(reset            : in std_logic;
     clk_100MHz       : in std_logic;
     
     -- AXI CTRL Registers
     cursor_enabled   : in std_logic;                     -- 0 : disabled, 1 : enabled
     cursor_x         : in std_logic_vector(6 downto 0);  -- range 0 to 79 
     cursor_y         : in std_logic_vector(5 downto 0);  -- range 0 to 59
     
     default_color_en : in std_logic;                     -- 0 : disabled, 1 : enabled
     background_color : in std_logic_vector(11 downto 0);  -- default color
     foreground_color : in std_logic_vector(11 downto 0);  -- default color     
     
     end_of_display   : out std_logic;   -- 1 : end of screen  0 : display pixel
     
     -- AXI SCREEN memory
     screen_we        : in std_logic_vector(0 downto 0);
     screen_addr      : in std_logic_vector(12 DOWNTO 0);
     screen_data_in   : in std_logic_vector(31 DOWNTO 0); 
     screen_data_out  : out std_logic_vector(31 DOWNTO 0);        
     
     -- VGA signals
     VGA_HS           : out std_logic;
     VGA_VS           : out std_logic;
     VGA_R            : out std_logic_vector(3 downto 0);
     VGA_G            : out std_logic_vector(3 downto 0);
     VGA_B            : out std_logic_vector(3 downto 0));
end component;

signal clk_100MHz, reset    :  std_logic := '1';

-- AXI CTRL Registers
signal cursor_enabled   : std_logic;                     -- 0 : disabled, 1 : enabled
signal cursor_x         : std_logic_vector(6 downto 0);  -- range 0 to 79 
signal cursor_y         : std_logic_vector(5 downto 0);  -- range 0 to 59

signal default_color_en : std_logic;                     -- 0 : disabled, 1 : enabled
signal background_color : std_logic_vector(11 downto 0);  -- default color
signal foreground_color : std_logic_vector(11 downto 0);  -- default color 

signal end_of_display   : std_logic;    
     
-- AXI SCREEN memory
signal screen_we        : std_logic_vector(0 downto 0);
signal screen_addr      : std_logic_vector(12 DOWNTO 0);
signal screen_data_in   : std_logic_vector(31 DOWNTO 0);   
signal screen_data_out  : std_logic_vector(31 DOWNTO 0);	 
	 
-- VGA signals
signal VGA_HS, VGA_VS         :  std_logic;
signal VGA_R, VGA_G, VGA_B  :  std_logic_vector(3 downto 0);

begin

clk_100MHz <= not clk_100MHz after 5 ns;

reset <= '1', '0' after 35 ns;

p0: process
begin

    cursor_enabled <= '1';
    cursor_x <= (others => '0');
    cursor_y <= (others => '0');
    
    default_color_en <= '1';
    background_color <= x"000";
    foreground_color <= x"FFF";
    
    -- Init
    screen_we <= "0";
    screen_addr <= (others => '0');
    screen_data_in <= (others => '0');
    
    wait for 50 ns;
    
    -- Ecriture du caractere B à l'adresse 3
    wait until clk_100MHz'event and clk_100MHz = '1';
    wait for 100 ps;
    screen_we <= "1";
    screen_addr <= "0" & x"003";
    screen_data_in <= x"00000042";   
    
    -- Ecriture du caractere C à l'adresse 3
    wait until clk_100MHz'event and clk_100MHz = '1';
    wait for 100 ps;
    screen_we <= "1";
    screen_addr <= "0" & x"003";
    screen_data_in <= x"00000043";
    
    wait for 100 ns;
    
    -- Lecture de l'adresse 3 (qui doit contenir C)
    wait until clk_100MHz'event and clk_100MHz = '1';
    wait for 100 ps;
    screen_we <= "0";
    screen_addr <= "0" & x"003";
    screen_data_in <= (others => 'X');  
    
      
    -- end scenario
    wait;

end process p0;

u0: console_core port map (clk_100MHz => clk_100MHz, 
                        reset => reset,
                        cursor_enabled => cursor_enabled,
                        cursor_x => cursor_x,
                        cursor_y => cursor_y,
                        default_color_en => default_color_en,
                        background_color => background_color,
                        foreground_color => foreground_color,
                        end_of_display => end_of_display,
                        screen_we => screen_we,
                        screen_addr => screen_addr,
                        screen_data_in => screen_data_in,
                        screen_data_out => screen_data_out,
                        VGA_HS => VGA_HS,
                        VGA_VS => VGA_VS,
                        VGA_R => VGA_R,
                        VGA_G => VGA_G,
                        VGA_B => VGA_B);

end Behavioral;
