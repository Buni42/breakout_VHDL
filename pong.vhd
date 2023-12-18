library IEEE;
use IEEE.STD_LOGIC_1164.ALL;-- voor alle logica, we gaan niet op poortniveau werken
use IEEE.numeric_std.all; -- voor unsigned

entity pong is
    Port ( clk : in STD_LOGIC;
           BTNL : in STD_LOGIC;
           BTNR : in STD_LOGIC;
           BTNC : in STD_LOGIC;
           R : out std_logic_vector(3 downto 0);
           G : out std_logic_vector(3 downto 0);
           B : out std_logic_vector(3 downto 0);
           hsync : out STD_LOGIC;
           vsync : out STD_LOGIC;
           displaysAN: out std_logic_vector(7 downto 0); 
           displaysCAT: out std_logic_vector(6 downto 0) 
           );
end pong;

architecture Behavioral of pong is
--alle constanten
    constant H_RES : integer := 640;  -- Horizontale resolutie
    constant V_RES : integer := 480;  -- Verticale resolutie
    constant H_FRONT_PORCH : integer := 16;
    constant H_SYNC_TIME : integer := 96;
    constant H_BACK_PORCH : integer := 48;
    constant V_FRONT_PORCH : integer := 10;
    constant V_SYNC_TIME : integer := 2;
    constant V_BACK_PORCH : integer := 33;
    constant MUUR_RAND : integer := 5;
--
--    clock voor vga
    signal pixel_clk : STD_LOGIC;
    signal pixel_counter : integer := 0;
    
--  player
    signal player_snelheid : integer := 3;
    signal PLAYER_H : integer := 80;
    signal PLAYER_V : integer := 15;
    signal player_L: integer  := 424;
    signal player_R: integer := 504;
    signal player_UP: integer := 485;
    signal player_DOWN: integer := 505;
    
--    ball
    signal clk_60hz : STD_LOGIC;
    signal counter_60hz : integer := 0;
    signal ball_snelheid_x : integer := 1;
    signal ball_snelheid_y : integer := 1;
    signal BAL_Z : integer := 10;
    signal ball_L: integer := 459;
    signal ball_R: integer := 469;
    signal ball_UP: integer := 270;
    signal ball_DOWN: integer := 280;
    signal Balldirectionx: boolean := True;
    signal Balldirectiony: boolean := True;

    
--    voor vsync en hsync
    signal h_count, v_count : integer := 0;
    signal hsync_counter, vsync_counter : integer := 0;
    
--    we mogen display data sturen volgens de vga timings
    signal VideoActive : boolean := false;
   
    
--    power ups
    signal sneller_player : boolean := false;
    signal sneller_ball : boolean := false;
    signal maximum_snelheid : boolean := false;
    
--    lives and restart
    signal lives : integer := 3;
    signal death : boolean := false;
    signal live_lost : boolean := false;
    
    
--    score en scoredisplay
    signal score : integer := 0;
    signal score_up : boolean := false;
    signal ClkCouter : integer range 0 to 6249 := 0;
    signal SlowClk: std_logic := '0' ;
    signal SlowCounter : integer range 0 to 7 := 0;
    signal BCDeenheid: unsigned (3 downto 0); -- bord rechts eenheid 
    signal BCDtiental: unsigned (3 downto 0); -- bord links tiental 
    signal BCD: unsigned (3 downto 0); -- BCD dat je wil gaan converteren 
    signal SevenSegm: std_logic_vector(6 downto 0); -- de geconverteerde bcd naar sevenseg
    
    component BCD2SevenSegm is port (
        BCD: in unsigned(3 downto 0);
        SevenSegm: out std_logic_vector(6 downto 0));                                       
    end component; 
    
