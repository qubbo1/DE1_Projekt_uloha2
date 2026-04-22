-- =============================================================================
-- control_logic.vhd
-- Riadiaca logika – správa menu cez tlačidlá a prepínače
--
-- OVLÁDANIE:
--   SW(0)=1, SW(1)=0  →  Režim frekvencie
--     BTNU / BTND  →  zvýši / zníži cifru na pozícii kurzora o 1 (0-9, wrap)
--     BTNR / BTNL  →  posunie kurzor vpravo / vľavo po AN[3:0]
--
--   SW(1)=1, SW(0)=0  →  Režim vlnového tvaru
--     BTNU         →  ďalší vlnový tvar
--     BTND         →  predchádzajúci vlnový tvar
--
--   SW(0)=1 a SW(1)=1 súčasne  →  zakázané, všetky tlačidlá ignorované
--   SW(2)  →  povolenie AUX výstupu – rieši top.vhd, kompatibilný s oboma módmi
--
-- DISPLAY (8-miestny 7-seg):
--   AN[7:4] = názov tvaru (SQr_, SIn_, SAu_, trI_)
--   AN[3:0] = frekvencia v Hz – 4 editovateľné BCD cifry
--             kurzorová pozícia je vyznačená rozsvietením desatinnej bodky (DP)
--
-- Segmentový bajt: bit[7]=DP (1=zapnutá), bit[6:0]={CG,CF,CE,CD,CC,CB,CA} aktívne LOW
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_logic is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    -- Jednocyklové pulzy z debounce
    btn_u     : in  std_logic;
    btn_d     : in  std_logic;
    btn_l     : in  std_logic;
    btn_r     : in  std_logic;
    -- Prepínače
    sw_freq   : in  std_logic;                     -- SW(0): režim frekvencie
    sw_wave   : in  std_logic;                     -- SW(1): režim tvaru
    -- Výstupy
    freq_val  : out std_logic_vector(13 downto 0); -- 0–9999 Hz (binárne)
    wave_sel  : out std_logic_vector(1 downto 0);
    disp_data : out std_logic_vector(63 downto 0)
  );
end entity control_logic;

