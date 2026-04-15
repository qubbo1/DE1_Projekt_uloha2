process(CLK100MHZ)
begin
    if rising_edge(CLK100MHZ) then
        
        -- BTN UP → +1
        if BTN_U = '1' then
            wave_sel <= wave_sel + 1;
        
        -- BTN DOWN → -1
        elsif BTN_D = '1' then
            wave_sel <= wave_sel - 1;
        end if;

    end if;
end process;


process(wave_sel, square_out, triangle_out, saw_out)
begin
    case wave_sel is
        when "00" => out_sig <= square_out;
        when "01" => out_sig <= triangle_out;
        when "10" => out_sig <= saw_out;
        when "11" => out_sig <= (others => '0'); -- alebo sine
        when others => out_sig <= (others => '0');
    end case;
end process;

process(wave_sel)
begin
    case wave_sel is

        -- RED
        when "00" =>
            led16_r <= '0'; led16_g <= '1'; led16_b <= '1';

        -- GREEN
        when "01" =>
            led16_r <= '1'; led16_g <= '0'; led16_b <= '1';

        -- BLUE
        when "10" =>
            led16_r <= '1'; led16_g <= '1'; led16_b <= '0';

        -- YELLOW
        when "11" =>
            led16_r <= '0'; led16_g <= '0'; led16_b <= '1';

        when others =>
            led16_r <= '1'; led16_g <= '1'; led16_b <= '1';

    end case;
end process;

-- kopia na druhú LED
led17_r <= led16_r;
led17_g <= led16_g;
led17_b <= led16_b;



signal btn_u_prev : STD_LOGIC := '0';
signal btn_d_prev : STD_LOGIC := '0';

process(CLK100MHZ)
begin
    if rising_edge(CLK100MHZ) then
        
        -- BTN UP (rising edge)
        if BTN_U = '1' and btn_u_prev = '0' then
            wave_sel <= wave_sel + 1;
        end if;

        -- BTN DOWN
        if BTN_D = '1' and btn_d_prev = '0' then
            wave_sel <= wave_sel - 1;
        end if;

        btn_u_prev <= BTN_U;
        btn_d_prev <= BTN_D;

    end if;
end process;
