-- =============================================================================
-- wave_mux.vhd
-- 4-vstupný 8-bit MUX výberu vlnového tvaru
--
-- wave_sel | Výstup
-- ---------+-----------
--   "00"   | Obdĺžnik  (Square)
--   "01"   | Sínus     (Sine)
--   "10"   | Pílový    (Sawtooth)
--   "11"   | Trojuholník (Triangle)
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity wave_mux is
  port (
    wave_sq  : in  std_logic_vector(7 downto 0); -- obdĺžnik
    wave_sin : in  std_logic_vector(7 downto 0); -- sínus
    wave_saw : in  std_logic_vector(7 downto 0); -- pílový
    wave_tri : in  std_logic_vector(7 downto 0); -- trojuholník
    wave_sel : in  std_logic_vector(1 downto 0); -- výber
    wave_out : out std_logic_vector(7 downto 0)  -- vybraný signál
  );
end entity wave_mux;

architecture rtl of wave_mux is
begin

  with wave_sel select wave_out <=
    wave_sq  when "00",
    wave_sin when "01",
    wave_saw when "10",
    wave_tri when "11",
    wave_sq  when others;

end architecture rtl;
