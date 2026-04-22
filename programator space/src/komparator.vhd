


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity komparator is
    Port (  A : in STD_LOGIC_VECTOR (2-1 downto 0);
            B : in STD_LOGIC_VECTOR (2-1 downto 0);
            b_gt : out std_logic;
            b_a_eq :     out std_logic;
            a_gt : out std_logic;
            b_gt_sop : out std_logic
            
               );
           
           
end komparator;

architecture Behavioral of komparator is

begin

b_gt <= '1' when (B>A) else '0';
b_a_eq <= '1' when (A=B) else '0';
a_gt <= '1' when (A>B) else '0';

b_gt_sop <= (not A(1) AND B(1)) OR 
((not A(0)) AND B(0) AND B(1)) OR 
(not A(0) AND not A(1) AND B(0));

end Behavioral;
