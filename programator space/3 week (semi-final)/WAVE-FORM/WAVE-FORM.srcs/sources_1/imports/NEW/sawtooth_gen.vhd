-- =============================================================================
-- sawtooth_gen.vhd                                         [STUDENT: doplniť]
-- Generátor PÍLOVÉHO signálu
--
-- Logika: výstup = fáza priamo (0 → 255 lineárne rastúci)
-- Stúpajúci pílový priebeh.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity sawtooth_gen is
  port (
    phase    : in  std_logic_vector(7 downto 0);
    wave_out : out std_logic_vector(7 downto 0)
  );
end entity sawtooth_gen;

architecture rtl of sawtooth_gen is
begin

  -- Sawtooth = priamy výstup fázového čítača
  wave_out <= phase;

end architecture rtl;
