-- =============================================================================
-- top.vhd – wavegen_top
-- Generátor vlnových tvarov – vrchná entita, Nexys A7-50T (100 MHz)
--
-- OVLÁDANIE:
--   SW(0)=1, SW(1)=0  →  Režim frekvencie
--     BTNU / BTND  →  zvýši / zníži cifru na kurzore o 1
--     BTNR / BTNL  →  posunie kurzor vpravo / vľavo po AN[3:0]
--
--   SW(1)=1, SW(0)=0  →  Režim vlnového tvaru
--     BTNU / BTND  →  ďalší / predchádzajúci vlnový tvar
--
--   SW(0)=1 a SW(1)=1 súčasne  →  zakázané
--   SW(2)   →  povolenie AUX výstupu (3.5 mm jack → osciloskop CH1)
--   BTNC    →  systémový reset
--
-- VÝSTUPY:
--   AUD_PWM – PWM signál → RC filter → 3.5 mm jack
--   AUD_SD  – povolenie audio zosilňovača
--   JA(0)   – priamy digitálny výstup (MSB vlny) → osciloskop CH2
--   7-seg   – AN[7:4] = tvar, AN[3:0] = frekvencia (kurzor = DP)
--   LED     – nevyužité, nastavené na '0'
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    -- Hodinový signál
    CLK100MHZ : in  std_logic;

    -- Tlačidlá (aktívne HIGH na Nexys A7)
    BTNC : in  std_logic;  -- Center → systémový reset
    BTNU : in  std_logic;  -- Up
    BTND : in  std_logic;  -- Down
    BTNL : in  std_logic;  -- Left
    BTNR : in  std_logic;  -- Right

    -- Prepínače
    SW   : in  std_logic_vector(15 downto 0);

    -- LED diódy (nevyužité – udržiavané na '0' pre správnu syntézu)
    LED  : out std_logic_vector(15 downto 0);

    -- 7-segmentový displej (aktívne LOW)
    SEG  : out std_logic_vector(6 downto 0);
    DP   : out std_logic;
    AN   : out std_logic_vector(7 downto 0);

    -- Audio výstup – 3.5 mm AUX jack
    AUD_PWM : out std_logic;
    AUD_SD  : out std_logic;

    -- Pmod JA – priamy digitálny výstup pre osciloskop CH2
    JA   : out std_logic_vector(7 downto 0)
  );
end entity top;

architecture rtl of top is

  -- -------------------------------------------------------------------------
  -- Interné signály
  -- -------------------------------------------------------------------------
  signal rst          : std_logic;

  -- Debounce výstupy
  signal btn_u_press  : std_logic;
  signal btn_d_press  : std_logic;
  signal btn_l_press  : std_logic;
  signal btn_r_press  : std_logic;

  -- Riadenie
  signal freq_val     : std_logic_vector(13 downto 0);
  signal wave_sel     : std_logic_vector(1 downto 0);
  signal disp_data    : std_logic_vector(63 downto 0);

  -- Fázový čítač
  signal phase        : std_logic_vector(7 downto 0);

  -- Vlnové tvary
  signal wave_sq      : std_logic_vector(7 downto 0);
  signal wave_sin     : std_logic_vector(7 downto 0);
  signal wave_saw     : std_logic_vector(7 downto 0);
  signal wave_tri     : std_logic_vector(7 downto 0);
  signal wave_out     : std_logic_vector(7 downto 0);

  -- PWM
  signal pwm_sig      : std_logic;

  -- -------------------------------------------------------------------------
  -- Komponent deklarácie
  -- -------------------------------------------------------------------------

  component debounce is
    port (
      clk         : in  std_logic;
      rst         : in  std_logic;
      btn_in      : in  std_logic;
      btn_state   : out std_logic;
      btn_press   : out std_logic;
      btn_release : out std_logic
    );
  end component;

  component phase_counter is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      freq_val : in  std_logic_vector(13 downto 0);
      phase    : out std_logic_vector(7 downto 0)
    );
  end component;

  component square_gen is
    port (
      phase    : in  std_logic_vector(7 downto 0);
      wave_out : out std_logic_vector(7 downto 0)
    );
  end component;

  component sine_lut is
    port (
      addr     : in  std_logic_vector(7 downto 0);
      data_out : out std_logic_vector(7 downto 0)
    );
  end component;

  component sawtooth_gen is
    port (
      phase    : in  std_logic_vector(7 downto 0);
      wave_out : out std_logic_vector(7 downto 0)
    );
  end component;

  component triangle_gen is
    port (
      phase    : in  std_logic_vector(7 downto 0);
      wave_out : out std_logic_vector(7 downto 0)
    );
  end component;

  component wave_mux is
    port (
      wave_sq  : in  std_logic_vector(7 downto 0);
      wave_sin : in  std_logic_vector(7 downto 0);
      wave_saw : in  std_logic_vector(7 downto 0);
      wave_tri : in  std_logic_vector(7 downto 0);
      wave_sel : in  std_logic_vector(1 downto 0);
      wave_out : out std_logic_vector(7 downto 0)
    );
  end component;

  component pwm is
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      sample  : in  std_logic_vector(7 downto 0);
      pwm_out : out std_logic
    );
  end component;

  component seg7_ctrl is
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      disp_data : in  std_logic_vector(63 downto 0);
      seg       : out std_logic_vector(6 downto 0);
      dp        : out std_logic;
      an        : out std_logic_vector(7 downto 0)
    );
  end component;

  component control_logic is
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      btn_u     : in  std_logic;
      btn_d     : in  std_logic;
      btn_l     : in  std_logic;
      btn_r     : in  std_logic;
      sw_freq   : in  std_logic;
      sw_wave   : in  std_logic;
      freq_val  : out std_logic_vector(13 downto 0);
      wave_sel  : out std_logic_vector(1 downto 0);
      disp_data : out std_logic_vector(63 downto 0)
    );
  end component;

