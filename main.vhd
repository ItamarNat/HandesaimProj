library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ps2_pkg.all;
use work.test_db_pkg.all;



entity main is
    generic (
        counter_size 	: integer := 19
        );
        
    port(
        clk, reset     : in std_logic;
        ps2_clk				: in STD_LOGIC;
        ps2_data 			: in STD_LOGIC;
         RGB 				: out STD_LOGIC_VECTOR(11 downto 0);
         hsync, vsync 		: out STD_LOGIC
    );
end main;


architecture arch of main is

    attribute chip_pin 					: STRING;
	attribute chip_pin of clk 			: signal is "l1";
	attribute chip_pin of reset 		: signal is "l22";
	attribute chip_pin of ps2_clk 	    : signal is "H15";
	attribute chip_pin of ps2_data 	    : signal is "J14";
	---------------------------------------------------------
  -- vga			
												-------red------/------green------/------blue--------
	attribute chip_pin of RGB 		: signal is "d9 ,c9 ,a7 ,b7 ,b8 ,c10 , b9, a8, a9, d11, a10, b10";
	attribute chip_pin of hsync 	: signal is "A11";
	attribute chip_pin of vsync 	: signal is "B11";
  
	----------------------- test_flow ------------------------
	signal test_result			: std_logic_vector(2 downto 0);
	signal current_state_num	: std_logic_vector(2 downto 0);
	signal counter_out_p			: std_logic_vector(counter_size downto 0);
	signal test_addr				: std_logic_vector(2 downto 0);
	signal enable_test				: std_logic;
	signal result_vec_4_6_7			: std_logic_vector(15 downto 0);
	signal result_vec_4_6_9			: std_logic_vector(15 downto 0);
	    
    ----------------------------------------------

    component keyboard_matrix is
       
    port(
        clk, reset			: in std_logic;
        result_vec_4_6_7	: in std_logic_vector(15 downto 0);
        result_vec_4_6_9	: in std_logic_vector(15 downto 0);
        ps2_clk				: in STD_LOGIC;
        ps2_data 			: in STD_LOGIC;
        RGB 				: out std_logic_vector(11 downto 0);
        hsync, vsync 		: out std_logic;
        test_addr			: out std_logic_vector(2 downto 0) := "111";
		enable_test			: out std_logic := '0'
       );
    end component;
    

    component test_flow
        port(
            test_addr				: in std_logic_vector(2 downto 0);
            clk						: in std_logic;
            enable_test				: in std_logic;
            test_result				: out std_logic_vector(2 downto 0);
            current_state_num		: out std_logic_vector(2 downto 0);
            counter_out_p			: out std_logic_vector(counter_size downto 0);
            result_vec_4_6_7		: out std_logic_vector(15 downto 0);
            result_vec_4_6_9		: out std_logic_vector(15 downto 0)
        );	
    end component;


   
--------------------------------------------------------
    
begin


    keyboard : keyboard_matrix
    port map(
        clk         => clk,
        reset       => reset,
        RGB         => RGB,
        hsync       => hsync,
        vsync       => vsync,
        ps2_clk     => ps2_clk,
        ps2_data    => ps2_data,
        result_vec_4_6_7 => result_vec_4_6_7,	
        result_vec_4_6_9 => result_vec_4_6_9,
        test_addr => test_addr,
		enable_test	=> enable_test
    );

	 
	test : test_flow
	port map (
		test_addr				=> test_addr,
		clk 					=> clk,
		enable_test				=> enable_test,
		test_result				=> test_result,
		current_state_num 	=> current_state_num,
		counter_out_p 			=> counter_out_p,
		result_vec_4_6_7		=> result_vec_4_6_7,
		result_vec_4_6_9		=> result_vec_4_6_9
	);


end architecture;
