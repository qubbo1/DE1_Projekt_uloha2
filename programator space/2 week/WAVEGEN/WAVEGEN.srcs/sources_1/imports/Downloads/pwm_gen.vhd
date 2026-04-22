-- =============================================================================
-- pwm_gen.vhd
-- 8-bit PWM generátor
-- Konvertuje 8-bitovú hodnotu duty cycle na PWM signál.
-- PWM frekvencia = 100 MHz / 256 ≈ 390 kHz
--
-- duty = 0x00 →   0% (trvale '0')
-- duty = 0x80 →  50% (50% duty cycle)
-- duty = 0xFF → ~100% (trvale '1')
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_gen is
  port (
    clk     : in  std_logic;                    -- 100 MHz systémový hodinový signál
    rst     : in  std_logic;                    -- synchrónny reset, aktívny HIGH
    duty    : in  std_logic_vector(7 downto 0); -- 8-bit duty cycle (0x00 = 0%, 0xFF ≈ 100%)
    pwm_out : out std_logic                     -- PWM výstup
  );
end entity pwm_gen;

architecture rtl of pwm_gen is
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
        if cnt < unsigned(duty) then
          pwm_out <= '1';
        else
          pwm_out <= '0';
        end if;
      end if;
    end if;
  end process p_pwm;

end architecture rtl;