architecture rtl of control_logic is

  -- =========================================================================
  -- Stavové registre
  -- =========================================================================
  signal freq_d0 : unsigned(3 downto 0) := "0001"; -- jednotky  (AN0, najprávejší)
  signal freq_d1 : unsigned(3 downto 0) := "0000"; -- desiatky  (AN1)
  signal freq_d2 : unsigned(3 downto 0) := "0000"; -- stovky    (AN2)
  signal freq_d3 : unsigned(3 downto 0) := "0000"; -- tisíce    (AN3)
  signal cursor  : unsigned(1 downto 0) := "00";   -- 0=AN0 .. 3=AN3
  signal wave_reg: unsigned(1 downto 0) := "00";

  -- =========================================================================
  -- 7-segmentové konštanty (bit[6:0], aktívne LOW, bez DP bitu)
  -- =========================================================================
  constant S_0   : std_logic_vector(6 downto 0) := "1000000"; -- 0
  constant S_1   : std_logic_vector(6 downto 0) := "1111001"; -- 1
  constant S_2   : std_logic_vector(6 downto 0) := "0100100"; -- 2
  constant S_3   : std_logic_vector(6 downto 0) := "0110000"; -- 3
  constant S_4   : std_logic_vector(6 downto 0) := "0011001"; -- 4
  constant S_5   : std_logic_vector(6 downto 0) := "0010010"; -- 5 / S
  constant S_6   : std_logic_vector(6 downto 0) := "0000010"; -- 6
  constant S_7   : std_logic_vector(6 downto 0) := "1111000"; -- 7
  constant S_8   : std_logic_vector(6 downto 0) := "0000000"; -- 8
  constant S_9   : std_logic_vector(6 downto 0) := "0010000"; -- 9
  constant S_A   : std_logic_vector(6 downto 0) := "0001000"; -- A
  constant S_r   : std_logic_vector(6 downto 0) := "0101111"; -- r (malé)
  constant S_n   : std_logic_vector(6 downto 0) := "0101011"; -- n (malé)
  constant S_u   : std_logic_vector(6 downto 0) := "1100011"; -- u (malé)
  constant S_t   : std_logic_vector(6 downto 0) := "0000111"; -- t
  constant S_I   : std_logic_vector(6 downto 0) := "1111001"; -- I  (= 1)
  constant S_BLK : std_logic_vector(6 downto 0) := "1111111"; -- prázdno

  -- =========================================================================
  -- LUT názvov vlnových tvarov – AN[7:4], každý tvar = 4 bajty
  --   bajt = '0' & 7-bitový seg vzor  (DP vypnutá)
  -- =========================================================================
  type wave_name_t is array(0 to 3) of std_logic_vector(31 downto 0);
  constant WAVE_NAMES : wave_name_t := (
    0 => ('0' & S_5) & ('0' & S_0) & ('0' & S_r) & ('0' & S_BLK), -- "SQr "
    1 => ('0' & S_5) & ('0' & S_I) & ('0' & S_n) & ('0' & S_BLK), -- "SIn "
    2 => ('0' & S_5) & ('0' & S_A) & ('0' & S_u) & ('0' & S_BLK), -- "SAu "
    3 => ('0' & S_t) & ('0' & S_r) & ('0' & S_I) & ('0' & S_BLK)  -- "trI "
  );

  -- =========================================================================
  -- Pomocné funkcie
  -- =========================================================================

  -- BCD cifra (0-9) → 7-segmentový vzor (7 bitov, bez DP)
  function bcd_seg(d : unsigned(3 downto 0)) return std_logic_vector is
    variable s : std_logic_vector(6 downto 0);
  begin
    case d is
      when "0000" => s := S_0;
      when "0001" => s := S_1;
      when "0010" => s := S_2;
      when "0011" => s := S_3;
      when "0100" => s := S_4;
      when "0101" => s := S_5;
      when "0110" => s := S_6;
      when "0111" => s := S_7;
      when "1000" => s := S_8;
      when "1001" => s := S_9;
      when others => s := S_BLK;
    end case;
    return s;
  end function;

  -- Zostavenie bajtu: DP bit & 7-seg vzor
  function seg_byte(seg : std_logic_vector(6 downto 0); dp : std_logic)
    return std_logic_vector is
  begin
    return dp & seg;
  end function;

  -- =========================================================================
  -- Interné signály pre výstupné bajty ciferníka frekvencie
  -- =========================================================================
  signal b0 : std_logic_vector(7 downto 0); -- AN0 – jednotky
  signal b1 : std_logic_vector(7 downto 0); -- AN1 – desiatky
  signal b2 : std_logic_vector(7 downto 0); -- AN2 – stovky
  signal b3 : std_logic_vector(7 downto 0); -- AN3 – tisíce

