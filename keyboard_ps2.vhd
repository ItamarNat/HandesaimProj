
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyboard_ps2 is
  generic (
    clk_freq : INTEGER := 50000000;
    debounce_counter_size : INTEGER := 8);
  port (
    clk, reset : in STD_LOGIC;
    ps2_clk : in STD_LOGIC;
    ps2_data : in STD_LOGIC;
    ps2_code_new : buffer STD_LOGIC;
    ps2_code : buffer STD_LOGIC_VECTOR(7 downto 0));
end keyboard_ps2;

architecture logic of keyboard_ps2 is

  signal sync_ffs : STD_LOGIC_VECTOR(1 downto 0);
  signal ps2_clk_int : STD_LOGIC;
  signal ps2_data_int : STD_LOGIC;
  signal ps2_word : STD_LOGIC_VECTOR(10 downto 0);
  signal error : STD_LOGIC;
  signal count_idle : INTEGER range 0 to clk_freq/18000;

  
  component debounce is
    generic (
      counter_size : INTEGER); --debounce time 
    port (
      clk : in STD_LOGIC;
      button : in STD_LOGIC;
      result : out STD_LOGIC);
  end component;

begin
  
  process (clk)
  begin
    if (clk'EVENT and clk = '1') then
      sync_ffs(0) <= ps2_clk;
      sync_ffs(1) <= ps2_data;
    end if;
  end process;

  debounce_ps2_clk : debounce
  generic map(counter_size => debounce_counter_size)
  port map(clk => clk, button => sync_ffs(0), result => ps2_clk_int);
  debounce_ps2_data : debounce
  generic map(counter_size => debounce_counter_size)
  port map(clk => clk, button => sync_ffs(1), result => ps2_data_int);

  --get PS2 data
  process (ps2_clk_int)
  begin
    if (ps2_clk_int'EVENT and ps2_clk_int = '0') then
      -- on each PS2 clock (falling edge) get the new data bit into ps2_word
      ps2_word <= ps2_data_int & ps2_word(10 downto 1);
    end if;
  end process;

  -- check if last transaction is finished 
  process (clk, reset)
    variable count : INTEGER := 0;
    variable index : INTEGER := 0;

  begin

    if (clk'EVENT and clk = '1') then

      if (ps2_clk_int = '0') then
        count_idle <= 0;
      elsif (count_idle /= clk_freq/18000) then
        count_idle <= count_idle + 1;
      end if;

      if (count_idle = clk_freq/18000) then
        ps2_code_new <= '1';
        ps2_code <= ps2_word(8 downto 1);

      else 
        ps2_code_new <= '0';
      end if;

    end if;
  end process;

end logic;
