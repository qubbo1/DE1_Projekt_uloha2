-- =============================================================================
-- seg7_ctrl.vhd
-- Ovládač 8-miestneho 7-segmentového displeja pre Nexys A7-50T
--
-- Vstup: disp_data(63:0) – 8 bajtov, každý bajt = jeden znak
--   Bajt formát: bit[7]    = desatinná bodka (1=zapnutá)
--                bit[6:0]  = segmentový vzor {CG,CF,CE,CD,CC,CB,CA} (aktívne LOW, 0=zapnutý)
--
--   Bajt 0 (disp_data[7:0])   = AN0 – najprávejšia cifra
--   Bajt 7 (disp_data[63:56]) = AN7 – najľavejšia cifra
--
-- Obnova: ~100 Hz/cifru → rámec 12.5 Hz (neviditeľné blikanie)
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7_ctrl is
  port (
    clk       : in  std_logic;                    -- 100 MHz
    rst       : in  std_logic;
    disp_data : in  std_logic_vector(63 downto 0);-- 8 × bajt (viď popis vyššie)
    seg       : out std_logic_vector(6 downto 0); -- {CG,CF,CE,CD,CC,CB,CA} aktívne LOW
    dp        : out std_logic;                     -- desatinná bodka, aktívna LOW
    an        : out std_logic_vector(7 downto 0)  -- anódy, aktívne LOW
  );
end entity seg7_ctrl;

architecture rtl of seg7_ctrl is

  -- 1 ms na cifru = 100 000 cyklov pri 100 MHz
  constant REFRESH_CYCLES : natural := 100_000;

  signal ref_cnt   : natural range 0 to REFRESH_CYCLES - 1 := 0;
  signal digit_sel : unsigned(2 downto 0) := (others => '0');
  signal cur_byte  : std_logic_vector(7 downto 0);

  -- Pomocná funkcia: vyber bajt podľa indexu z 64-bitového vektora
  type byte_array_t is array(0 to 7) of std_logic_vector(7 downto 0);
  signal digits : byte_array_t;

begin

  -- Rozbalenie 64-bit vektora na pole 8 bajtov
  G_UNPACK : for i in 0 to 7 generate
    digits(i) <= disp_data(i*8+7 downto i*8);
  end generate;

  -- Aktuálny bajt podľa vybranej pozície
  cur_byte <= digits(to_integer(digit_sel));

  -- Počítadlo obnovy a prepínanie cifernej pozície
  p_refresh : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        ref_cnt   <= 0;
        digit_sel <= (others => '0');
      else
        if ref_cnt = REFRESH_CYCLES - 1 then
          ref_cnt   <= 0;
          digit_sel <= digit_sel + 1;
        else
          ref_cnt <= ref_cnt + 1;
        end if;
      end if;
    end if;
  end process p_refresh;

  -- Výstupy
  seg <= cur_byte(6 downto 0);      -- segmenty sú už aktívne LOW
  dp  <= not cur_byte(7);            -- bit7=1 → DP zapnutá → výstup LOW

  -- Dekodér anód (iba jedna aktívna = LOW)
  p_anode : process(digit_sel)
  begin
    an <= (others => '1');
    an(to_integer(digit_sel)) <= '0';
  end process p_anode;

end architecture rtl;
