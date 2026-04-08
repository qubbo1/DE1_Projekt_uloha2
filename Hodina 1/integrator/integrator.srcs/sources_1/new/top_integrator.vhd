library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity top_integrator is
Port (clk : in std_logic  );
end top_integrator;

architecture Behavioral of top_integrator is

  component debounce is
        port (
            clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           btn_in : in STD_LOGIC;
           btn_state : out STD_LOGIC;
           btn_press : out STD_LOGIC;
           btn_release : out std_logic
        );
    end component debounce;
    
 component control_logic is
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
 end component control_logic;
 
 component integrator is
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
 end component integrator;
        
 

begin


end Behavioral;
