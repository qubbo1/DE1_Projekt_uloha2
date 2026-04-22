-- =============================================================================
-- square_wave_gen.vhd
-- Generátor obdĺžnikového signálu pre Nexys A7-50T (100 MHz clock)
--
-- Výstup wave_out (8-bit) je zdieľané rozhranie so zvyškom skupiny:
--   phase = '1'  →  wave_out = 0xFF (amplitúda = max)
--   phase = '0'  →  wave_out = 0x00 (amplitúda = min)
--
-- freq_sel | Frekvencia
-- ---------+-----------
--   "000"  |     1 Hz
--   "001"  |     2 Hz
--   "010"  |     5 Hz
--   "011"  |    10 Hz
--   "100"  |   100 Hz
--   "101"  |   1 kHz
--   "110"  |  10 kHz
--   "111"  | 100 kHz
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity square_wave_gen is
  port (
    clk      : in  std_logic;                    -- 100 MHz systémový hodinový signál
    rst      : in  std_logic;                    -- synchrónny reset, aktívny HIGH
    freq_sel : in  std_logic_vector(2 downto 0); -- výber frekvencie (8 predvolieb)
    wave_out : out std_logic_vector(7 downto 0); -- 8-bit amplitúda (zdieľané rozhranie)
    wave_raw : out std_logic                     -- 1-bit obdĺžnikový signál pre LED
  );
end entity square_wave_gen;

architecture rtl of square_wave_gen is

  -- Pol-periódy v cykloch hodinového signálu pre 100 MHz
  -- f = 100_000_000 / (2 * HALF_PERIOD)
  type half_period_lut_t is array (0 to 7) of natural;
  constant HALF_PERIOD_LUT : half_period_lut_t := (
    50_000_000,  -- "000" →    1 Hz
    25_000_000,  -- "001" →    2 Hz
    10_000_000,  -- "010" →    5 Hz
     5_000_000,  -- "011" →   10 Hz
       500_000,  -- "100" →  100 Hz
        50_000,  -- "101" →    1 kHz
         5_000,  -- "110" →   10 kHz
           500   -- "111" →  100 kHz
  );

  signal half_period : natural;
  signal cnt         : natural range 0 to 50_000_000 := 0;
  signal phase       : std_logic := '0';

begin

  half_period <= HALF_PERIOD_LUT(to_integer(unsigned(freq_sel)));

  p_square : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt   <= 0;
        phase <= '0';
      else
        if cnt >= half_period - 1 then
          cnt   <= 0;
          phase <= not phase;
        else
          cnt <= cnt + 1;
        end if;
      end if;
    end if;
  end process p_square;

  -- Výstupy
  wave_raw <= phase;
  wave_out <= (others => '1') when phase = '1' else (others => '0');

end architecture rtl;
