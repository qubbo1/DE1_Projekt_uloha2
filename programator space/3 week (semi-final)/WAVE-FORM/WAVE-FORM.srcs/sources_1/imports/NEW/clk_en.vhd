-- =============================================================================
-- clk_en.vhd
-- Generický clock enable – generuje jednocyklový pulz každých G_MAX cyklov.
-- Používa ho debounce.vhd (G_MAX=200_000 → 2 ms pri 100 MHz).
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_en is
  generic (
    G_MAX : positive := 1_000_000  -- počet hodinových cyklov medzi pulzmi
  );
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    ce  : out std_logic
  );
end entity clk_en;

architecture rtl of clk_en is
  signal cnt : natural range 0 to G_MAX - 1 := 0;
begin

  p_ce : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt <= 0;
        ce  <= '0';
      else
        ce <= '0';                       -- default: žiadny pulz
        if cnt = G_MAX - 1 then
          cnt <= 0;
          ce  <= '1';                    -- jednocyklový pulz
        else
          cnt <= cnt + 1;
        end if;
      end if;
    end if;
  end process p_ce;

end architecture rtl;
