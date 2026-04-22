-- =============================================================================
-- triangle_gen.vhd                                         [STUDENT: doplniť]
-- Generátor TROJUHOLNÍKOVÉHO signálu
--
-- Logika odvodená z fázy:
--   phase(7) = '0'  →  výstup = phase(6:0) & '0'       (0→254, stúpa)
--   phase(7) = '1'  →  výstup = NOT phase(6:0) & '0'   (254→0, klesá)
--
-- Príklad:
--   phase=0   → 0b0_0000000 & '0' = 0x00
--   phase=64  → 0b1_000000 & '0'  = 0x80
--   phase=127 → 0b1_111111 & '0'  = 0xFE  (maximum)
--   phase=128 → NOT(0b0_000000) & '0' = 0xFF & '0' = 0xFE (stále maximum)
--   phase=192 → NOT(0b1_000000) & '0' = 0x7F & '0' = 0x7E
--   phase=255 → NOT(0b1_111111) & '0' = 0x00
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity triangle_gen is
  port (
    phase    : in  std_logic_vector(7 downto 0);
    wave_out : out std_logic_vector(7 downto 0)
  );
end entity triangle_gen;

architecture rtl of triangle_gen is
  signal lower7 : std_logic_vector(6 downto 0);
begin

  lower7 <= phase(6 downto 0);

  wave_out <= lower7 & '0'       when phase(7) = '0'
         else (not lower7) & '0';

end architecture rtl;
