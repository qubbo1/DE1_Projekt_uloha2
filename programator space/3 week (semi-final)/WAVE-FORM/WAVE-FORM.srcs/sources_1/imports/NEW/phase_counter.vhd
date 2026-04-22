-- =============================================================================
-- phase_counter.vhd
-- DDS fázový akumulátor – priame digitálne syntézovanie (Direct Digital Synthesis)
--
-- Vstup:  freq_val (14-bit) = požadovaná frekvencia v Hz, rozsah 0–9999
-- Výstup: phase   (8-bit)  = aktuálna fáza 0–255
--
-- Princíp:
--   Každý hodinový cyklus (100 MHz) sa k 32-bitovému akumulátoru pripočíta
--   hodnota  incr = freq_val * 43.
--   Fázový výstup = akumulátor[31:24]  (horných 8 bitov).
--
-- Výpočet presnosti:
--   f_out = incr * f_clk / 2^32
--         = freq_val * 43 * 100_000_000 / 4_294_967_296
--         ≈ freq_val * 1.00117 Hz    (chyba < 0.12 %)
--
-- Príklady:
--   freq_val =    1  →  incr =       43  →  f_out ≈   1.00 Hz
--   freq_val =  100  →  incr =    4 300  →  f_out ≈ 100.1 Hz
--   freq_val =  440  →  incr =   18 920  →  f_out ≈ 440.5 Hz  (hudobné A)
--   freq_val = 9999  →  incr =  429 957  →  f_out ≈ 10 012 Hz
--   freq_val =    0  →  incr =        0  →  fáza stojí (DC výstup)
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_counter is
  port (
    clk      : in  std_logic;                     -- 100 MHz
    rst      : in  std_logic;                     -- synchrónny reset
    freq_val : in  std_logic_vector(13 downto 0); -- 0–9999 Hz
    phase    : out std_logic_vector(7 downto 0)   -- DDS fáza 0–255
  );
end entity phase_counter;

architecture rtl of phase_counter is

  -- 32-bitový DDS akumulátor
  signal accum : unsigned(31 downto 0) := (others => '0');

  -- Prírastkový krok: freq_val (14 b) * 43 (6 b) = 20 b
  -- max: 9999 * 43 = 429 957 < 2^20 = 1 048 576  ✓
  signal incr : unsigned(19 downto 0);

begin

  -- Kombinačný výpočet kroku (syntetizuje sa ako násobička v DSP bloku)
  incr <= unsigned(freq_val) * to_unsigned(43, 6);

  -- DDS akumulátor – inkrementuje každý hodinový cyklus
  p_dds : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        accum <= (others => '0');
      else
        accum <= accum + resize(incr, 32);
      end if;
    end if;
  end process p_dds;

  -- Fázový výstup = horných 8 bitov akumulátora
  phase <= std_logic_vector(accum(31 downto 24));

end architecture rtl;
