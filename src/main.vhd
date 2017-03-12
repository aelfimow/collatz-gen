library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity main is

    generic (NUM_WIDTH: natural := 8);

    port (
        CLK_I: in bit;
        RST_I: in bit;
        READY_O: out bit;
        COLLATZ_NUM_O: out bit_vector(NUM_WIDTH + 1 downto 0));

end entity main;

architecture ArchMain of main is

    component CollatzGen is

    generic (NUM_WIDTH: natural := 8);

    port (
        CLK_I: in bit;
        RST_I: in bit;
        READY_O: out bit;
        COLLATZ_NUM_O: out bit_vector((NUM_WIDTH + 1) downto 0));

    end component CollatzGen;

    signal CLK: bit;
    signal RST: bit;
    signal COLLATZ_NUM: bit_vector((NUM_WIDTH + 1) downto 0);

begin

    IN_OUT_BLOCK: block
    begin
        CLK <= CLK_I;
        RST <= RST_I;
        COLLATZ_NUM_O <= COLLATZ_NUM;
    end block IN_OUT_BLOCK;

    COLLATZ_GEN_INST: CollatzGen
    generic map (NUM_WIDTH => NUM_WIDTH)
    port map (
        CLK_I => CLK,
        RST_I => RST,
        READY_O => open,
        COLLATZ_NUM_O => COLLATZ_NUM);

end architecture ArchMain;

