library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity console_core is
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
end console_core;


architecture synth of console_core is

component screen_memory is
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END component;

component search_car is
  port(
      line_number  : in std_logic_vector(2 downto 0);  -- 0 � 7 (8 pixels verticales de hauteur)
      pixel_number : in std_logic_vector(2 downto 0);  -- 0 � 7 (pixels horizontals)
      car          : in std_logic_vector(7 downto 0);  -- car de 32 � 96 (0 .. 64)
      foreground   : in std_logic_vector(11 downto 0);
      background   : in std_logic_vector(11 downto 0);
      pixel        : out std_logic_vector(11 downto 0) -- pixel courante � afficher
       );
end component;

-- VGA signal generation ----------------------------------------- 
signal clk_25MHz : std_logic;
signal videoon, videov, videoh : std_logic;
signal hcount, vcount          : std_logic_vector(9 downto 0);
signal row                   : std_logic_vector(8 downto 0);
signal column                : std_logic_vector(9 downto 0);

-- Search Caracters -----------------------------------------
signal line_number, line_number_nxt  :  std_logic_vector(2 downto 0);  
signal pixel_number, pixel_number_nxt :  std_logic_vector(2 downto 0);  
signal car          :  std_logic_vector(7 downto 0);  
signal foreground, foreground_tmp   :  std_logic_vector(11 downto 0);
signal background, background_tmp   :  std_logic_vector(11 downto 0);
signal pixel        :  std_logic_vector(11 downto 0);

-- Screen Memory ----------------------------------
signal clka, ena, clkb, enb : STD_LOGIC;
signal wea, web : STD_LOGIC_VECTOR(0 downto 0);
signal addra, addrb : STD_LOGIC_VECTOR(12 downto 0);
signal dina, douta, dinb, doutb : STD_LOGIC_VECTOR(31 downto 0);

signal cursor_addr : STD_LOGIC_VECTOR(12 DOWNTO 0);
signal cursor_active_area : std_logic;

-- FSM ----------------------------------
signal cursor_blind_off : std_logic;

begin
  
-- VGA signal generation -----------------------------------------  
  
    div: process(clk_100MHz)
        variable cpt : std_logic_vector(25 downto 0) := (others => '0');
    begin
        if clk_100MHz'event and clk_100MHz = '1' then
            cpt := cpt + 1;
            clk_25MHz <= cpt(1);
            cursor_blind_off <= cpt(25);
        end if;
    end process;
  
    hcounter: process (clk_25MHz, reset)
        begin
        if reset='1' then 
            hcount <= (others => '0');
         elsif (clk_25MHz'event and clk_25MHz='1') then
            if hcount=799 then
                hcount <= (others => '0');
            else
                hcount <= hcount + 1;
            end if;
        end if;
    end process;
    
    process (hcount)
    begin
        videoh <= '1';
        column <= hcount;
        if hcount>639 then
            videoh <= '0';
            column <= (others => '0');
        end if;
    end process;    
    
    vcounter: process (clk_25MHz, reset)
    begin
        if reset='1' then
            vcount <= (others => '0');
        elsif clk_25MHz'event and clk_25MHz='1' then
            if hcount=699 then
                if vcount=524 then
                    vcount <= (others => '0');
                else
                    vcount <= vcount + 1;
                end if;
             end if;
        end if;
    end process;
    
    process (vcount)
    begin
        videov <= '1';
        row <= vcount(8 downto 0);
        if vcount>479 then
            videov <= '0';
            row <= (others => '0');
        end if;
    end process;    
         
    sync: process (clk_25MHz, reset)
    begin
        if reset='1' then
            VGA_HS <= '0';
            VGA_VS <= '0';
         elsif clk_25MHz'event and clk_25MHz='1' then
            if (hcount<=755 and hcount>=659) then
                VGA_HS <= '0';
            else
                VGA_HS <= '1';
            end if;
            
            --if (vcount<=495 and vcount>=494) then
            if vcount = 493  then
                VGA_VS <= '0';
            else 
                VGA_VS <= '1';
            end if;
        end if;
    end process;
    videoon <= videoh and videov;
                  
    colors: process (clk_25MHz, reset)
    begin
        if reset='1' then
            VGA_R <= (others => '0');
            VGA_G <= (others => '0');
            VGA_B <= (others => '0');
        elsif clk_25MHz'event and clk_25MHz='1' then
            if videoon = '0' then
                VGA_R <= (others => '0');
                VGA_G <= (others => '0');
                VGA_B <= (others => '0');            
            else
                VGA_R <= pixel(3 downto 0);
                VGA_G <= pixel(7 downto 4);   
                VGA_B <= (others => '1'); -- pixel(11 downto 8);  
            end if;
        end if;
    end process;

-- Search Characters -----------------------------------------

car <= "01000001"; -- 8 bits
line_number <= "000"; -- 8 bits
pixel_number <= "000"; -- 8 bits
foreground_tmp <= doutb(19 downto 8) when default_color_en = '0' else foreground_color;
background_tmp <= doutb(31 downto 20) when default_color_en = '0' else background_color;

foreground <= background_tmp when cursor_active_area = '1' and cursor_blind_off = '1' and cursor_enabled = '1' else foreground_tmp;
background <= foreground_tmp when cursor_active_area = '1' and cursor_blind_off = '1' and cursor_enabled = '1' else background_tmp;

u1: search_car port map(
       line_number => line_number,
       pixel_number => pixel_number,
       car => car,
       foreground => foreground,
       background => background,
       pixel => pixel);

-- Screen Memory ----------------------------------
ena <= '1';
enb <='1';
web <="0";
dinb <="0";

u2: screen_memory port map(
        clka=>clk_100MHz,
        clkb=>clk_100MHz,
        ena => ena,
        enb => enb,
        web => web,
        dinb => dinb,
        wea => screen_we,
        addra => screen_addr,
        addrb => screen_addr,
        dina => screen_data_in,
        douta => screen_data_out,
        doutb => screen_data_out);

cursor_addr <= CONV_STD_LOGIC_VECTOR(CONV_INTEGER(cursor_y) * 80, 13) + cursor_x;
cursor_active_area <= '1' when cursor_addr = addrb else '0';

-- FSM ----------------------------------



end synth;                  
                                    