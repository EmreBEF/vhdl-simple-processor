LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY add_sub IS 
PORT(
A: in std_logic_vector(8 downto 0);
B: in std_logic_vector(8 downto 0);
Addsub: in std_logic;
S: out std_logic_vector(8 downto 0)
);
end add_sub;

ARCHITECTURE additionneur_soustracteur OF add_sub IS

BEGIN
process(A,B,Addsub)
begin
if Addsub = '0' then
S <= std_logic_vector(unsigned(A) + unsigned(B));
elsif Addsub = '1' then
S <= std_logic_vector(unsigned(A) - unsigned(B));
end if;
end process;

end additionneur_soustracteur;

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY testbench_add IS
end testbench_add;

ARCHITECTURE test_add OF testbench_add IS
signal AT, BT, ST: std_logic_vector (8 DOWNTO 0);
signal Addsub_T: std_logic;

begin 
DUT: Entity work.add_sub(additionneur_soustracteur)
port map(A=>AT, B=>BT, S=>ST, Addsub=>Addsub_T);

-- Début du processus de test --
process
begin

Addsub_T <= '0';
AT <= "100000000";
BT <= "111111111";
wait for 10 ns;

Addsub_T <= '1';
AT <= "100011110";
BT <= "001110000";
wait for 10 ns;

-- Résultat attendu 000111111(63) --
Addsub_T <= '0';
AT <= "000101010";
BT <= "000010101";
wait for 10 ns;

-- Résultat attendu 000000000(troncature, bit de poids fort perdu) --
Addsub_T <= '0';
AT <= "111111111";
BT <= "000000001";
wait for 10 ns;

-- Résultat attendu 001000000(64) --
Addsub_T <= '1';
AT <= "100000000";
BT <= "011000000";
wait for 10 ns;

wait;
end process;
end test_add;


