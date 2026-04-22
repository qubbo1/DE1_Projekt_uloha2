-- =============================================================================
-- tb_top.vhd
-- Testbench pre wavegen_top
-- Simuluje: reset, zmenu frekvencie cez BTNU (SW0=1), zmenu tvaru cez BTNR (SW1=1)
-- Odporúčaný čas simulácie: > 5 ms (krok 10 ns pri 100 MHz)
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top is
end entity tb_top;

architecture sim of tb_top is

  constant CLK_T : time := 10 ns;  -- 100 MHz

  signal clk     : std_logic := '0';
  signal btnc    : std_logic := '0';
  signal btnu    : std_logic := '0';
  signal btnd    : std_logic := '0';
  signal btnl    : std_logic := '0';
  signal btnr    : std_logic := '0';
  signal sw      : std_logic_vector(15 downto 0) := (others => '0');
  signal led     : std_logic_vector(15 downto 0);
  signal seg     : std_logic_vector(6 downto 0);
  signal dp      : std_logic;
  signal an      : std_logic_vector(7 downto 0);
  signal aud_pwm : std_logic;
  signal aud_sd  : std_logic;
  signal ja      : std_logic_vector(7 downto 0);

  component top is
    port (
      CLK100MHZ : in  std_logic;
      BTNC : in  std_logic; BTNU : in  std_logic;
      BTND : in  std_logic; BTNL : in  std_logic; BTNR : in std_logic;
      SW   : in  std_logic_vector(15 downto 0);
      LED  : out std_logic_vector(15 downto 0);
      SEG  : out std_logic_vector(6 downto 0);
      DP   : out std_logic; AN   : out std_logic_vector(7 downto 0);
      AUD_PWM : out std_logic; AUD_SD : out std_logic;
      JA   : out std_logic_vector(7 downto 0)
    );
  end component;

  -- Simulovaný stisk tlačidla (trvá 5 ms = 500 000 cyklov → debounce = 4 × 200 000 = 800 000)
  -- Pre rýchlejšiu simuláciu skrátíme na 10 cyklov (debounce C_MAX=2 pre sim)
  constant BTN_HOLD : time := 100 ns;  -- 10 cyklov

  procedure press_btn(signal btn : out std_logic) is
  begin
    btn <= '1';
    wait for BTN_HOLD;
    btn <= '0';
    wait for BTN_HOLD;
  end procedure;

begin

  clk <= not clk after CLK_T / 2;

  uut : top
    port map (
      CLK100MHZ => clk, BTNC => btnc,
      BTNU => btnu, BTND => btnd, BTNL => btnl, BTNR => btnr,
      SW => sw, LED => led,
      SEG => seg, DP => dp, AN => an,
      AUD_PWM => aud_pwm, AUD_SD => aud_sd, JA => ja
    );

  p_stim : process
  begin
    -- =====================================================================
    -- 1. Reset
    -- =====================================================================
    btnc <= '1';
    wait for 10 * CLK_T;
    btnc <= '0';
    wait for 10 * CLK_T;
    report "INFO: Reset dokoncený. freq=1Hz, wave=SQr" severity note;

    -- =====================================================================
    -- 2. Povolenie AUX výstupu (SW2=1)
    -- =====================================================================
    sw(2) <= '1';
    wait for 5 * CLK_T;
    assert aud_sd = '1' report "CHYBA: AUD_SD malo byť '1'" severity error;
    report "INFO: AUX povolený (SW2=1)" severity note;

    -- =====================================================================
    -- 3. Zmena frekvencie: SW0=1, stlač BTNU 3×  → 1Hz→2Hz→5Hz→10Hz
    -- =====================================================================
    sw(0) <= '1';
    wait for 5 * CLK_T;
    press_btn(btnu);
    press_btn(btnu);
    press_btn(btnu);
    sw(0) <= '0';
    report "INFO: Frekvencia zmenená 3x nahor (ocakávaná = 10 Hz)" severity note;

    -- =====================================================================
    -- 4. Zmena vlnového tvaru: SW1=1, stlač BTNR 2×  → SQr→SIn→SAu
    -- =====================================================================
    sw(1) <= '1';
    wait for 5 * CLK_T;
    press_btn(btnr);
    press_btn(btnr);
    sw(1) <= '0';
    report "INFO: Tvar zmenený 2x doprava (ocakávaný = SAu/sawtooth)" severity note;

    -- =====================================================================
    -- 5. Nechaj bežať 500 cyklov, skontroluj LED
    -- =====================================================================
    wait for 500 * CLK_T;
    assert led(2) = '1'  report "CHYBA: LED(2) malo byť '1' (AUX aktívny)" severity error;
    assert aud_sd = '1'  report "CHYBA: AUD_SD malo byť '1'" severity error;
    report "INFO: Simulácia úspesne dokoncená" severity note;

    wait;
  end process p_stim;

end architecture sim;
