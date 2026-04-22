-- =============================================================================
-- pwm.vhd
-- 8-bit PWM generátor pre AUX výstup
--
-- PWM frekvencia ≈ 100 MHz / 256 ≈ 390 kHz (ďaleko nad sluchom, RC filter hladí)
-- sample = 0x00 →   0% duty (trvale LOW)
-- sample = 0x80 →  50% duty
-- sample = 0xFF → ~100% duty (trvale HIGH)
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm is
  port (
    clk     : in  std_logic;                    -- 100 MHz
    rst     : in  std_logic;
    sample  : in  std_logic_vector(7 downto 0); -- 8-bit duty cycle
    pwm_out : out std_logic
  );
end entity pwm;

architecture rtl of pwm is
  signal cnt : unsigned(7 downto 0) := (others => '0');
begin

  p_pwm : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt     <= (others => '0');
        pwm_out <= '0';
      else
        cnt <= cnt + 1;
        if cnt < unsigned(sample) then
          pwm_out <= '1';
        else
          pwm_out <= '0';
        end if;
      end if;
    end if;
  end process p_pwm;

end architecture rtl;