begin

  -- =========================================================================
  -- Riadiaci proces – frekvenčné cifry, kurzor, vlnový tvar
  -- =========================================================================
  p_ctrl : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        freq_d0 <= "0001";
        freq_d1 <= "0000";
        freq_d2 <= "0000";
        freq_d3 <= "0000";
        cursor   <= "00";
        wave_reg <= "00";

      -- ----------------------------------------------------------------
      -- SW(0)=1, SW(1)=0  →  Režim frekvencie
      -- ----------------------------------------------------------------
      elsif sw_freq = '1' and sw_wave = '0' then

        -- Pohyb kurzora
        if btn_r = '1' then
          if cursor = "11" then cursor <= "00";
          else cursor <= cursor + 1;
          end if;
        elsif btn_l = '1' then
          if cursor = "00" then cursor <= "11";
          else cursor <= cursor - 1;
          end if;
        end if;

        -- Zvýšenie cifry na kurzore
        if btn_u = '1' then
          case cursor is
            when "00" =>
              if freq_d0 = 9 then freq_d0 <= "0000";
              else freq_d0 <= freq_d0 + 1; end if;
            when "01" =>
              if freq_d1 = 9 then freq_d1 <= "0000";
              else freq_d1 <= freq_d1 + 1; end if;
            when "10" =>
              if freq_d2 = 9 then freq_d2 <= "0000";
              else freq_d2 <= freq_d2 + 1; end if;
            when others =>
              if freq_d3 = 9 then freq_d3 <= "0000";
              else freq_d3 <= freq_d3 + 1; end if;
          end case;

        -- Zníženie cifry na kurzore
        elsif btn_d = '1' then
          case cursor is
            when "00" =>
              if freq_d0 = 0 then freq_d0 <= "1001";
              else freq_d0 <= freq_d0 - 1; end if;
            when "01" =>
              if freq_d1 = 0 then freq_d1 <= "1001";
              else freq_d1 <= freq_d1 - 1; end if;
            when "10" =>
              if freq_d2 = 0 then freq_d2 <= "1001";
              else freq_d2 <= freq_d2 - 1; end if;
            when others =>
              if freq_d3 = 0 then freq_d3 <= "1001";
              else freq_d3 <= freq_d3 - 1; end if;
          end case;
        end if;

      -- ----------------------------------------------------------------
      -- SW(1)=1, SW(0)=0  →  Režim vlnového tvaru
      -- ----------------------------------------------------------------
      elsif sw_wave = '1' and sw_freq = '0' then
        if btn_u = '1' then
          wave_reg <= wave_reg + 1;   -- wrap: "11" → "00"
        elsif btn_d = '1' then
          wave_reg <= wave_reg - 1;   -- wrap: "00" → "11"
        end if;

      -- SW(0)=1 a SW(1)=1 zároveň → ignorujeme všetky tlačidlá
      end if;

    end if;
  end process p_ctrl;

  -- =========================================================================
  -- Výpočet freq_val: BCD → binárne  (max 9999, mieści sa do 14 bitov)
  --   freq_val = d3*1000 + d2*100 + d1*10 + d0
  -- =========================================================================
  freq_val <= std_logic_vector(
    resize(freq_d3 * to_unsigned(1000, 10), 14) +
    resize(freq_d2 * to_unsigned(100,  7),  14) +
    resize(freq_d1 * to_unsigned(10,   4),  14) +
    resize(freq_d0, 14)
  );

  wave_sel <= std_logic_vector(wave_reg);

  -- =========================================================================
  -- Zostavenie frekvenčných bajtov – kurzorová pozícia dostane DP = '1'
  -- =========================================================================
  b0 <= seg_byte(bcd_seg(freq_d0), '1') when cursor = "00" else
        seg_byte(bcd_seg(freq_d0), '0');
  b1 <= seg_byte(bcd_seg(freq_d1), '1') when cursor = "01" else
        seg_byte(bcd_seg(freq_d1), '0');
  b2 <= seg_byte(bcd_seg(freq_d2), '1') when cursor = "10" else
        seg_byte(bcd_seg(freq_d2), '0');
  b3 <= seg_byte(bcd_seg(freq_d3), '1') when cursor = "11" else
        seg_byte(bcd_seg(freq_d3), '0');

  -- =========================================================================
  -- 64-bit displej:
  --   [63:32] = AN7..AN4 = názov vlnového tvaru
  --   [31:24] = AN3 = tisíce (d3)
  --   [23:16] = AN2 = stovky (d2)
  --   [15:8]  = AN1 = desiatky (d1)
  --   [7:0]   = AN0 = jednotky (d0)
  -- =========================================================================
  disp_data <= WAVE_NAMES(to_integer(wave_reg)) & b3 & b2 & b1 & b0;

end architecture rtl;
