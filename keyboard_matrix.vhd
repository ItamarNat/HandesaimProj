library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ps2_pkg.all;
use work.test_db_pkg.all;



entity keyboard_matrix is
		
   port(
	clk, reset			: in std_logic;
	result_vec_4_6_7	: in std_logic_vector(15 downto 0);
	result_vec_4_6_9	: in std_logic_vector(15 downto 0);
	ps2_clk				: in STD_LOGIC;
   	ps2_data 			: in STD_LOGIC;
	RGB 				: out STD_LOGIC_VECTOR(11 downto 0);
	hsync, vsync 		: out STD_LOGIC;
	enable_test			: out std_logic;
	test_addr			: out std_logic_vector(2 downto 0)
   );
end keyboard_matrix;

architecture arch of keyboard_matrix is

	------------------------------------------------
	
	signal pixel_x : STD_LOGIC_VECTOR (9 downto 0); -- 10 bit
	signal pixel_y : STD_LOGIC_VECTOR (9 downto 0); -- 10 bit
	

	signal data_out	: std_logic_vector(7 downto 0);
	signal font_bit : std_logic;
	
	signal video_on	: std_logic;
	
	signal ascii_char	: std_logic_vector (6 downto 0);

 	
	----------------------------- stete machine --------------

	type machine is (ready, new_code, translate, output); 
	signal state : machine; 

	type screens is (home_screen, menu, run_all, select_test, test_4_6_7, test_4_6_9);
	signal screen_select : screens := home_screen;

	type text_boxes is (text_box_one, text_box_two, text_box_three);
	signal text_box_select : text_boxes; 

	----------------------------------------------------------  
  
	signal ps2_code_new 					: std_logic; 
	signal ps2_code 						: std_logic_vector(7 downto 0);
	signal prev_ps2_code_new 				: std_logic := '1';
	signal break 							: std_logic := '0'; 
	signal ascii 							: std_logic_vector(7 downto 0) := x"FF"; 

	
	----------------------------------------------------------
	
	type matrix is array (0 to 29) of string (1 to 80); -- matrix 80x30
	signal font_matrix : matrix;
	signal char :character;
	signal line_temp :string (1 to 80);
	signal char_p_x, char_p_y, char_key_nav : integer range 1 to 2048;
	signal addr_code : std_logic_vector (10 downto 0);

	signal text_box : string (1 to 55);
	signal text_box0 : string (1 to 55);
	signal text_box1 : string (1 to 55);
	
	----------------------------------------------
	
	component font_rom is
		port(
			clk: in std_logic;
			addr: in std_logic_vector(10 downto 0);
			data: out std_logic_vector(7 downto 0)
			);
	end component;

	component vga_sync is
	port (
		clk, reset 			: in std_logic;
		hsync, vsync 		: out std_logic;
		pixel_x, pixel_y 	: out std_logic_vector (9 downto 0);
		video_on			: out std_logic
	);
   end component;	
   
   component ps2_keyboard is
		 generic (
			clk_freq 				: INTEGER; 
			debounce_counter_size 	: INTEGER); 
		 port (
			clk 			: in STD_LOGIC;
			ps2_clk 		: in STD_LOGIC;
			ps2_data 		: in STD_LOGIC;
			ps2_code_new 	: out STD_LOGIC;
			ps2_code 		: out STD_LOGIC_VECTOR(7 downto 0));
	end component;

	
	--------------------------------------------------------
		
