library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_logic is
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;

        -- vstup z integrátora
        phase      : in  unsigned(11 downto 0);

        -- limity
        up_limit   : in  unsigned(11 downto 0);
        down_limit : in  unsigned(11 downto 0);

        -- výber signálu (zo switchov)
        sel        : in  STD_LOGIC_VECTOR(1 downto 0);

        -- výstupy
        direction  : out STD_LOGIC; -- 1 = hore, 0 = dole
        square_out : out STD_LOGIC;
        wave_out   : out unsigned(11 downto 0)
    );
end control_logic;

architecture Behavioral of control_logic is

    signal dir_reg : STD_LOGIC := '1';

    signal triangle : unsigned(11 downto 0);
    signal square   : STD_LOGIC;

    -- fake sine (zatiaľ, nahradíš LUT)
    signal sine     : unsigned(11 downto 0);

begin

    ----------------------------------------------------------------
    -- 🔁 Smer integrácie (trojuholník)
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                dir_reg <= '1';
            else
                if phase >= up_limit then
                    dir_reg <= '0';
                elsif phase <= down_limit then
                    dir_reg <= '1';
                end if;
            end if;
        end if;
    end process;

    direction <= dir_reg;

    ----------------------------------------------------------------
    -- ⚖️ Square wave (komparátor)
    ----------------------------------------------------------------
    square <= '1' when phase > (up_limit / 2) else '0';
    square_out <= square;

    ----------------------------------------------------------------
    -- 🔺 Triangle (priamo phase)
    ----------------------------------------------------------------
    triangle <= phase;

    ----------------------------------------------------------------
    -- 🌊 Sine (placeholder – zatiaľ len phase)
    ----------------------------------------------------------------
    sine <= phase;  -- TODO: nahradiť LUT

    ----------------------------------------------------------------
    -- 🔀 Multiplexer
    ----------------------------------------------------------------
    process(sel, triangle, square, sine)
    begin
        case sel is
            when "00" =>
                wave_out <= triangle;

            when "01" =>
                if square = '1' then
                    wave_out <= (others => '1');
                else
                    wave_out <= (others => '0');
                end if;

            when "10" =>
                wave_out <= sine;

            when others =>
                wave_out <= (others => '0');
        end case;
    end process;

end Behavioral;
