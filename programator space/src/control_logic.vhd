library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_logic is
    port (
        clk     : in  std_logic;        -- hodinový signál
        rst     : in  std_logic;        -- reset
        btn     : in  std_logic;        -- tlačidlo (už odbouncované)
        sel     : out std_logic_vector(1 downto 0);  -- výber tvaru pre MUX
        dir     : out std_logic         -- smer integrácie pre integrátor
    );
end control_logic;

architecture Behavioral of control_logic is

    -- stavy vlnových tvarov
    -- 00 = square, 01 = saw, 10 = triangle, 11 = sine
    signal waveform : std_logic_vector(1 downto 0) := "00";

    -- detekcia nábeżnej hrany tlačidla
    signal btn_prev : std_logic := '0';
    signal btn_edge : std_logic := '0';

    -- interný smer pre trojuholník
    signal dir_reg  : std_logic := '1';

begin

    -- detekcia náběžnej hrany (stlačenie tlačidla)
    process(clk)
    begin
        if rising_edge(clk) then
            btn_prev <= btn;
        end if;
    end process;

    btn_edge <= btn and (not btn_prev);  -- '1' len na jeden takt pri stlačení

    -- hlavná logika: prepínanie vlnových tvarov
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                waveform <= "00";       -- po resete začni od square
            elsif btn_edge = '1' then
                case waveform is
                    when "00"   => waveform <= "01";   -- square -> saw
                    when "01"   => waveform <= "10";   -- saw -> triangle
                    when "10"   => waveform <= "11";   -- triangle -> sine
                    when others => waveform <= "00";   -- sine -> square
                end case;
            end if;
        end if;
    end process;

    -- smer integrácie:
    -- square a saw: vždy hore (dir = '1')
    -- triangle: komparátor bude riadiť dir zvonku, tu dáme default '1'
    -- sine: DDS, dir nie je relevantný (phase vždy rastie)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                dir_reg <= '1';
            else
                case waveform is
                    when "10"   => dir_reg <= dir_reg;  -- triangle: riadi komparátor
                    when others => dir_reg <= '1';       -- ostatné: vždy hore
                end case;
            end if;
        end if;
    end process;

    sel <= waveform;
    dir <= dir_reg;

end Behavioral;
