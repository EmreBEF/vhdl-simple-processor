LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY proc_v2 IS
    PORT (
        Resetn   : IN  STD_LOGIC;
        Clock   : IN  STD_LOGIC;
        Run      : IN  STD_LOGIC;
        Done     : OUT STD_LOGIC;
        BusWires : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
    );
END proc_v2;

ARCHITECTURE Behavior OF proc_v2 IS

    --------------------------------------------------------------------
    -- FSM state
    --------------------------------------------------------------------
    TYPE State_type IS (T0, T1, T2, T3);
    SIGNAL Tstep_Q, Tstep_D : State_type;

    --------------------------------------------------------------------
    -- Instruction + decode
    --------------------------------------------------------------------
    SIGNAL IR   : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL I    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL Xreg : STD_LOGIC_VECTOR(0 TO 7);
    SIGNAL Yreg : STD_LOGIC_VECTOR(0 TO 7);

    --------------------------------------------------------------------
    -- Control signals
    --------------------------------------------------------------------
    SIGNAL Rin     : STD_LOGIC_VECTOR(0 TO 7);
    SIGNAL Rout    : STD_LOGIC_VECTOR(0 TO 7);
    SIGNAL Ain, Gin, Gout, DINout, IRin, AddSub : STD_LOGIC;
    SIGNAL Done_s  : STD_LOGIC;

    --------------------------------------------------------------------
    -- Datapath registers / bus / ALU
    --------------------------------------------------------------------
    SIGNAL R0, R1, R2, R3, R4, R5, R6, R7 : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL A, G, Sum : STD_LOGIC_VECTOR(8 DOWNTO 0);

    SIGNAL Sel          : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL BusWires_int : STD_LOGIC_VECTOR(8 DOWNTO 0);

    --------------------------------------------------------------------
    -- Mémoire, Compteur
    --------------------------------------------------------------------
    SIGNAL PC : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL DIN_int : STD_LOGIC_VECTOR (8 DOWNTO 0);
    

    --------------------------------------------------------------------
    -- Components
    --------------------------------------------------------------------

    COMPONENT counter IS
      PORT (
	Resetn : IN std_logic;                  -- Réinitialisation
        Clock : IN std_logic;                  -- Horloge
        addr   : OUT std_logic_vector(4 DOWNTO 0)  -- Adresse de sortie (5 bits)
      );
    END COMPONENT;

    COMPONENT memory IS
      PORT (
	addr   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);  -- 5 bits pour l'adresse (32 cases)
	Clock : IN  STD_LOGIC;                      -- Horloge pour la mémoire
	data   : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)    -- Données de 9 bits
      );
    END COMPONENT;

    COMPONENT dec3to8 IS
      PORT (
        W  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        En : IN  STD_LOGIC;
        Y  : OUT STD_LOGIC_VECTOR(0 TO 7)
      );
    END COMPONENT;

    COMPONENT registre IS
      PORT(
        Rin : IN  STD_LOGIC;
        Clk : IN  STD_LOGIC;
        R   : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        Q   : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
      );
    END COMPONENT;

    COMPONENT add_sub IS
      PORT(
        A      : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        B      : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        Addsub : IN  STD_LOGIC;
        S      : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
      );
    END COMPONENT;

    COMPONENT mux IS
      PORT(
        Din : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        R0  : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        R1  : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        R2  : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        R3  : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        R4  : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        R5  : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        R6  : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        R7  : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        G   : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        Sel : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        S   : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
      );
    END COMPONENT;

BEGIN
    --------------------------------------------------------------------
    -- IR = [ I(8..6) | X(5..3) | Y(2..0) ]
    --------------------------------------------------------------------
    I <= IR(8 DOWNTO 6);

    decX: dec3to8 PORT MAP(W => IR(5 DOWNTO 3), En => '1', Y => Xreg);
    decY: dec3to8 PORT MAP(W => IR(2 DOWNTO 0), En => '1', Y => Yreg);

    --------------------------------------------------------------------
    -- FSM next-state logic 
    --------------------------------------------------------------------
    statetable: PROCESS (Tstep_Q, Run, I)
    BEGIN
        CASE Tstep_Q IS
            WHEN T0 =>
                IF Run = '0' THEN
                    Tstep_D <= T0;
                ELSE
                    Tstep_D <= T1;
                END IF;

            WHEN T1 =>
                IF (I = "010") OR (I = "011") THEN
                    Tstep_D <= T2;   -- add/sub need more cycles
                ELSE
                    Tstep_D <= T0;   -- mv/mvi finish here
                END IF;

            WHEN T2 =>
                Tstep_D <= T3;

            WHEN T3 =>
                Tstep_D <= T0;
        END CASE;
    END PROCESS;

  --------------------------------------------------------------------
    -- FSM control signals 
    --------------------------------------------------------------------
    controlsignals: PROCESS (Tstep_Q, I, Xreg, Yreg, Run)  
