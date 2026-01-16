LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY mux IS 
PORT(
Din, R0, R1, R2, R3, R4, R5, R6, R7, G:in std_logic_vector(8 downto 0);
Sel: in std_logic_vector(9 downto 0);
S: out std_logic_vector(8 downto 0)
);
end mux;

ARCHITECTURE multiplexeur OF mux IS

begin
with Sel select
S <= R0  when "1000000000",
R1  when "0100000000",
R2  when "0010000000",
R3  when "0001000000",
R4  when "0000100000",
R5  when "0000010000",
R6  when "0000001000",
R7  when "0000000100",
G   when "0000000010",
Din when "0000000001", 
(others => '0') when others;  
end multiplexeur;

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY testbench1 IS 
END testbench1;

architecture test1 of testbench1 IS
signal R0T, R1T, R2T, R3T, R4T, R5T, R6T, R7T, GT, DinT: std_logic_vector(8 DOWNTO 0):= (others => '0');
signal Sel_T: std_logic_vector(9 downto 0);
signal S_T: std_logic_vector(8 downto 0);

begin
DUT: Entity work.mux
port map(Din => DinT, R0 => R0T, R1 => R1T, R2 => R2T, R3 => R3T, R4 => R4T, R5 => R5T, R6 => R6T, R7 => R7T, G => GT, Sel => Sel_T, S => S_T);

-- Processus de test
process
begin
-- Initialisation des valeurs pour R0T, R1T, R2T, etc.
DinT <= "011100000";
R0T <= "000000001";  -- Exemple de données pour R0
R1T <= "000000010";  -- Exemple de données pour R1
R2T <= "000000011";
R3T <= "100000010";
R4T <= "101000000";

-- Ajouter les affectations pour R2T, R3T, etc. selon besoin

-- Test des valeurs du signal Sel
Sel_T <= "1000000000"; -- Test pour R0
wait for 20 ns;

Sel_T <= "0100000000"; -- Test pour R1
wait for 20 ns;

Sel_T <= "0010000000"; -- Test pour R2
wait for 20 ns;

Sel_T <= "0001000000"; -- Test pour R3
wait for 20 ns;

Sel_T <= "0000100000"; -- Test pour R4
wait for 20 ns;

Sel_T <= "0000000001";
wait for 20 ns;

wait;
end process;
END test1;