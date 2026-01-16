LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY proc IS
    PORT (
        DIN      : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        Resetn   : IN  STD_LOGIC;
        Clock    : IN  STD_LOGIC;
        Run      : IN  STD_LOGIC;
        Done     : OUT STD_LOGIC;
        BusWires : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
    );
END proc;

ARCHITECTURE Behavior OF proc IS

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
    -- Components
    --------------------------------------------------------------------
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
    IRreg : registre PORT MAP(Rin => IRin, Clk => Clock, R => DIN,          Q => IR);
    Areg  : registre PORT MAP(Rin => Ain,  Clk => Clock, R => BusWires_int, Q => A);
    Greg  : registre PORT MAP(Rin => Gin,  Clk => Clock, R => Sum,          Q => G);

    reg0 : registre PORT MAP(Rin => Rin(0), Clk => Clock, R => BusWires_int, Q => R0);
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
    Sel <= Rout(0) & Rout(1) & Rout(2) & Rout(3) & Rout(4) & Rout(5) & Rout(6) & Rout(7) & Gout & DINout;

    mux_inst : mux PORT MAP(
        Din => DIN,
        R0  => R0, R1 => R1, R2 => R2, R3 => R3,
        R4  => R4, R5 => R5, R6 => R6, R7 => R7,
        G   => G,
        Sel => Sel,
        S   => BusWires_int
    );

    --------------------------------------------------------------------
    -- Outputs
    --------------------------------------------------------------------
    Done     <= Done_s;
    BusWires <= BusWires_int;

END Behavior;

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY testbench_proc IS
END testbench_proc;

ARCHITECTURE test_proc OF testbench_proc IS
  SIGNAL DIN_T      : STD_LOGIC_VECTOR(8 DOWNTO 0) := (others => '0');
  SIGNAL Resetn_T   : STD_LOGIC := '0';
  SIGNAL Clock_T    : STD_LOGIC := '0';
  SIGNAL Run_T      : STD_LOGIC := '0';
  SIGNAL Done_T     : STD_LOGIC;
  SIGNAL BusWires_T : STD_LOGIC_VECTOR(8 DOWNTO 0);
BEGIN

  DUT: ENTITY work.proc
    PORT MAP(
      DIN      => DIN_T,
      Resetn   => Resetn_T,
      Clock    => Clock_T,
      Run      => Run_T,
      Done     => Done_T,
      BusWires => BusWires_T
    );

  -- Horloge 20 ns (comme toi)
  Clock_T_process : PROCESS
  BEGIN
    Clock_T <= '0';
    wait for 10 ns;
    Clock_T <= '1';
    wait for 10 ns;
  END PROCESS Clock_T_process;

  -- Stimulus (même style que toi : wait for XX ns)
  PROCESS
  BEGIN
    ------------------------------------------------------------------
    -- RESET
    ------------------------------------------------------------------
    Resetn_T <= '0';
    Run_T    <= '0';
    DIN_T    <= (others => '0');
    wait for 40 ns;

    Resetn_T <= '1';
    wait for 40 ns;

    ------------------------------------------------------------------
    -- 1) mvi R0, #10
    --    T0: DIN = instruction, Run=1 (passe en T1)
    --    T1: DIN = immédiat (chargé dans R0)
    ------------------------------------------------------------------
    Run_T <= '1';
    DIN_T <= "001000000";        -- mvi Rx=# : opcode=001, X=000 (R0), Y=000 (don?t care)
    wait for 20 ns;              -- 1 cycle : T0 -> T1

    Run_T <= '0';
    DIN_T <= "000001010";        -- #10 (immédiat lu en T1)
    wait for 40 ns;              -- laisse revenir à T0 proprement

    ------------------------------------------------------------------
    -- 2) mvi R1, #5
    ------------------------------------------------------------------
    Run_T <= '1';
    DIN_T <= "001001000";        -- mvi, X=001 (R1)
    wait for 20 ns;

    Run_T <= '0';
    DIN_T <= "000000101";        -- #5
    wait for 40 ns;

    ------------------------------------------------------------------
    -- 3) mv R2, R0   (R2 <- R0)
    --    mv finit en T1 (1 cycle d?exécution)
    ------------------------------------------------------------------
    Run_T <= '1';
    DIN_T <= "000010000";        -- mv : opcode=000, X=010 (R2), Y=000 (R0)
    wait for 20 ns;              -- T0 -> T1 (mv exécuté)
    Run_T <= '0';
    wait for 40 ns;              -- retour T0 + marge

    ------------------------------------------------------------------
    -- 4) add R0, R1   (R0 <- R0 + R1)
    --    add prend 3 cycles d?exécution : T1, T2, T3
    ------------------------------------------------------------------
    Run_T <= '1';
    DIN_T <= "010000001";        -- add : opcode=010, X=000 (R0), Y=001 (R1)
    wait for 20 ns;              -- T0 -> T1
    Run_T <= '0';
    wait for 60 ns;              -- T2 + T3 (2 cycles) => total 3 cycles après T0

    wait for 40 ns;              -- marge

    ------------------------------------------------------------------
    -- 5) sub R0, R1   (R0 <- R0 - R1) => doit revenir à 10
    --    sub prend aussi 3 cycles
    ------------------------------------------------------------------
    Run_T <= '1';
    DIN_T <= "011000001";        -- sub : opcode=011, X=000 (R0), Y=001 (R1)
    wait for 20 ns;              -- T0 -> T1
    Run_T <= '0';
    wait for 60 ns;              -- T2 + T3

    wait for 100 ns;

    wait;
  END PROCESS;

END test_proc;

