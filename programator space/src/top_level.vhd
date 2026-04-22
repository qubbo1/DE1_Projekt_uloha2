library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    port (
        clk     : in  std_logic;                        -- 100 MHz onboard clock
        rst     : in  std_logic;                        -- BTNC - reset
        btn     : in  std_logic;                        -- BTNR - prepinanie tvaru
        led     : out std_logic_vector(15 downto 0)     -- 16x LED na zobrazenie phase
    );
end top_level;

architecture Behavioral of top_level is

    -- =========================================================
    -- KOMPONENTY
    -- =========================================================

    component debounce
        port (
            clk    : in  std_logic;
            btn_in : in  std_logic;
            btn_out: out std_logic
        );
    end component;

    component control_logic
        port (
            clk  : in  std_logic;
            rst  : in  std_logic;
            btn  : in  std_logic;
            sel  : out std_logic_vector(1 downto 0);
            dir  : out std_logic
        );
    end component;

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

    -- =========================================================
    -- INTERNEE SIGNALY
    -- =========================================================

    signal btn_clean  : std_logic;                      -- odbouncovane tlacidlo
    signal sel        : std_logic_vector(1 downto 0);   -- vyber tvaru
    signal dir        : std_logic;                      -- smer integracie
    signal phase      : std_logic_vector(11 downto 0);  -- vystup integratora

    -- clock divider signal
    signal clk_div_cnt : unsigned(16 downto 0) := (others => '0');
    signal clk_en      : std_logic := '0';              -- enable pre integrator

begin

    -- =========================================================
    -- CLOCK DIVIDER (jednoduchy, inline)
    -- 100 MHz / 2^17 = cca 763 Hz - viditelne na LEDkach
    -- =========================================================
    process(clk)
    begin
        if rising_edge(clk) then
            clk_div_cnt <= clk_div_cnt + 1;
        end if;
    end process;

    clk_en <= clk_div_cnt(16);  -- en pulz kazdych 2^16 taktov

    -- =========================================================
    -- INSTANCIE
    -- =========================================================

    -- debouncer
    u_debounce: debounce
        port map (
            clk     => clk,
            btn_in  => btn,
            btn_out => btn_clean
        );

    -- riadiaca logika
    u_ctrl: control_logic
        port map (
            clk => clk,
            rst => rst,
            btn => btn_clean,
            sel => sel,
            dir => dir
        );

    -- integrator
    u_integ: integrator
        generic map (
            WIDTH => 12,
            K     => 1
        )
        port map (
            clk   => clk,
            rst   => rst,
            en    => clk_en,
            dir   => dir,
            phase => phase
        );

    -- =========================================================
    -- LED VYSTUP
    -- zobrazuje phase na hornich 12 LEDkach
    -- spodne 2 LEDky ukazuju vybrany tvar (sel)
    -- =========================================================
    led(15 downto 4) <= phase(11 downto 0);   -- phase na LEDkach
    led(3 downto 2)  <= (others => '0');       -- nevyuzite
    led(1 downto 0)  <= sel;                   -- aktualny tvar

end Behavioral;