begin

  -- =========================================================================
  -- Reset
  -- =========================================================================
  rst <= BTNC;

  -- =========================================================================
  -- LED – nevyužité, všetky nastavené na '0'
  -- =========================================================================
  LED <= (others => '0');

  -- =========================================================================
  -- Debounce pre každé tlačidlo
  -- =========================================================================
  u_dbn_u : debounce
    port map (clk => CLK100MHZ, rst => rst, btn_in => BTNU,
              btn_press => btn_u_press, btn_state => open, btn_release => open);

  u_dbn_d : debounce
    port map (clk => CLK100MHZ, rst => rst, btn_in => BTND,
              btn_press => btn_d_press, btn_state => open, btn_release => open);

  u_dbn_l : debounce
    port map (clk => CLK100MHZ, rst => rst, btn_in => BTNL,
              btn_press => btn_l_press, btn_state => open, btn_release => open);

  u_dbn_r : debounce
    port map (clk => CLK100MHZ, rst => rst, btn_in => BTNR,
              btn_press => btn_r_press, btn_state => open, btn_release => open);

  -- =========================================================================
  -- Riadiaca logika
  -- =========================================================================
  u_ctrl : control_logic
    port map (
      clk       => CLK100MHZ,
      rst       => rst,
      btn_u     => btn_u_press,
      btn_d     => btn_d_press,
      btn_l     => btn_l_press,
      btn_r     => btn_r_press,
      sw_freq   => SW(0),
      sw_wave   => SW(1),
      freq_val  => freq_val,
      wave_sel  => wave_sel,
      disp_data => disp_data
    );

  -- =========================================================================
  -- DDS Fázový čítač
  -- =========================================================================
  u_phase : phase_counter
    port map (
      clk      => CLK100MHZ,
      rst      => rst,
      freq_val => freq_val,
      phase    => phase
    );

  -- =========================================================================
  -- Generátory vlnových tvarov
  -- =========================================================================
  u_sq  : square_gen   port map (phase => phase, wave_out => wave_sq);
  u_sin : sine_lut     port map (addr  => phase, data_out => wave_sin);
  u_saw : sawtooth_gen port map (phase => phase, wave_out => wave_saw);
  u_tri : triangle_gen port map (phase => phase, wave_out => wave_tri);

  -- =========================================================================
  -- MUX výberu vlnového tvaru
  -- =========================================================================
  u_mux : wave_mux
    port map (
      wave_sq  => wave_sq,
      wave_sin => wave_sin,
      wave_saw => wave_saw,
      wave_tri => wave_tri,
      wave_sel => wave_sel,
      wave_out => wave_out
    );

  -- =========================================================================
  -- PWM generátor
  -- =========================================================================
  u_pwm : pwm
    port map (
      clk     => CLK100MHZ,
      rst     => rst,
      sample  => wave_out,
      pwm_out => pwm_sig
    );

  -- =========================================================================
  -- 7-segmentový displej
  -- =========================================================================
  u_seg7 : seg7_ctrl
    port map (
      clk       => CLK100MHZ,
      rst       => rst,
      disp_data => disp_data,
      seg       => SEG,
      dp        => DP,
      an        => AN
    );

  -- =========================================================================
  -- Výstupné priradenia
  -- =========================================================================

  -- AUX výstup – SW(2) povolí signál a zosilňovač
  AUD_PWM <= pwm_sig when SW(2) = '1' else '0';
  AUD_SD  <= SW(2);

  -- Priamy digitálny výstup → osciloskop CH2
  JA(0)          <= wave_out(7) when SW(2) = '1' else '0';
  JA(7 downto 1) <= (others => '0');

end architecture rtl;
