library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_integrator is
end tb_integrator;

architecture Behavioral of tb_integrator is

    -- komponent integratora
    component integrator
        generic (
            WIDTH : integer := 12;
            K     : integer := 1
        );
        port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            en    : in  std_logic;
            dir   : in  std_logic;
            phase : out std_logic_vector(11 downto 0)
        );
    end component;

    -- signaly
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal en    : std_logic := '1';
    signal dir   : std_logic := '1';
    signal phase : std_logic_vector(11 downto 0);

    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz

begin

    -- instancia integratora
    uut: integrator
        generic map (
            WIDTH => 12,
            K     => 1
        )
        port map (
            clk   => clk,
            rst   => rst,
            en    => en,
            dir   => dir,
            phase => phase
        );

    -- hodinovy signal
    clk <= not clk after CLK_PERIOD / 2;

    -- stimuly
    process
    begin
        -- reset na zaciatku
        rst <= '1';
        wait for 40 ns;
        rst <= '0';

        -- test 1: pocita hore (dir = '1')
        dir <= '1';
        wait for 500 ns;

        -- test 2: pocita dole (dir = '0')
        dir <= '0';
        wait for 500 ns;

        -- test 3: enable vypnuty - hodnota sa nesmie menit
        en <= '0';
        wait for 200 ns;
        en <= '1';

        -- test 4: reset uprostred behu
        wait for 200 ns;
        rst <= '1';
        wait for 40 ns;
        rst <= '0';

        -- nechaj bezat
        dir <= '1';
        wait for 1000 ns;

        wait;
    end process;

end Behavioral;
