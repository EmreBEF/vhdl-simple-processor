LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY counter IS
    PORT(
        Resetn : IN std_logic;                  -- Réinitialisation
        Clock : IN std_logic;                  -- Horloge
        addr   : OUT std_logic_vector(4 DOWNTO 0)  -- Adresse de sortie (5 bits)
    );
END counter;

ARCHITECTURE addr_counter OF counter IS
    -- Déclaration du compteur de 0 à 31 (compteur mod 32)
    SIGNAL count : INTEGER RANGE 0 TO 31 := 0;
BEGIN

    -- Processus pour gérer l'incrémentation et la réinitialisation
    PROCESS(Clock, Resetn)
    BEGIN
        IF Resetn = '0' THEN
            count <= 0;  -- Réinitialisation du compteur à 0
        ELSIF rising_edge(Clock) THEN
            IF count = 31 THEN
                count <= 0;  -- Retour à 0 lorsque le compteur atteint 31
            ELSE
                count <= count + 1;  -- Incrémentation du compteur
            END IF;
        END IF;
    END PROCESS;

    -- Conversion du compteur en une adresse à 5 bits
    addr <= std_logic_vector(to_unsigned(count, 5));  -- Conversion de l'entier en std_logic_vector

END addr_counter;

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY testbench_counter IS
end testbench_counter;

ARCHITECTURE test_counter OF testbench_counter IS
signal Resetn_T : std_logic;
signal Clock_T : std_logic;
signal addr_T : std_logic_vector(4 DOWNTO 0);

begin
DUT : Entity work.counter(addr_counter)
port map(addr=>addr_T, Resetn=>Resetn_T, Clock=>Clock_T);

 -- Processus de génération de l'horloge
    MClock_process : PROCESS
    BEGIN
        Clock_T <= '0';  -- Initialisation
        WAIT FOR 10 ns;
        Clock_T <= '1';
        WAIT FOR 10 ns;
    END PROCESS;

    -- Processus pour appliquer les stimuli de réinitialisation et observer l'évolution du compteur
    stimulus_process : PROCESS
    BEGIN
        -- Réinitialisation
        Resetn_T <= '0';  -- Initialisation de Resetn à 0
        WAIT FOR 20 ns;    -- Attente pour l'effet de Resetn
        Resetn_T <= '1';  -- Réinitialisation terminée
        WAIT FOR 40 ns;    -- Observation après réinitialisation

        -- Simuler les changements de l'adresse pendant plusieurs cycles d'horloge
        WAIT FOR 200 ns;    -- Laisser passer 200 ns pour observer l'incrémentation du compteur

        -- Tester la réinitialisation du compteur
        Resetn_T <= '0';    -- Réinitialiser à 0
        WAIT FOR 20 ns;     -- Attendre la réinitialisation
        Resetn_T <= '1';    -- Fin de la réinitialisation
        WAIT FOR 200 ns;    -- Laisser passer 200 ns après la réinitialisation

        WAIT;
    END PROCESS;
END test_counter;

