

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity komparator_4b is
Port (
A : in std_logic_vector (3 downto 0);
B : in std_logic_vector (3 downto 0);
a_gt : out std_logic;
b_gt : out std_logic;
a_b_eq : out std_logic;
a_lo : out std_logic;
b_lo : out std_logic

);

end komparator_4b;

architecture Behavioral of komparator_4b is

begin

a_gt <= '1' when (A>B) else '0';
b_gt <= '1' when (B>A) else '0';
a_b_eq <= '1' when (A=B) else '0';
a_lo <= '1' when (A<B) else '0';
b_lo <= '1' when (B<A) else '0';



end Behavioral;