BEGIN
    -- defaults
    Rin    <= (others => '0');
    Rout   <= (others => '0');
    Ain    <= '0';
    Gin    <= '0';
    Gout   <= '0';
    DINout <= '0';
    IRin   <= '0';
    AddSub <= '0';
    Done_s <= '0';

    CASE Tstep_Q IS
        WHEN T0 =>
            IF Run = '1' THEN
                IRin <= '1';
            END IF;

        WHEN T1 =>
            CASE I IS
                WHEN "000" =>  -- mv Rx,Ry
                    Rout   <= Yreg;
                    Rin    <= Xreg;
                    Done_s <= '1';

                WHEN "001" =>  -- mvi Rx,#D
                    DINout <= '1';
                    Rin    <= Xreg;
                    Done_s <= '1';

                WHEN "010" =>  -- add Rx,Ry : Rx -> A
                    Rout <= Xreg;
                    Ain  <= '1';

                WHEN "011" =>  -- sub Rx,Ry : Rx -> A
                    Rout <= Xreg;
                    Ain  <= '1';

                WHEN OTHERS =>
                    NULL;
            END CASE;

        WHEN T2 =>
            -- add/sub step 2: Ry -> ALU, result -> G
            Rout <= Yreg;
            Gin  <= '1';
            IF I = "011" THEN
                AddSub <= '1'; -- subtraction
            END IF;

        WHEN T3 =>
            -- add/sub step 3: G -> Rx
            Gout   <= '1';
            Rin    <= Xreg;
            Done_s <= '1';
    END CASE;
END PROCESS;


    --------------------------------------------------------------------
    -- State register
    --------------------------------------------------------------------
    fsmflipflops: PROCESS (Clock, Resetn)
    BEGIN
        IF Resetn = '0' THEN
            Tstep_Q <= T0;
        ELSIF rising_edge(Clock) THEN
            Tstep_Q <= Tstep_D;
        END IF;
    END PROCESS;

    --------------------------------------------------------------------
    -- Registers
    --------------------------------------------------------------------
    IRreg : entity work.registre(reg) PORT MAP(Rin => IRin, Clk => Clock, R => DIN_int, Q => IR);
    Areg  : registre PORT MAP(Rin => Ain,  Clk => Clock, R => BusWires_int, Q => A);
    Greg  : registre PORT MAP(Rin => Gin,  Clk => Clock, R => Sum,          Q => G);

    reg0 : entity work.registre(reg) PORT MAP(Rin => Rin(0), Clk => Clock, R => BusWires_int, Q => R0);
    reg1 : registre PORT MAP(Rin => Rin(1), Clk => Clock, R => BusWires_int, Q => R1);
    reg2 : registre PORT MAP(Rin => Rin(2), Clk => Clock, R => BusWires_int, Q => R2);
    reg3 : registre PORT MAP(Rin => Rin(3), Clk => Clock, R => BusWires_int, Q => R3);
    reg4 : registre PORT MAP(Rin => Rin(4), Clk => Clock, R => BusWires_int, Q => R4);
    reg5 : registre PORT MAP(Rin => Rin(5), Clk => Clock, R => BusWires_int, Q => R5);
    reg6 : registre PORT MAP(Rin => Rin(6), Clk => Clock, R => BusWires_int, Q => R6);
    reg7 : registre PORT MAP(Rin => Rin(7), Clk => Clock, R => BusWires_int, Q => R7);

    --------------------------------------------------------------------
    -- ALU
    --------------------------------------------------------------------
    addunit : add_sub PORT MAP(A => A, B => BusWires_int, Addsub => AddSub, S => Sum);

    --------------------------------------------------------------------
    -- Mux selection vector (one-hot) : R0..R7, G, DIN
    -- Sel(9)=R0 ... Sel(2)=R7, Sel(1)=G, Sel(0)=DIN
    --------------------------------------------------------------------
    Sel(9) <= Rout(0);
    Sel(8) <= Rout(1);
    Sel(7) <= Rout(2);
    Sel(6) <= Rout(3);
    Sel(5) <= Rout(4);
    Sel(4) <= Rout(5);
    Sel(3) <= Rout(6);
    Sel(2) <= Rout(7);
    Sel(1) <= Gout;
    Sel(0) <= DINout;

    mux_inst : mux PORT MAP(Din => DIN_int,R0  => R0, R1 => R1, R2 => R2, R3 => R3, R4  => R4, R5 => R5, R6 => R6, R7 => R7,G   => G, Sel => Sel, S   => BusWires_int);



    --------------------------------------------------------------------
    -- Mémoire, Compteur
    --------------------------------------------------------------------
 

    PC_inst : counter PORT MAP(Resetn => Resetn, Clock => Clock, addr => PC);

    ROM_inst : memory PORT MAP(addr => PC, Clock => Clock, data => DIN_int);


    --------------------------------------------------------------------
    -- Outputs
    --------------------------------------------------------------------
    Done     <= Done_s;
    BusWires <= BusWires_int;

END Behavior;

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY testbench_proc_v2 IS
END testbench_proc_v2;

ARCHITECTURE test_proc_v2 OF testbench_proc_v2 IS
  SIGNAL Resetn_T   : STD_LOGIC := '0';
  SIGNAL Clock_T   : STD_LOGIC := '0';
  SIGNAL Run_T      : STD_LOGIC := '0';
  SIGNAL Done_T     : STD_LOGIC;
  SIGNAL BusWires_T : STD_LOGIC_VECTOR(8 DOWNTO 0);

BEGIN

  DUT: ENTITY work.proc_v2
    PORT MAP(
      Resetn   => Resetn_T,
      Clock   => Clock_T,
      Run      => Run_T,
      Done     => Done_T,
      BusWires => BusWires_T
    );


Clock_process : PROCESS
BEGIN
    Clock_T <= '0'; wait for 20 ns;
    Clock_T <= '1'; wait for 20 ns;
END PROCESS;


stimulus : PROCESS
BEGIN
    -- RESET
    Resetn_T <= '0';
    Run_T    <= '0';
    wait for 20 ns;

    Resetn_T <= '1';   -- fin du reset
    wait for 10 ns;

    -- Lancer le processeur
    Run_T <= '1';

    -- Laisser tourner le programme en ROM
    wait for 500 ns;

    -- Arrêter (optionnel)
    Run_T <= '0';

    wait;
END PROCESS;

END test_proc_v2;
