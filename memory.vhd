LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY memory IS
PORT(
addr   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);  -- 5 bits pour l'adresse (32 cases)
Clock : IN  STD_LOGIC;                      -- Horloge pour la mémoire
data   : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)    -- Données de 9 bits
);

END memory;

ARCHITECTURE ROM_str of memory IS
    type ROM_type is array(31 DOWNTO 0) of std_logic_vector(8 DOWNTO 0);
    signal ROM: ROM_type;
begin
    -- Remplir la mémoire avec des valeurs intéressantes
    ROM(31) <= "000000000";  )
    ROM(30) <= "000000001";  
    ROM(29) <= "000000010";  
    ROM(28) <= "000000011";  
    ROM(27) <= "000001000";  
    ROM(26) <= "000001001";  
    ROM(25) <= "000001010";  
    ROM(24) <= "000001011";  
    ROM(23) <= "000010000";  
    ROM(22) <= "001001010";  
    ROM(21) <= "010000001";  
    ROM(20) <= "011000001";  
    ROM(19) <= "000010001";  
    ROM(18) <= "000010010";  
    ROM(17) <= "001000000";  
    ROM(16) <= "001001111";  
    ROM(15) <= "010001100";  
    ROM(14) <= "011001100";  
    ROM(13) <= "000010011";  
    ROM(12) <= "001000010";  
    ROM(11) <= "010000011";  
    ROM(10) <= "011000011";  
    ROM(9)  <= "000001100";  
    ROM(8)  <= "001001100";  
    ROM(7)  <= "010000100";  
    ROM(6)  <= "011000100";  
    ROM(5)  <= "010000010";  
    ROM(4)  <= "010000010";  
    ROM(3)  <= "001110000";  
    ROM(2)  <= "001000000";  
    ROM(1)  <= "001000000";  
    ROM(0)  <= "001010101";  


PROCESS(Clock)
    BEGIN
        IF rising_edge(Clock) THEN
            data <= ROM(to_integer(unsigned(addr)));  -- Lecture de la ROM
        END IF;
    END PROCESS;
END ROM_str;

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY testbench_ROM IS
end testbench_ROM;

ARCHITECTURE test_ROM OF testbench_ROM IS
signal addr_T: std_logic_vector(4 DOWNTO 0);
signal data_T: std_logic_vector(8 DOWNTO 0);
signal Clock_T : std_logic;

begin 
DUT: Entity work.memory(ROM_str)
port map(addr=>addr_T, data=>data_T, Clock=>Clock_T);

-- Début du processus de test --

MClock_T_process : process
begin
    Clock_T <= '0';
    wait for 10 ns;
    Clock_T <= '1';
    wait for 10 ns;
end process;

process
begin

addr_T <= "00000"; -- 000010101
wait for 20 ns;

addr_T <= "00001"; -- 000010100
wait for 20 ns;

addr_T <= "00010"; -- 000001111
wait for 20 ns;

addr_T <= "11000"; -- 000001011
wait for 20 ns;

addr_T <= "11111"; -- 000000000
wait for 20 ns;

end process;

end test_ROM;
