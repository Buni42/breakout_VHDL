library IEEE;
use IEEE.STD_LOGIC_1164.ALL;-- voor alle logica, we gaan niet op poortniveau werken
use IEEE.numeric_std.all; -- voor unsigned

entity pong is
    Port ( clk : in STD_LOGIC;
           BTNL : in STD_LOGIC;
           BTNR : in STD_LOGIC;
           R : out std_logic_vector(3 downto 0);
           G : out std_logic_vector(3 downto 0);
           B : out std_logic_vector(3 downto 0);
           hsync : out STD_LOGIC;
           vsync : out STD_LOGIC);
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
    constant PLAYER_H : integer := 100;
    constant PLAYER_V : integer := 20;
    constant BAL_Z : integer := 10;
    constant RAND : integer := 5;
--
--    clock voor vga
    signal pixel_clk : STD_LOGIC;
    signal pixel_counter : integer := 0;
    
--  player
    signal player_velocity : integer := 0;
    
--    ball
    signal ball_clk : STD_LOGIC;
    signal ball_counter : integer := 0;
    signal ball_velocity : integer := 0;
    
--    voor vsync en hsync
    signal h_count, v_count : integer := 0;
    signal hsync_counter, vsync_counter : integer := 0;
    
--    we mogen display data sturen volgens de vga timings
    signal VideoActive : boolean := false;
    
    signal collision : boolean := false;
    signal col_rb : boolean := false;
    signal col_ro : boolean := false;
    signal col_lb : boolean := false;
    signal col_lo : boolean := false;
    
    
begin
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
    P_ball_clk : process (clk)
    begin
        if rising_edge(clk) then
            if ball_counter = 833332 then --60hz
                ball_clk <= not ball_clk;
                ball_counter <= 0; 
            else
                ball_counter <= ball_counter + 1;
            end if;
        end if;
    end process P_ball_clk;
    
    --we maken een trage counter op basis van de 60Hz clock, we gaan dit gebruiken als snelheid voor de bal
    P_ball_velocity : process (ball_clk)
    begin
        if rising_edge(ball_clk) then
            --count until collision
            if collision = false then
                ball_velocity <= ball_velocity + 1;
            --when collision, ball_velosity = 0
            else
                ball_velocity <= 0;
            end if;
            --depending on the collision, change ball directon (linksboven/onder rechtsboven/onder)
            --to give the ball an x, y value add ball_velocity to the left or right side of h/vcounter in P_display
        end if;
    end process P_ball_velocity;
  
    
    --hier maken we een counter dat optelt/aftrekt wanneer we BTN induwen
    P_player : process(ball_clk)
    begin
        if rising_edge(ball_clk) then
            if BTNL = '1' then
                if player_velocity > (-265) then--collision met linkse kant en wall
                    player_velocity <= player_velocity - 1;
                else
                    player_velocity <= player_velocity;
                end if;
            elsif BTNR = '1' then
                if player_velocity < 265 then--collision met rechtse kant en wall
                    player_velocity <= player_velocity + 1;--problem bence bastigin an 270 i gecmesi
                                                           --dedigim sey dogru cikti, 60Hz clk kullaninca duzeldi!
                else
                    player_velocity <= player_velocity;
                end if;
            else
                player_velocity <= player_velocity;
            end if;
        end if;
    end process P_player;
    
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
    
    P_collision_detection : process(h_count, v_count, player_velocity, ball_velocity)
    begin
        
    end process P_collision_detection;
    
    P_Display : process(h_count, v_count, player_velocity, ball_velocity)
    begin
        -- wanneer we rgb signalen mogen sturen
        if (H_BACK_PORCH + H_SYNC_TIME) < h_count and h_count < (H_RES + H_SYNC_TIME + H_BACK_PORCH)
         and (V_BACK_PORCH + V_SYNC_TIME) < v_count and v_count < (V_RES + V_SYNC_TIME + V_BACK_PORCH) then
            VideoActive <= true;

-----------------------------------------  ball en paddles
            if 144 + (H_RES - PLAYER_H)/2 + player_velocity < h_count and h_count < 144 + (H_RES + PLAYER_H)/2 + player_velocity 
            and 35 + (V_RES - PLAYER_V - 10) < v_count and v_count < 35 + (V_RES - 10) then
                -- witte paddle -> onze player
                G <= "1111";
                B <= "1111";
                R <= "1111";
--          witte vierkanten bal in het midden 10x10 px
            elsif 144 + (H_RES - BAL_Z)/2 + ball_velocity  < h_count and h_count < 144 + (H_RES + BAL_Z)/2 + ball_velocity
            and 35 + (V_RES - BAL_Z)/2 + ball_velocity < v_count and v_count < 35 + (V_RES + BAL_Z)/2 + ball_velocity then
                G <= "1111";
                B <= "1111";
                R <= "1111";
                
 ---------------------------------------witte box-----------------------------------
            elsif 144 < h_count and h_count < 144 + RAND then--links rand
                G <= "1111";
                B <= "1111";
                R <= "1111";
            elsif 144 + H_RES - RAND < h_count and h_count < 144 + H_RES then--rchts rand
                G <= "1111";
                B <= "1111";
                R <= "1111";
            elsif 35 < v_count and v_count < 35 + RAND then -- boven rand
                G <= "1111";
                B <= "1111";
                R <= "1111";
--            elsif 35 + V_RES - RAND < v_count and v_count < 35 + V_RES then -- onder kant
--                G <= "1111"; -- er moet geen onderkant zijn
--                B <= "1111";
--                R <= "1111";
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
    end process P_Display; 
end Behavioral;
