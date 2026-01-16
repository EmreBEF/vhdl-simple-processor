LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;


ENTITY registre IS
port(
Rin,Clk:in std_logic;
R:in std_logic_vector(8 downto 0);
Q:out std_logic_vector(8 downto 0)
);
end registre;

architecture reg of registre is 
signal Q_reg : std_logic_vector(8 downto 0);
begin
process(Clk)
begin
if rising_edge(Clk) then
if Rin = '1' then
Q_reg <= R;
end if;
end if;
end process;

Q <= Q_reg;

end reg;

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY testbench IS 
END testbench;

architecture test of testbench IS
signal Rin_T, Clk_T:std_logic:='0';
signal RT : std_logic_vector (8 DOWNTO 0) := (others => '0');
signal QT : std_logic_vector (8 DOWNTO 0);

begin
DUT: Entity work.registre(reg)
port map(Rin=>Rin_T, R=>RT, Clk=>Clk_T, Q=>QT);

Clk_T_process : process
begin
    Clk_T <= '0';
    wait for 10 ns;
    Clk_T <= '1';
    wait for 10 ns;
end process;

process
begin
Rin_T <= '0';
RT <= "000000001";
wait for 15 ns;

Rin_T <= '1';
RT <= "111111111";
wait for 15 ns;

Rin_T <= '0';
RT <= "101010101";
wait for 15 ns;

Rin_T <= '1';
RT <= "010101010";
wait for 20 ns;

wait;
end process;

end test;
