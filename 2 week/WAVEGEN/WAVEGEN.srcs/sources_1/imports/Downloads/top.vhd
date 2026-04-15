-- =============================================================================
-- top.vhd
-- Vrchná entita: Generátor priebehov – DE1 Projekt (úloha 2)
-- Platforma: Nexys A7-50T, 100 MHz
--
-- OVLÁDANIE:
--   SW(2:0)  – výber frekvencie (8 predvolieb, viď square_wave_gen.vhd)
--   SW(4:3)  – výber priebehov: "00"=obdĺžnik | "01"=sínus* | "10"=pílový* | "11"=trojuholník*
--              (* – doplnia ostatní členovia skupiny)
--   BTNC     – systémový reset
--
-- VÝSTUPY:
--   LED(0)   – surový 1-bit obdĺžnikový signál (viditeľné blikanie pri nízkych frekvenciách)
--   LED(2:1) – indikátor jednotky: "01"=Hz, "10"=kHz
--   LED(7:5) – indikátor vybraného priebehov (one-hot: 001=square, 010=sine, 100=saw, ...)
--   JA(0)    – PWM výstup (pripoj RC filter pre analógový signál)
--   7-seg    – zobrazenie hodnoty frekvencie v Hz
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    CLK100MHZ : in  std_logic;
    BTNC      : in  std_logic;                    -- reset (aktívny HIGH)
    SW        : in  std_logic_vector(15 downto 0);
    LED       : out std_logic_vector(15 downto 0);
    -- 7-segmentový displej
    SEG       : out std_logic_vector(6 downto 0); -- {CG,CF,CE,CD,CC,CB,CA} aktívne LOW
    DP        : out std_logic;
    AN        : out std_logic_vector(7 downto 0); -- aktívne LOW
    -- Pmod JA
    JA        : out std_logic_vector(7 downto 0)
  );
end entity top;

architecture rtl of top is

  -- -----------------------------------------------------------------------
  -- Interné signály
  -- -----------------------------------------------------------------------
  signal rst       : std_logic;
  signal freq_sel  : std_logic_vector(2 downto 0);
  signal wave_sel  : std_logic_vector(1 downto 0);

  -- Výstupy jednotlivých generátorov (8-bit amplitúda)
  signal sq_wave   : std_logic_vector(7 downto 0);
  signal sq_raw    : std_logic;

  -- TODO (ostatní členovia skupiny):
  -- signal sin_wave  : std_logic_vector(7 downto 0);
  -- signal saw_wave  : std_logic_vector(7 downto 0);
  -- signal tri_wave  : std_logic_vector(7 downto 0);

  -- MUX výstup → PWM
  signal wave_mux  : std_logic_vector(7 downto 0);
  signal pwm_sig   : std_logic;

  -- 7-segmentový displej
  signal disp_data : std_logic_vector(31 downto 0);

  -- -----------------------------------------------------------------------
  -- LUT zobrazenia frekvencie na 7-seg (8 x 4-bit cifry, 15=blank)
  -- Formát: "  xxxxxx" = hodnota v Hz (6 číslic vpravo)
  -- data(3:0)=AN0(vpravo) ... data(31:28)=AN7(vľavo)
  -- -----------------------------------------------------------------------
  type disp_lut_t is array(0 to 7) of std_logic_vector(31 downto 0);
  constant DISP_LUT : disp_lut_t := (
    x"FFFF_FF01",  -- 000 →       1 Hz  (zobraz "       1")
    x"FFFF_FF02",  -- 001 →       2 Hz
    x"FFFF_FF05",  -- 010 →       5 Hz
    x"FFFF_FF10",  -- 011 →      10 Hz  (zobraz "      10")
    x"FFFF_F100",  -- 100 →     100 Hz  (zobraz "     100")
    x"FFFF_1000",  -- 101 →    1000 Hz  (zobraz "    1000")
    x"FFF1_0000",  -- 110 →   10000 Hz  (zobraz "   10000")
    x"FF10_0000"   -- 111 →  100000 Hz  (zobraz "  100000")
  );

  -- -----------------------------------------------------------------------
  -- Component declarations
  -- -----------------------------------------------------------------------
  component square_wave_gen is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      freq_sel : in  std_logic_vector(2 downto 0);
      wave_out : out std_logic_vector(7 downto 0);
      wave_raw : out std_logic
    );
  end component;

  component pwm_gen is
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      duty    : in  std_logic_vector(7 downto 0);
      pwm_out : out std_logic
    );
  end component;

  component seg7_ctrl is
    port (
      clk   : in  std_logic;
      rst   : in  std_logic;
      data  : in  std_logic_vector(31 downto 0);
      dp_in : in  std_logic_vector(7 downto 0);
      seg   : out std_logic_vector(6 downto 0);
      dp    : out std_logic;
      an    : out std_logic_vector(7 downto 0)
    );
  end component;