begin
    using : BCD2SevenSegm port map(
            BCD => BCD,
            SevenSegm => SevenSegm
        );
    
    
 -- Pixel Clock Generation(25 MHz)
    P_pixel_clk : process (clk)
    begin
        if rising_edge(clk) then
            if pixel_counter = 1 then
                pixel_clk <= not pixel_clk;
                pixel_counter <= 0;                
            else
                pixel_counter <= pixel_counter + 1;
            end if;
        end if;
    end process P_pixel_clk;

    -- Vertical en horizontal Counter
    P_VHcount : process (pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if h_count = H_RES + H_FRONT_PORCH + H_SYNC_TIME + H_BACK_PORCH - 1 then
                h_count <= 0;
                if v_count = V_RES + V_FRONT_PORCH + V_SYNC_TIME + V_BACK_PORCH - 1 then
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process P_VHcount;
    
    --we maken een trage klok van 60 hz(=60 pixels/s)
    P_clk_60hz : process (clk)
    begin
        if rising_edge(clk) then
            if counter_60hz = 833332 then --60hz
                clk_60hz <= not clk_60hz;
                counter_60hz <= 0; 
            else
                counter_60hz <= counter_60hz + 1;
            end if;
        end if;
    end process P_clk_60hz;
    
    
    P_clkdiv : process(clk)
    begin
        if rising_edge(clk) then
            if ClkCouter = 6249 then
                ClkCouter <= 0;
                SlowClk <= not SlowClk;
             else
                ClkCouter <= ClkCouter + 1;
            end if;
        end if;
    end process P_clkdiv;
    
    P_slow : process(SlowClk)
    begin
        if rising_edge(SlowClk) then
            if SlowCounter = 7 then
                SlowCounter <= 0;
            else
                SlowCounter <= SlowCounter + 1;
            end if;
        end if;
    end process P_slow;
    
    P_scoresplit : process(score)
    begin
        if score >= 0 and score <=9 then
            BCDeenheid <= TO_UNSIGNED(score,4);
            BCDtiental <= "0000";
        elsif score >= 10 and score <=19 then
            BCDeenheid <= TO_UNSIGNED(score-10,4);
            BCDtiental <= "0001";
        elsif score >= 20 and score <=29 then
            BCDeenheid <= TO_UNSIGNED(score-20,4);
            BCDtiental <= "0010";
        elsif score >= 30 and score <=39 then
            BCDeenheid <= TO_UNSIGNED(score-30,4);
            BCDtiental <= "0011";
        elsif score >= 40 and score <=49 then
            BCDeenheid <= TO_UNSIGNED(score-40,4);
            BCDtiental <= "0100";
        elsif score >= 50 and score <=59 then
            BCDeenheid <= TO_UNSIGNED(score-50,4);
            BCDtiental <= "0101";
        elsif score >= 60 and score <=69 then
            BCDeenheid <= TO_UNSIGNED(score-60,4);
            BCDtiental <= "0110";
        elsif score >= 70 and score <=79 then
            BCDeenheid <= TO_UNSIGNED(score-70,4);
            BCDtiental <= "0111";
        elsif score >= 80 and score <=89 then
            BCDeenheid <= TO_UNSIGNED(score-80,4);
            BCDtiental <= "1000";
        elsif score >= 90 and score <=99 then
            BCDeenheid <= TO_UNSIGNED(score-90,4);
            BCDtiental <= "1001";
        else 
            BCDeenheid <= "1110";
            BCDtiental <= "1110";
        end if;  
    end process P_scoresplit ;
    
    P_scoredisplay : process(SlowCounter, BCDeenheid, BCDtiental, lives, SevenSegm)
    begin
        if SlowCounter = 7 then
            BCD <= BCDeenheid;
            displaysAN <= "11111110";
            displaysCAT <= SevenSegm; -- score eenheid
        elsif SlowCounter = 6 then
            BCD <= BCDtiental;
            displaysAN <= "11111101";
            displaysCAT <= SevenSegm; -- score tiental
        elsif SlowCounter = 1 then
            BCD <= TO_UNSIGNED(lives, 4);
            displaysAN <= "10111111";
            displaysCAT <= SevenSegm; -- levens
        else
            displaysAN <= "01111111";
            displaysCAT <= "0000001"; ---0
        end if;
    end process P_scoredisplay;
    
    
    P_game : process(clk_60hz)
    begin
        if rising_edge(clk_60hz) then
        --hier maken we een counter dat optelt/aftrekt wanneer we BTN induwen
            if BTNL = '1' then
                    if player_L > 149 then--collision met linkse kant en wall
                        player_L <= player_L - player_snelheid;
                        player_R <= player_R - player_snelheid;
                    else
                        player_L <= player_L;
                    end if;
            elsif BTNR = '1' then
                if player_R < 784 then--collision met rechtse kant en wall
                    player_R <= player_R + player_snelheid;--problem bence bastigin an 270 i gecmesi
                    player_L <= player_L + player_snelheid;                                      --dedigim sey dogru cikti, 60Hz clk kullaninca duzeldi!
                else
                    player_R <= player_R;
                end if;
            else
                player_R <= player_R;
                player_L <= player_L;
            end if;
            -- ball collision
            if ball_L <= 150 then
                Balldirectionx <= True;  -- naar rechts
            elsif ball_L >= 767 then
                Balldirectionx <= False;
            else
                Balldirectionx <= Balldirectionx;
            end if;
            
            if ball_UP <= 48 then
                Balldirectiony <= true;  -- naar beneden
            elsif ball_UP >= 498 then
                live_lost <= true;
                Balldirectiony <= false;
            else
                Balldirectiony <= Balldirectiony;
            end if;

            if Balldirectionx = True then
                ball_L <= ball_L + ball_snelheid_x;
                ball_R <= ball_R + ball_snelheid_x;
            else
                ball_L <= ball_L - ball_snelheid_x;
                ball_R <= ball_R - ball_snelheid_x;
            end if;
            --zorgt voor direction van bal wanneer het op het player land (boven en links/rechts)
            if ball_DOWN >= player_UP and ball_L >= player_L - BAL_Z and ball_L <= player_R then
                Balldirectiony <= false;
                score_up <= true;
            end if;
            if score_up then
                score_up <= false;
                score <= score + 1;
            end if;
            
            if Balldirectiony = true then
                ball_UP <= ball_UP + ball_snelheid_y;
                ball_DOWN <= ball_DOWN + ball_snelheid_y;
            else
                ball_UP <= ball_UP - ball_snelheid_y;
                ball_DOWN <= ball_DOWN - ball_snelheid_y;
            end if;
            --death en lives reset
            if live_lost then
                lives <= lives - 1;
                live_lost <= false;
            end if;
            
            if lives <= 0 then
                death <= true;     
            else
                death <= false;
            end if;
            
            if lives <= 0 and BTNC = '1' then
                lives <= 3;
                score <= 0;
            else
                lives <= lives;
            end if;
            
        end if;
    end process P_game;
    
  
    P_powerup : process(score)
    begin
        sneller_player <= false;
        sneller_ball <= false;
        maximum_snelheid <= false;
 
        if 0 <= score and score <= 5 then
            ball_snelheid_x <= 2;
            ball_snelheid_y <= 2;
        elsif 6 <= score and score <= 10 then
            ball_snelheid_x <= 3;
            ball_snelheid_y <= 3;
            player_snelheid <= 5;
            sneller_player <= true;
        elsif 11 <= score and score <= 20 then
            ball_snelheid_x <= 5;
            ball_snelheid_y <= 5;
            sneller_ball <= true;
            sneller_player <= true;
        else
            ball_snelheid_x <= 8;
            ball_snelheid_y <= 8;
            maximum_snelheid <= true;
            sneller_ball <= true;
            sneller_player <= true;
        end if; 
    end process P_powerup;
    
    P_Display : process(h_count, v_count, death, player_L, player_R, player_UP, player_DOWN, ball_L, ball_R, ball_UP, ball_DOWN, maximum_snelheid, sneller_player, sneller_ball)
    begin
        G <= "0000";
        B <= "0000";
        R <= "0000";
        if not death then
            -- wanneer we rgb signalen mogen sturen
            if (H_BACK_PORCH + H_SYNC_TIME) < h_count and h_count < (H_RES + H_SYNC_TIME + H_BACK_PORCH)
             and (V_BACK_PORCH + V_SYNC_TIME) < v_count and v_count < (V_RES + V_SYNC_TIME + V_BACK_PORCH) then
                VideoActive <= true;
    ----------------------------------------- paddles en bal generation
                if player_L < h_count and h_count < player_R 
                and player_UP < v_count and v_count < player_DOWN then
                    -- witte paddle -> onze player
                    if sneller_player then
                        G <= "1111";
                        B <= "0000";
                        R <= "0000";
                    else
                        G <= "1111";
                        B <= "1111";
                        R <= "1111";
                    end if;
                                      
                elsif ball_L < h_count and h_count < ball_R --bal
                and ball_UP < v_count and v_count < ball_DOWN then
                    --witte vierkanten bal in het midden 10x10 px
                   if sneller_ball then
                        G <= "1111";
                        B <= "0000";
                        R <= "0000";
                    else
                        G <= "1111";
                        B <= "1111";
                        R <= "1111";
                    end if;
               --------------------------------------------------------------------
     ---------------------------------------witte box----------------------------------
                elsif 143 < h_count and h_count < 144 + MUUR_RAND then--links muur
                    if maximum_snelheid then
                        G <= "0000";
                        B <= "0000";
                        R <= "1111";
                    else
                        G <= "1111";
                        B <= "1111";
                        R <= "1111";
                    end if;
                elsif 143 + H_RES - MUUR_RAND < h_count and h_count < 143 + H_RES then--rchts muur
                    if maximum_snelheid then
                        G <= "0000";
                        B <= "0000";
                        R <= "1111";
                    else
                        G <= "1111";
                        B <= "1111";
                        R <= "1111";
                    end if;
                elsif 34 < v_count and v_count < 35 + MUUR_RAND then -- boven muur
                    if maximum_snelheid then
                        G <= "0000";
                        B <= "0000";
                        R <= "1111";
                    else
                        G <= "1111";
                        B <= "1111";
                        R <= "1111";
                    end if;
                elsif 35 + V_RES - MUUR_RAND < v_count and v_count < 35 + V_RES then--rchts muur
                    if maximum_snelheid then
                        G <= "0000";
                        B <= "0000";
                        R <= "1111";
                    else
                        G <= "1111";
                        B <= "1111";
                        R <= "1111";
                    end if;
    ------------------------------------------------------------------------------------
                else
                    --al de rest zwart
                    G <= "0000";
                    B <= "0000";
                    R <= "0000";
                end if;           
            else
                VideoActive <= false;
            end if;
        else --death is true
            G <= "0000";
            B <= "0000";
            R <= "1111";  
        end if;
    end process P_Display; 
    
    P_sync : process(h_count, v_count)
    begin
        -- assign HSync 
        if h_count < H_SYNC_TIME then
            hsync <= '0';
        else
            hsync <= '1';
        end if;
        
        --assign vsync
        if v_count < V_SYNC_TIME then
            vsync <= '0';
        else 
            vsync <= '1';
        end if;
    end process P_sync;
end Behavioral;
