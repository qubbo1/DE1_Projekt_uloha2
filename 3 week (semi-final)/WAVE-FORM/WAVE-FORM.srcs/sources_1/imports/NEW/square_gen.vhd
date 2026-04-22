-- =============================================================================
-- square_gen.vhd                                              [STUDENT: qubbo1]
-- Generátor OBDĹŽNIKOVÉHO signálu
--
-- Logika:
--   phase(7) = '1'  →  wave_out = 0xFF  (horná polperióda)
--   phase(7) = '0'  →  wave_out = 0x00  (dolná polperióda)
-- Výsledok: symetrický obdĺžnik s duty cycle 50%.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity square_gen is
  port (
    phase    : in  std_logic_vector(7 downto 0); -- fázový vstup od phase_counter
    wave_out : out std_logic_vector(7 downto 0)  -- 8-bit amplitúda
  );
end entity square_gen;

architecture rtl of square_gen is
begin

  -- MSB fázy rozdeľuje periódu presne na polovicu
  wave_out <= x"FF" when phase(7) = '1' else x"00";

end architecture rtl;
