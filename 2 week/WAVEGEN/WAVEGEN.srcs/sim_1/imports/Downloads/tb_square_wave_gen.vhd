-- =============================================================================
-- tb_square_wave_gen.vhd
-- Testbench pre square_wave_gen
--
-- Simuluje generátor pri 100 kHz (freq_sel="111", pol-perióda = 500 cyklov).
-- Overuje:
--   1. Reset → wave_raw = '0', wave_out = 0x00
--   2. Po reléze resetu: wave_raw sa prepína každých 500 cyklov
--   3. Zmena freq_sel za behu: generator sa adaptuje
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_square_wave_gen is
end entity tb_square_wave_gen;

architecture sim of tb_square_wave_gen is

  -- Hodinový signál: 100 MHz → perióda 10 ns
  constant CLK_PERIOD : time := 10 ns;

  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';
  signal freq_sel : std_logic_vector(2 downto 0) := "111";  -- 100 kHz (pol-perióda 500 cyklov)
  signal wave_out : std_logic_vector(7 downto 0);
  signal wave_raw : std_logic;

  -- Komponent (UUT)
  component square_wave_gen is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      freq_sel : in  std_logic_vector(2 downto 0);
      wave_out : out std_logic_vector(7 downto 0);
      wave_raw : out std_logic
    );
  end component;

begin

  -- Generátor hodinového signálu
  p_clk : process
  begin
    clk <= '0'; wait for CLK_PERIOD / 2;
    clk <= '1'; wait for CLK_PERIOD / 2;
  end process p_clk;

  -- UUT inštancia
  uut : square_wave_gen
    port map (
      clk      => clk,
      rst      => rst,
      freq_sel => freq_sel,
      wave_out => wave_out,
      wave_raw => wave_raw
    );

  -- Stimuly
  p_stim : process
  begin
    -- =======================================================
    -- TEST 1: Reset
    -- =======================================================
    rst <= '1';
    wait for 5 * CLK_PERIOD;
    assert wave_raw = '0'
      report "CHYBA: wave_raw malo byt '0' pocas resetu" severity error;
    assert wave_out = x"00"
      report "CHYBA: wave_out malo byt 0x00 pocas resetu" severity error;

    -- =======================================================
    -- TEST 2: Uvoľniť reset, sledovať 100 kHz výstup
    --         pol-perióda = 500 cyklov → 2 pol-periódy = 1000 cyklov = 1 perióda
    -- =======================================================
    rst <= '0';
    wait for CLK_PERIOD;  -- 1 cyklus settle

    -- Čakáme na prvú nástupnú hranu wave_raw
    wait until rising_edge(wave_raw);
    report "INFO: Prvá nástupná hrana wave_raw detegovaná" severity note;
    assert wave_out = x"FF"
      report "CHYBA: wave_out malo byt 0xFF ked wave_raw='1'" severity error;

    -- Čakáme na zostupnú hranu
    wait until falling_edge(wave_raw);
    report "INFO: Zostupná hrana wave_raw detegovaná" severity note;
    assert wave_out = x"00"
      report "CHYBA: wave_out malo byt 0x00 ked wave_raw='0'" severity error;

    -- Overíme 2 kompletné periódy
    for i in 1 to 4 loop
      wait until wave_raw'event;
      report "INFO: Prechod c. " & integer'image(i) & " detegovany" severity note;
    end loop;

    -- =======================================================
    -- TEST 3: Zmena frekvencie za behu → 10 kHz (pol-perióda = 5000 cyklov)
    -- =======================================================
    freq_sel <= "110";
    wait for 2 * CLK_PERIOD;
    report "INFO: Prepnutie na 10 kHz (freq_sel=110)" severity note;

    wait until rising_edge(wave_raw);
    wait until falling_edge(wave_raw);
    report "INFO: 10 kHz perióda overená" severity note;

    -- =======================================================
    -- TEST 4: Reset znova
    -- =======================================================
    rst <= '1';
    wait for 3 * CLK_PERIOD;
    assert wave_raw = '0'
      report "CHYBA: wave_raw malo byť '0' po druhom reséte" severity error;
    rst <= '0';

    -- Koniec simulácie
    wait for 100 * CLK_PERIOD;
    report "INFO: Vsetky testy uspesne dokoncene" severity note;
    wait;
  end process p_stim;

end architecture sim;
