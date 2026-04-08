library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity integrator is
    generic (
        WIDTH : integer := 12;          -- šírka akumulátora (bitov)
        K     : integer := 1            -- krok integrácie (určuje frekvenciu)
    );
    port (
        clk   : in  std_logic;          -- hodinový signál
        rst   : in  std_logic;          -- reset (active high)
        en    : in  std_logic;          -- enable (napr. z clock dividera)
        dir   : in  std_logic;          -- smer: '1' = hore, '0' = dole
        phase : out std_logic_vector(WIDTH-1 downto 0)  -- výstup akumulátora
    );
end integrator;

architecture Behavioral of integrator is

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
                else
                    phase_reg <= phase_reg - to_unsigned(K, WIDTH);
                end if;
            end if;
        end if;
    end process;

    phase <= std_logic_vector(phase_reg);

end Behavioral;
