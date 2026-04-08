-- =============================================================
--  TESTBENCH — demonstrates sawtooth vs triangle visually
--  Run for ~20000 ns to see multiple full cycles of both
-- =============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_integrator is
end tb_integrator;

architecture Behavioral of tb_integrator is

    component integrator_saw
        generic (WIDTH : integer := 12; K : integer := 1);
        port (clk, rst, en, dir : in std_logic;
              phase : out std_logic_vector(11 downto 0));
    end component;

    component integrator_tri
        generic (WIDTH : integer := 12; K : integer := 1);
        port (clk, rst, en, dir : in std_logic;
              phase : out std_logic_vector(11 downto 0));
    end component;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal en        : std_logic := '1';
    signal dir       : std_logic := '1';
    signal phase_saw : std_logic_vector(11 downto 0);
    signal phase_tri : std_logic_vector(11 downto 0);

    -- use a larger K so waveforms complete faster and are visible in sim
    constant K_VAL      : integer := 4;
    constant CLK_PERIOD : time    := 10 ns;  -- 100 MHz

begin

    uut_saw : integrator_saw
        generic map (WIDTH => 12, K => K_VAL)
        port map (clk => clk, rst => rst, en => en,
                  dir => dir, phase => phase_saw);

    uut_tri : integrator_tri
        generic map (WIDTH => 12, K => K_VAL)
        port map (clk => clk, rst => rst, en => en,
                  dir => dir, phase => phase_tri);

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        -- -------------------------------------------------------
        -- PHASE 0: reset both
        -- -------------------------------------------------------
        rst <= '1';
        en  <= '0';
        dir <= '1';
        wait for 100 ns;
        rst <= '0';
        en  <= '1';

        -- -------------------------------------------------------
        -- PHASE 1: upward sawtooth + triangle rising
        --   saw:  0 ------> 4095 -> wraps to 0 -> repeats
        --   tri:  0 ------> 4095 -> bounces down -> bounces up
        -- let it run for 3 full sawtooth cycles
        -- one cycle = 4096/K_VAL clocks = 1024 clocks = 10240 ns
        -- -------------------------------------------------------
        dir <= '1';
        wait for 30720 ns;  -- 3 x (4096/4) x 10ns

        -- -------------------------------------------------------
        -- PHASE 2: freeze both with en — values must hold steady
        -- -------------------------------------------------------
        en <= '0';
        wait for 500 ns;
        en <= '1';

        -- -------------------------------------------------------
        -- PHASE 3: downward sawtooth
        --   saw:  current value -> counts down -> wraps at 0 -> repeats
        --   tri:  ignores dir change, keeps bouncing automatically
        -- -------------------------------------------------------
        dir <= '0';
        wait for 30720 ns;

        -- -------------------------------------------------------
        -- PHASE 4: mid-run reset — both snap back to 0
        --          then restart: saw down, tri up (dir='1' after)
        -- -------------------------------------------------------
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        dir <= '1';
        wait for 30720 ns;

        -- -------------------------------------------------------
        -- PHASE 5: show enable toggling during a run
        --          output should stutter — freeze and resume
        -- -------------------------------------------------------
        en <= '0'; wait for 200 ns;
        en <= '1'; wait for 500 ns;
        en <= '0'; wait for 200 ns;
        en <= '1'; wait for 500 ns;
        en <= '0'; wait for 200 ns;
        en <= '1';
        wait for 10000 ns;

        wait;  -- stop simulation
    end process;

end Behavioral;
