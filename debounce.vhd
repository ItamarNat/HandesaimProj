--------------------------------------------------------------------------------
--
--   FileName:         debounce.vhd
--   Dependencies:     none
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity debounce is
  generic (
    counter_size : INTEGER := 19); --counter size (19 bits gives 10.5ms with 50MHz clock)
  port (
    clk : in STD_LOGIC; --input clock
    button : in STD_LOGIC; --input signal to be debounced
    result : out STD_LOGIC); --debounced signal
end debounce;

architecture logic of debounce is
  signal flipflops : STD_LOGIC_VECTOR(1 downto 0); --input flip flops
  signal counter_set : STD_LOGIC; --sync reset to zero
  signal counter_out : STD_LOGIC_VECTOR(counter_size downto 0) := (others => '0'); --counter output
begin

  counter_set <= flipflops(0) xor flipflops(1); --determine when to start/reset counter

  process (clk)
  begin
    if (clk'EVENT and clk = '1') then
      flipflops(0) <= button;
      flipflops(1) <= flipflops(0);
      if (counter_set = '1') then --reset counter because input is changing
        counter_out <= (others => '0');
      elsif (counter_out(counter_size) = '0') then --stable input time is not yet met
        counter_out <= counter_out + 1;
      else --stable input time is met
        result <= flipflops(1);
      end if;
    end if;
  end process;
end logic;