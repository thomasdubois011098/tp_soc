
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.font.all;


entity search_car is
  port(
       line_number  : in std_logic_vector(2 downto 0);  -- 0 à 7 (8 pixels verticales de hauteur)
       pixel_number : in std_logic_vector(2 downto 0);  -- 0 à 7 (pixels horizontals)
       car          : in std_logic_vector(7 downto 0);  -- car de 32 à 96 (0 .. 64)
       foreground   : in std_logic_vector(11 downto 0);
       background   : in std_logic_vector(11 downto 0);
       pixel        : out std_logic_vector(11 downto 0) -- pixel courante à afficher
       );
end search_car;


architecture synth of search_car is

signal car_tmp : std_logic_vector(7 downto 0);
signal addr : std_logic_vector(8 downto 0);
signal value : std_logic_vector(7 downto 0);

signal col0        : std_logic_vector(11 downto 0);
signal col1        : std_logic_vector(11 downto 0);
signal col2        : std_logic_vector(11 downto 0);
signal col3        : std_logic_vector(11 downto 0);
signal col4        : std_logic_vector(11 downto 0);
signal col5        : std_logic_vector(11 downto 0);
signal col6        : std_logic_vector(11 downto 0);
signal col7        : std_logic_vector(11 downto 0);

begin

car_tmp <= car - 32 when car > "00011111" and car < "01100001" else "00000000";  -- default : car = "!"  (31, 97)
addr <= (car_tmp(5 downto 0) & "000") + line_number;
value <= font_array(to_integer(unsigned(addr)));

col0 <= foreground when value(0) = '1' else background;
col1 <= foreground when value(1) = '1' else background;
col2 <= foreground when value(2) = '1' else background;
col3 <= foreground when value(3) = '1' else background;
col4 <= foreground when value(4) = '1' else background;
col5 <= foreground when value(5) = '1' else background;
col6 <= foreground when value(6) = '1' else background;
col7 <= foreground when value(7) = '1' else background;

pixel <= col7 when pixel_number = "000" else
         col6 when pixel_number = "001" else
         col5 when pixel_number = "010" else
         col4 when pixel_number = "011" else
         col3 when pixel_number = "100" else
         col2 when pixel_number = "101" else
         col1 when pixel_number = "110" else
         col0;

end synth;                  
                                    