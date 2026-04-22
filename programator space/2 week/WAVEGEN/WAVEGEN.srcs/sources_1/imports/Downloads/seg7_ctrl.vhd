-- =============================================================================
-- seg7_ctrl.vhd
-- Ovládač 8-miestneho 7-segmentového displeja pre Nexys A7-50T
--
-- Vstup data (32 bitov) = 8 x 4-bitové cifry
--   data(3:0)   = cifra 0 (AN0, najprávejšia)
--   data(7:4)   = cifra 1 (AN1)
--   ...
--   data(31:28) = cifra 7 (AN7, najľavejšia)
--
-- Kódovanie cifry (4-bit):
--   0-9   = decimálne číslice
--   10=A, 11=b, 12=C, 13=d, 14=E, 15=blank (vypnuté)
--
-- Výstupy sú aktívne LOW (Nexys A7 štandard)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7_ctrl is
  port (
    clk   : in  std_logic;                     -- 100 MHz
    rst   : in  std_logic;
    data  : in  std_logic_vector(31 downto 0); -- 8 x 4-bit cifry
    dp_in : in  std_logic_vector(7 downto 0);  -- desatinné bodky (aktívne HIGH)
    seg   : out std_logic_vector(6 downto 0);  -- {CG,CF,CE,CD,CC,CB,CA} aktívne LOW
    dp    : out std_logic;                     -- desatinná bodka, aktívna LOW
    an    : out std_logic_vector(7 downto 0)   -- anódy, aktívne LOW
  );
end entity seg7_ctrl;

architecture rtl of seg7_ctrl is

  -- Obnova: 1 cifra každých 1 ms = 100 000 cyklov @ 100 MHz
  constant REFRESH_CYCLES : natural := 100_000;

  -- LUT segmentov: seg(6:0) = {CG, CF, CE, CD, CC, CB, CA}, aktívne LOW
  --        aaaa
  --       f    b
  --       f    b
  --        gggg
  --       e    c
  --       e    c
  --        dddd
  type seg_lut_t is array(0 to 15) of std_logic_vector(6 downto 0);
  constant SEG_LUT : seg_lut_t := (
    "1000000",  --  0
    "1111001",  --  1
    "0100100",  --  2
    "0110000",  --  3
    "0011001",  --  4
    "0010010",  --  5
    "0000010",  --  6
    "1111000",  --  7
    "0000000",  --  8
    "0010000",  --  9
    "0001000",  -- 10 = A
    "0000011",  -- 11 = b
    "1000110",  -- 12 = C
    "0100001",  -- 13 = d
    "0000110",  -- 14 = E
    "1111111"   -- 15 = blank (vypnuté)
  );

  -- Rozbalenie 32-bitového vstupu na pole 8 číslic
  type nibble_array_t is array(0 to 7) of std_logic_vector(3 downto 0);
  signal digits : nibble_array_t;

  signal refresh_cnt : natural range 0 to REFRESH_CYCLES - 1 := 0;
  signal digit_sel   : unsigned(2 downto 0) := (others => '0');
  signal digit_val   : std_logic_vector(3 downto 0);
  signal sel_int     : integer range 0 to 7;

begin

  -- Rozbalenie vstupných dát na pole číslic
  digits(0) <= data(3  downto  0);
  digits(1) <= data(7  downto  4);
  digits(2) <= data(11 downto  8);
  digits(3) <= data(15 downto 12);
  digits(4) <= data(19 downto 16);
  digits(5) <= data(23 downto 20);
  digits(6) <= data(27 downto 24);
  digits(7) <= data(31 downto 28);

  sel_int <= to_integer(digit_sel);

  -- Počítadlo obnovovania a výber cifry
  p_refresh : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        refresh_cnt <= 0;
        digit_sel   <= (others => '0');
      else
        if refresh_cnt = REFRESH_CYCLES - 1 then
          refresh_cnt <= 0;
          digit_sel   <= digit_sel + 1;
        else
          refresh_cnt <= refresh_cnt + 1;
        end if;
      end if;
    end if;
  end process p_refresh;

  -- Výber aktuálnej cifry
  digit_val <= digits(sel_int);

  -- Dekodér segmentov
  seg <= SEG_LUT(to_integer(unsigned(digit_val)));

  -- Desatinná bodka (aktívna LOW)
  dp <= not dp_in(sel_int);

  -- Dekodér anód (aktívna LOW, iba jedna aktívna naraz)
  p_anode : process(digit_sel)
  begin
    an <= (others => '1');
    an(to_integer(digit_sel)) <= '0';
  end process p_anode;

end architecture rtl;
