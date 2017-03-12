library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity CollatzGen is

    generic (NUM_WIDTH: natural := 8);

    port (
        CLK_I: in bit;
        RST_I: in bit;
        READY_O: out bit;
        COLLATZ_NUM_O: out bit_vector((NUM_WIDTH + 1) downto 0));

end entity CollatzGen;

architecture ArchCollatzGen of CollatzGen is

    constant Zero: bit_vector(NUM_WIDTH downto 0) := (others => '0');

    signal StartNum: bit_vector((NUM_WIDTH - 1) downto 0);
    signal NextNum: bit_vector((NUM_WIDTH - 1) downto 0);

    signal GenNum: bit_vector((NUM_WIDTH + 1) downto 0);
    signal EvenCaseNum: bit_vector((NUM_WIDTH + 1) downto 0);
    signal OddCaseNum: bit_vector((NUM_WIDTH + 1) downto 0);

    signal IsCaseEven: boolean;
    signal IsEvenEnd: boolean;
    signal IsOddEnd: boolean;

    signal Ready: bit;

    signal CLK: bit;
    signal RST: bit;

    type Tstates is (
        SRESET,
        SVALIDATE,
        SLOAD,
        SCHECK,
        SRELOAD,
        SREADY);

    signal state: Tstates;

begin

    -- This block maps global signals to local one.
    IN_OUT_BLOCK: block
    begin
        CLK <= CLK_I;
        RST <= RST_I;
        READY_O <= Ready;
        COLLATZ_NUM_O <= GenNum;
    end block IN_OUT_BLOCK;

    -- This process computes next number for starting generation of
    -- Collatz numbers.
    -- Next number is just incremented current number.
    NextNumProc: process(StartNum)
        variable tmp: std_logic_vector((NUM_WIDTH - 1) downto 0);
        variable result: unsigned((NUM_WIDTH - 1) downto 0);
    begin
        tmp := To_StdLogicVector(StartNum);
        result := unsigned(tmp) + 1;
        NextNum <= To_bitvector(std_logic_vector(result));
    end process NextNumProc;

    -- This process computes number for even case.
    -- Next number is just a half of original number and this
    -- is a right shift operation.
    NextEvenCaseNumProc: process(GenNum)
    begin
        EvenCaseNum(NUM_WIDTH + 1) <= '0';
        EvenCaseNum(NUM_WIDTH downto 0) <= GenNum((NUM_WIDTH + 1) downto 1);
    end process NextEvenCaseNumProc;

    -- This process computes next number for odd case.
    -- Next number is (3x + 1) and this is (2x + x + 1).
    -- 2x is a left shift operation, over steps are simple
    -- additions.
    NextOddCaseNumProc: process(GenNum)
        variable num: bit_vector((NUM_WIDTH + 1) downto 0);
        variable tmp_a: std_logic_vector((NUM_WIDTH + 1) downto 0);
        variable tmp_b: std_logic_vector((NUM_WIDTH + 1) downto 0);
        variable result_a: unsigned((NUM_WIDTH + 1) downto 0);
        variable sum: unsigned((NUM_WIDTH + 1) downto 0);
    begin
        tmp_a := To_StdLogicVector(GenNum);
        result_a := unsigned(tmp_a) + 1;    -- result_a is (x + 1)
        num(0) := '0';
        num((NUM_WIDTH + 1) downto 1) := GenNum(NUM_WIDTH downto 0);
        tmp_a := To_StdLogicVector(num);    -- tmp_a is (2x)
        sum := unsigned(tmp_a) + result_a;  -- (2x + x + 1)
        OddCaseNum <= To_bitvector(std_logic_vector(sum));
    end process NextOddCaseNumProc;

    -- This process checks, if next even case number is equal to 1.
    IsEvenEndProc: process(EvenCaseNum)
    begin
        if (EvenCaseNum(0) = '1') and (EvenCaseNum((NUM_WIDTH + 1) downto 1) = Zero) then
            IsEvenEnd <= true;
        else
            IsEvenEnd <= false;
        end if;
    end process IsEvenEndProc;

    -- This process checks, if next odd case number is equal to 1.
    IsOddEndProc: process(OddCaseNum)
    begin
        if (OddCaseNum(0) = '1') and (OddCaseNum((NUM_WIDTH + 1) downto 1) = Zero) then
            IsOddEnd <= true;
        else
            IsOddEnd <= false;
        end if;
    end process IsOddEndProc;

    -- This process determines, if current number is odd
    -- or even and sets corresponding flag.
    DetermineCaseProc: process(GenNum)
    begin
        if GenNum(0) = '0' then
            IsCaseEven <= true;
        else
            IsCaseEven <= false;
        end if;
    end process DetermineCaseProc;

    -- This process realizes the main state machine.
    process(CLK, RST)
    begin
        if CLK = '1' and CLK'event then
            if RST = '1' then
                StartNum <= (others => '0');
                GenNum <= (others => '0');
                state <= SRESET;
                Ready <= '0';
            else
                StartNum <= StartNum;
                GenNum <= GenNum;
                Ready <= '0';
                state <= SRESET;
                case state is
                    when SRESET =>
                        state <= SVALIDATE;
                        null;
                    when SVALIDATE =>
                        StartNum <= NextNum;
                        state <= SLOAD;
                        null;
                    when SLOAD =>
                        GenNum(NUM_WIDTH + 1) <= '0';
                        GenNum(NUM_WIDTH) <= '0';
                        GenNum((NUM_WIDTH - 1) downto 0) <= StartNum;
                        state <= SCHECK;
                        null;
                    when SCHECK =>
                        if IsEvenEnd = true or IsOddEnd = true then
                            state <= SREADY;
                        else
                            state <= SRELOAD;
                        end if;
                        null;
                    when SRELOAD =>
                        state <= SCHECK;
                        if IsCaseEven = true then
                            GenNum <= EvenCaseNum;
                        else
                            GenNum <= OddCaseNum;
                        end if;
                        null;
                    when SREADY =>
                        state <= SVALIDATE;
                        Ready <= '1';
                        null;
                    when others =>
                        state <= SRESET;
                        null;
                end case;
            end if;
        end if;
    end process;

end architecture ArchCollatzGen;