begin

  -- -----------------------------------------------------------------------
  -- Mapovanie vstupov
  -- -----------------------------------------------------------------------
  rst      <= BTNC;
  freq_sel <= SW(2 downto 0);
  wave_sel <= SW(4 downto 3);

  -- -----------------------------------------------------------------------
  -- Inštancie generátorov
  -- -----------------------------------------------------------------------

  u_square : square_wave_gen
    port map (
      clk      => CLK100MHZ,
      rst      => rst,
      freq_sel => freq_sel,
      wave_out => sq_wave,
      wave_raw => sq_raw
    );

  -- TODO: Sem doplnia ostatní členovia skupiny svoje generátory:
  -- u_sine : sine_wave_gen   port map (clk => CLK100MHZ, rst => rst, freq_sel => freq_sel, wave_out => sin_wave);
  -- u_saw  : sawtooth_gen    port map (clk => CLK100MHZ, rst => rst, freq_sel => freq_sel, wave_out => saw_wave);
  -- u_tri  : triangle_gen    port map (clk => CLK100MHZ, rst => rst, freq_sel => freq_sel, wave_out => tri_wave);

  -- -----------------------------------------------------------------------
  -- MUX výberu priebehov (SW[4:3])
  -- -----------------------------------------------------------------------
  p_mux : process(wave_sel, sq_wave)
  begin
    case wave_sel is
      when "00"   => wave_mux <= sq_wave;
      -- when "01"   => wave_mux <= sin_wave;   -- TODO: sínus
      -- when "10"   => wave_mux <= saw_wave;   -- TODO: pílový
      -- when "11"   => wave_mux <= tri_wave;   -- TODO: trojuholník
      when others => wave_mux <= sq_wave;    -- fallback: obdĺžnik
    end case;
  end process p_mux;

  -- -----------------------------------------------------------------------
  -- PWM generátor
  -- -----------------------------------------------------------------------
  u_pwm : pwm_gen
    port map (
      clk     => CLK100MHZ,
      rst     => rst,
      duty    => wave_mux,
      pwm_out => pwm_sig
    );

  -- -----------------------------------------------------------------------
  -- 7-segmentový displej – zobrazenie frekvencie
  -- -----------------------------------------------------------------------
  disp_data <= DISP_LUT(to_integer(unsigned(freq_sel)));

  u_seg7 : seg7_ctrl
    port map (
      clk   => CLK100MHZ,
      rst   => rst,
      data  => disp_data,
      dp_in => (others => '0'),  -- žiadne desatinné bodky
      seg   => SEG,
      dp    => DP,
      an    => AN
    );

  -- -----------------------------------------------------------------------
  -- LED indikátory
  -- -----------------------------------------------------------------------
  LED(0)           <= sq_raw;           -- blikajúci obdĺžnik (viditeľný pri 1–10 Hz)
  LED(2 downto 1)  <= "01" when unsigned(freq_sel) <= 4 else "10"; -- Hz / kHz
  LED(4 downto 3)  <= (others => '0');  -- rezerva
  LED(6 downto 5)  <= wave_sel;         -- zobrazenie vybraného priebehov
  LED(15 downto 7) <= (others => '0');  -- rezerva

  -- -----------------------------------------------------------------------
  -- Pmod JA výstupy
  -- -----------------------------------------------------------------------
  JA(0)          <= pwm_sig;            -- hlavný PWM výstup
  JA(7 downto 1) <= (others => '0');

end architecture rtl;