begin
   ---------------- instantiate font ROM ---------------- 
   font_unit: entity work.font_rom
		port map(clk=>clk, addr => addr_code, data=>data_out);
	------------------------------------------------------

	-- addr <= rom_addr

	sync : vga_sync port map(
		clk => clk,
		hsync => hsync,
		vsync => vsync,
		reset => reset,
		pixel_x => pixel_x,
		pixel_y => pixel_y,
		video_on => video_on
		);

	keyboard_ps2_0 : entity work.keyboard_ps2(logic)
    port map(clk => clk,
		 reset => reset,
		 ps2_clk => ps2_clk,
		 ps2_data => ps2_data,
		 ps2_code_new => ps2_code_new,
		 ps2_code => ps2_code
	 );
	 

	char_p_x <=  to_integer(unsigned(pixel_x(9 downto 3))); -- get current char column in screen
	char_p_y <=  to_integer(unsigned(pixel_y(8 downto 4))); -- get current char raw in screen

	line_temp <= font_matrix(char_p_y); -- get the corresponding string for the current line
	char <= (line_temp(char_p_x));		-- get current char from string
	ascii_char <= key2ascii(char);
	addr_code <= ascii_char & pixel_y(3 downto 0); -- send ascii to fontRom
	
	-- set font_bit if char pixel is on  
	font_bit	<= data_out(to_integer(unsigned(not(pixel_x(2 downto 0))))+1) when pixel_x(2 downto 0)="000" else
					 data_out(to_integer(unsigned(not(pixel_x(2 downto 0))))+1);
				
	
	
	process (clk)
		variable key_nav : std_logic_vector (7 downto 0) := key_code2char(ps2_code).ascii; 
		variable index : INTEGER := 0;
		variable c1 : INTEGER := 0;
		variable counter : INTEGER := 0;
  	begin
	if (rising_edge(clk)) then
		
		prev_ps2_code_new <= ps2_code_new;
		case state is
	
			when ready =>
			if (prev_ps2_code_new = '0' and ps2_code_new = '1') then 
				state <= new_code;
			else 
				state <= ready;
			end if;
	
			when new_code =>
			if (ps2_code = x"F0") then -- got break
				break <= '1';
				state <= ready; 
			else --code after make,break
				ascii(7) <= '1';
				state <= translate;
			end if;
	
			when translate =>
			break <= '0'; 
			
			ascii <= key_code2char(ps2_code).ascii; -- get ascii code from ps2 data
	
			if (break = '0') then --the code is a make
				state <= output; 
			else --code is a break
				state <= ready; -- wait for next PS2 data
			end if;
	
			when output =>
			if (ascii(7) = '0') then

					case text_box_select is
						when text_box_one => -- first text box
							if (ascii = x"08") then -- backspace
								text_box(index) <= ' ';
								index := index - 1;
								text_box(index) <= '_';
							elsif (ascii = x"0D") then -- enter was pressed
								text_box(index) <= ' ';
								index := 0;
								text_box_select <= text_box_two;
							elsif (ascii = x"5D") then -- ]
								text_box(index) <= ' ';
								index := 0;
								text_box_select <= text_box_one;
							else
								text_box(index) <= key_code2char(ps2_code).c;
								index := index + 1; -- move to next position in string
								text_box(index) <= '_';
								if (index = 80) then -- end of line
									index := 0;
								end if;	
							end if;
						
						when text_box_two =>
							if (ascii = x"08") then -- backspace
								text_box0(index) <= ' ';
								index := index - 1;
								text_box0(index) <= '_';
							elsif (ascii = x"0D") then -- enter was pressed
								text_box0(index) <= ' ';
								index := 0;
								text_box_select <= text_box_three;
							elsif (ascii = x"5D") then -- ]
								text_box0(index) <= ' ';
								index := 0;
								text_box_select <= text_box_one;
							else
								text_box0(index) <= key_code2char(ps2_code).c;
								index := index + 1; -- move to next position in string
								text_box0(index) <= '_';
								if (index = 80) then -- end of line
									index := 0;
								end if;	
							end if;	
							
						when text_box_three =>
							if (ascii = x"08") then -- backspace
								text_box1(index) <= ' ';
								index := index - 1;
								text_box1(index) <= '_';
							elsif (ascii = x"0D") then -- enter was pressed
								text_box1(index) <= ' ';
								index := 0;
								text_box_select <= text_box_two;
							elsif (ascii = x"5D") then -- ]
								text_box1(index) <= ' ';
								index := 0;
								text_box_select <= text_box_two;
							else
								text_box1(index) <= key_code2char(ps2_code).c;
								index := index + 1; -- move to next position in string
								text_box1(index) <= '_';
								if (index = 80) then -- end of line
									index := 0;
								end if;	
							end if;	
					end case;		
				end if;
			state <= ready; --return to ready state to await next PS2 code
	
		end case;
		
			case screen_select is -- Screen SM (UI)
				when home_screen =>
					font_matrix(0)  <= "                                                                                ";
					font_matrix(1)  <= "   \   \ \%% \   \%% \%%\ \%^%\ \%%  %%\%% \%%\                                 ";
					font_matrix(2)  <= "   \^\^\ \%% \   \   \  \ \ % \ \%%    \   \  \                                 ";
					font_matrix(3)  <= "    % %  %%% %%% %%% %%%% %   % %%%    %   %%%%                                 ";
					font_matrix(4)  <= "                                                                                ";
					font_matrix(5)  <= "   %\% %%\%% \%%\ \%^%\ \%%\ \%%\ \ \%%   \%%\ \%%\ \%%\   % \%% \%% %%\%%      ";
					font_matrix(6)  <= "    \    \   \^^\ \ % \ \^^\ \^^%   %%\   \  \ \^^% \  \   \ \%% \     \        ";
					font_matrix(7)  <= "   %%%   %   %  % %   % %  % % %%   %%%   \%%% % %% %%%% \^\ %%% %%%   %        ";
					font_matrix(8)  <= "                                                                                ";
					font_matrix(9)  <= "                                                                                ";
					font_matrix(10) <= "                                                                                ";
					font_matrix(11) <= "                                                                                ";
					font_matrix(12) <= "                                                                                ";
					font_matrix(13) <= "       ENTER - MENU                                                             ";
					font_matrix(14) <= "                                                                                ";
					font_matrix(15) <= "                                                                                ";
					font_matrix(16) <= "                                                                                ";
					font_matrix(17) <= "                                                                                ";
					font_matrix(18) <= "                                                                                ";
					font_matrix(19) <= "                                                                                ";
					font_matrix(20) <= "                                                                                ";
					font_matrix(21) <= "                                                                                ";
					font_matrix(22) <= "                                                                                ";
					font_matrix(23) <= "                                                                                ";
					font_matrix(24) <= "                                                                                ";
					font_matrix(25) <= "                                                                                ";
					font_matrix(26) <= "                                                                                ";
					font_matrix(27) <= "                                                                                ";
					font_matrix(28) <= "                                                                                ";
					font_matrix(29) <= "  ITAMAR NATAN                                                                  ";

					font_matrix(21) <= debug("CHAR_P_X  ", char_p_x);

					c1 := c1 + 1;
					if (c1 = 50000000) then -- Wait 5 seconds and go to MENU screen (only once)
						counter := counter + 1;
						c1 := 0;
					end if;

					if (counter = 5) then
						screen_select <= menu;
					end if;	

					if (key_nav = x"0D") then -- press enter to continue to menu screen
						text_box <= (others => ' ');
						index := 0;
						screen_select <= menu;	
					end if;	 
						
				when menu => -- Enter operator's persional info and select action 
						
					font_matrix(0)  <= "                                                                                ";
					font_matrix(1)  <= "                                MENU                                            ";
					font_matrix(2)  <= "                                                                                ";
					font_matrix(3)  <= "                                                                                ";
					font_matrix(4)  <= "                                                                                ";
					font_matrix(5)  <= "                                                                                ";
					font_matrix(6)  <= "                                                                                ";
					font_matrix(7)  <= "                                                                                ";
					font_matrix(8)  <= "                                                                                ";
					font_matrix(9)  <= "                                                                                ";
					font_matrix(10) <= "       ENTER NAME -      " & text_box; 
					font_matrix(11) <= "       ENTER ID   -      " & text_box0;
					font_matrix(12) <= "       ENTER DATE -      " & text_box1;
					font_matrix(13) <= "                                                                                ";
					font_matrix(14) <= "                                                                                ";
					font_matrix(15) <= "       F1 - SELECT A SPECIFIC TEST                                              ";
					font_matrix(16) <= "       F2 - RUN ALL TESTS                                                       ";
					font_matrix(17) <= "       ESC - HOME SCREEN                                                        ";
					font_matrix(18) <= "                                                                                ";
					font_matrix(19) <= "                                                                                ";
					font_matrix(20) <= "                                                                                ";
					font_matrix(21) <= "                                                                                ";
					font_matrix(22) <= "                                                                                ";
					font_matrix(23) <= "                                                                                ";
					font_matrix(24) <= "                                                                                ";
					font_matrix(25) <= "                                                                                ";
					font_matrix(26) <= "                                                                                ";
					font_matrix(27) <= "                                                                                ";
					font_matrix(28) <= "                                                                                ";
					font_matrix(29) <= "  ITAMAR NATAN                                                                  ";
					
					enable_test <= '0';
					if (key_nav = x"11") then -- F1 -> Sellect test
						text_box <= (others => ' ');
						index := 0;
						screen_select <= select_test;
					elsif key_nav = x"12" then -- F2 -> run all
						text_box <= (others => ' ');
						index := 0;
						enable_test <= '1';
						test_addr <= "000";
						screen_select <= run_all;
					elsif key_nav = x"1B" then -- Esc -> return to home screen
						text_box <= (others => ' ');
						index := 0;
						screen_select <= home_screen;
					end if;	
					char_key_nav <= to_integer(unsigned(ps2_code)); -- get current key char on screen
					font_matrix(23) <= debug("KEY_NAV   ", char_key_nav);
					
				when select_test => -- Select screen for specific test
					font_matrix(0)  <= "                                                                                ";
					font_matrix(1)  <= "                                SELECT TEST                                     ";
					font_matrix(2)  <= "                                                                                ";
					font_matrix(3)  <= "                                                                                ";
					font_matrix(4)  <= "                                                                                ";
					font_matrix(5)  <= "                                                                                ";
					font_matrix(6)  <= "                                                                                ";
					font_matrix(7)  <= "       1 - 4.6.7                                                                ";
					font_matrix(8)  <= "       2 - 4.6.9                                                                ";
					font_matrix(9)  <= "                                                                                ";
					font_matrix(10) <= "       ESC - MENU                                                               ";
					font_matrix(11) <= "                                                                                ";
					font_matrix(12) <= "                                                                                ";
					font_matrix(13) <= "                                                                                ";
					font_matrix(14) <= "                                                                                ";
					font_matrix(15) <= "                                                                                ";
					font_matrix(16) <= "                                                                                ";
					font_matrix(17) <= "                                                                                ";
					font_matrix(18) <= "                                                                                ";
					font_matrix(19) <= "                                                                                ";
					font_matrix(20) <= "                                                                                ";
					font_matrix(21) <= "                                                                                ";
					font_matrix(22) <= "                                                                                ";
					font_matrix(23) <= "                                                                                ";
					font_matrix(24) <= "                                                                                ";
					font_matrix(25) <= "                                                                                ";
					font_matrix(26) <= "                                                                                ";
					font_matrix(27) <= "                                                                                ";
					font_matrix(28) <= "                                                                                ";
					font_matrix(29) <= "  ITAMAR NATAN                                                                  ";	

					if (key_nav = x"1B") then -- Esc to return to Menu
						screen_select <= menu;
					elsif key_nav = x"35" then
						test_addr <= "001"; -- sent to test flow 4.6.7 addr
						enable_test <= '1';
						screen_select <= test_4_6_7;
						
					elsif key_nav = x"36" then
						test_addr <= "010"; -- sent to test flow 4.6.9 addr
						enable_test <= '1';
						screen_select <= test_4_6_9;
					end if;	
				
				when run_all => -- Run both test outomaticly
					enable_test <= '0';

					font_matrix(0)  <= "                                                                                ";
					font_matrix(1)  <= "                                RUN ALL                                         ";
					font_matrix(2)  <= "                                                                                ";
					font_matrix(3)  <= "                                                                                ";
					font_matrix(4)  <= "                                                                                ";
					font_matrix(5)  <= "                                                                                ";
					font_matrix(6)  <= "                                                                                ";
					font_matrix(7)  <= "                                                                                ";
					font_matrix(8) <= getLineAll("4.6.7",result_vec_4_6_7);
					font_matrix(9) <= getLineAll("4.6.9",result_vec_4_6_9);
					font_matrix(10) <= "       ESC - MENU                                                               ";
					font_matrix(11) <= "                                                                                ";
					font_matrix(12) <= "                                                                                ";
					font_matrix(13) <= "                                                                                ";
					font_matrix(14) <= "                                                                                ";
					font_matrix(15) <= "                                                                                ";
					font_matrix(16) <= "                                                                                ";
					font_matrix(17) <= "                                                                                ";
					font_matrix(18) <= "                                                                                ";
					font_matrix(19) <= "                                                                                ";
					font_matrix(20) <= "                                                                                ";
					font_matrix(21) <= "                                                                                ";
					font_matrix(22) <= "                                                                                ";
					font_matrix(23) <= "                                                                                ";
					font_matrix(24) <= "                                                                                ";
					font_matrix(25) <= "                                                                                ";
					font_matrix(26) <= "                                                                                ";
					font_matrix(27) <= "                                                                                ";
					font_matrix(28) <= "                                                                                ";
					font_matrix(29) <= "  ITAMAR NATAN                                                                  ";	

					test_addr <= "001"; -- sent to test flow 4.6.7 addr
					enable_test <= '1';
					
					test_addr <= "010"; -- sent to test flow 4.6.9 addr
					enable_test <= '1';

					if (key_nav = x"1B") then -- Esc to return to Menu
						screen_select <= menu;
					end if;
						
				when test_4_6_7 => -- Test 4.6.7 resluts screen
					enable_test <= '0';

					font_matrix(0)  <= "                                                                                ";
					font_matrix(1)  <= "                                TEST 4.6.7                                      ";
					font_matrix(2)  <= "                                                                                ";
					font_matrix(3)  <= "                                                                                ";
					font_matrix(4)  <= "                                                                                ";
					font_matrix(5)  <= "                                                                                ";
					font_matrix(6)  <= "                                                                                ";
					font_matrix(7)  <= "                                                                                ";
					font_matrix(8)  <= "       TEST RESULTS:                                                            ";
					font_matrix(9)  <= "                                                                                ";
					font_matrix(10) <= getLine('A',result_vec_4_6_7(0), 'I', result_vec_4_6_7(8));
					font_matrix(11) <= getLine('B',result_vec_4_6_7(1), 'J', result_vec_4_6_7(9));
					font_matrix(12) <= getLine('C',result_vec_4_6_7(2), 'K', result_vec_4_6_7(10));
					font_matrix(13) <= getLine('D',result_vec_4_6_7(3), 'L', result_vec_4_6_7(11));
					font_matrix(14) <= getLine('E',result_vec_4_6_7(4), 'M', result_vec_4_6_7(12));
					font_matrix(15) <= getLine('F',result_vec_4_6_7(5), 'N', result_vec_4_6_7(13));
					font_matrix(16) <= getLine('G',result_vec_4_6_7(6), 'O', result_vec_4_6_7(14));
					font_matrix(17) <= getLine('H',result_vec_4_6_7(7), 'P', result_vec_4_6_7(15));
					font_matrix(18) <= "       ESC - MENU                                                               ";
					font_matrix(19) <= "                                                                                ";
					font_matrix(20) <= "                                                                                ";
					font_matrix(21) <= "                                                                                ";
					font_matrix(22) <= "                                                                                ";
					font_matrix(23) <= "                                                                                ";
					font_matrix(24) <= "                                                                                ";
					font_matrix(25) <= "                                                                                ";
					font_matrix(26) <= "                                                                                ";
					font_matrix(27) <= "                                                                                ";
					font_matrix(28) <= "                                                                                ";
					font_matrix(29) <= "  ITAMAR NATAN                                                                  ";	

					if (key_nav = x"1B") then
						screen_select <= menu;
					end if;
					
				when test_4_6_9 => -- Test 4.6.9 resluts screen
					enable_test <= '0';

					font_matrix(0)  <= "                                                                                ";
					font_matrix(1)  <= "                                TEST 4.6.9                                      ";
					font_matrix(2)  <= "                                                                                ";
					font_matrix(3)  <= "                                                                                ";
					font_matrix(4)  <= "                                                                                ";
					font_matrix(5)  <= "                                                                                ";
					font_matrix(6)  <= "                                                                                ";
					font_matrix(7)  <= "       TEST RESULTS:                                                            ";
					font_matrix(8)  <= "                                                                                ";
					font_matrix(9)  <= "                                                                                ";
					font_matrix(10) <= "       4.6.9.1:                  4.6.9.2:                 4.6.9.3:              ";
					font_matrix(11) <= "                                                                                ";
					font_matrix(12) <= getLine_4_6_9('A', result_vec_4_6_9(0), 'A', result_vec_4_6_9(3), 'A', result_vec_4_6_9(9));
					font_matrix(13) <= getLine_4_6_9('B', result_vec_4_6_9(1), 'B', result_vec_4_6_9(4), 'B', result_vec_4_6_9(10));
					font_matrix(14) <= getLine_4_6_9('C', result_vec_4_6_9(2), 'C', result_vec_4_6_9(5), 'C', result_vec_4_6_9(11));
					font_matrix(15) <= getLine_4_6_9('0', result_vec_4_6_9(0), 'D', result_vec_4_6_9(6), 'D', result_vec_4_6_9(12));
					font_matrix(16) <= getLine_4_6_9('0', result_vec_4_6_9(0), 'E', result_vec_4_6_9(7), '0', result_vec_4_6_9(0));
					font_matrix(17) <= getLine_4_6_9('0', result_vec_4_6_9(0), 'F', result_vec_4_6_9(8), '0', result_vec_4_6_9(0));
					font_matrix(18) <= "       ESC - MENU                                                               ";
					font_matrix(19) <= "                                                                                ";
					font_matrix(20) <= "                                                                                ";
					font_matrix(21) <= "                                                                                ";
					font_matrix(22) <= "                                                                                ";
					font_matrix(23) <= "                                                                                ";
					font_matrix(24) <= "                                                                                ";
					font_matrix(25) <= "                                                                                ";
					font_matrix(26) <= "                                                                                ";
					font_matrix(27) <= "                                                                                ";
					font_matrix(28) <= "                                                                                ";
					font_matrix(29) <= "  ITAMAR NATAN                                                                  ";	

					if (key_nav = x"1B") then
						screen_select <= menu;
					end if;
				
			end case;		
		end if;
	end process;  

	process (font_bit, video_on) -- decide if pixel on/off
	begin
		if (video_on = '1') then
			if (font_bit = '1') then
				RGB <= x"fff";
			else
				RGB <= x"000";
			end if;
		end if;	
	end process;
end architecture;
