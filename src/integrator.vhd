-- =============================================================
--  SAWTOOTH version
--  Counts up/down based on external dir signal.
--  At overflow (4095->0) or underflow (0->4095) it wraps around,
--  producing a sawtooth shape. Dir must be flipped manually.
-- =============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity integrator_saw is
    generic (
        WIDTH : integer := 12;
        K     : integer := 1
    );
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        en    : in  std_logic;
        dir   : in  std_logic;          -- '1' = up sawtooth, '0' = down sawtooth
        phase : out std_logic_vector(WIDTH-1 downto 0)
    );
end integrator_saw;

architecture Behavioral of integrator_saw is
    signal phase_reg : unsigned(WIDTH-1 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                phase_reg <= (others => '0');
            elsif en = '1' then
                if dir = '1' then
                    phase_reg <= phase_reg + to_unsigned(K, WIDTH);
                    -- at 4095 wraps back to 0  -> sawtooth /|/|/|
                else
                    phase_reg <= phase_reg - to_unsigned(K, WIDTH);
                    -- at 0 wraps back to 4095  -> sawtooth |\|\|\
                end if;
            end if;
        end if;
    end process;

    phase <= std_logic_vector(phase_reg);
end Behavioral;


-- =============================================================
--  TRUE TRIANGLE version
--  Bounces automatically between 0 and 4095.
--  External dir is only used to set initial direction after reset.
--  No wrapping — the signal reverses at both limits: /\/\/\
-- =============================================================

entity integrator_tri is
    generic (
        WIDTH : integer := 12;
        K     : integer := 1
    );
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        en    : in  std_logic;
        dir   : in  std_logic;          -- sets initial direction after reset only
        phase : out std_logic_vector(WIDTH-1 downto 0)
    );
end integrator_tri;

architecture Behavioral of integrator_tri is
    signal phase_reg : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal dir_i     : std_logic := '1';    -- internally managed direction
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                phase_reg <= (others => '0');
                dir_i     <= dir;           -- capture external dir at reset

            elsif en = '1' then
                -- flip direction before hitting the limits to prevent overshoot
                if phase_reg >= to_unsigned(2**WIDTH - 1 - K, WIDTH) then
                    dir_i <= '0';
                elsif phase_reg <= to_unsigned(K, WIDTH) then
                    dir_i <= '1';
                end if;

                if dir_i = '1' then
                    phase_reg <= phase_reg + to_unsigned(K, WIDTH);
                else
                    phase_reg <= phase_reg - to_unsigned(K, WIDTH);
                end if;
            end if;
        end if;
    end process;

    phase <= std_logic_vector(phase_reg);
end Behavioral;
