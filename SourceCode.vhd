----------------------------------------------------------------------------------
--
--Progeto reti logiche anno accademico 2022/2023
--
--Creatore: Davide Spinelli
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity project_reti_logiche is
  Port ( 
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_w : in std_logic;
        o_z0 : out std_logic_vector(7 downto 0);
        o_z1 : out std_logic_vector(7 downto 0);
        o_z2 : out std_logic_vector(7 downto 0);
        o_z3 : out std_logic_vector(7 downto 0);
        o_done : out std_logic;
        -- Indirizzo da mandare alla memoria per leggere
        o_mem_addr : out std_logic_vector(15 downto 0);
        -- Dato arrivante dalla memoria
        i_mem_data : in std_logic_vector(7 downto 0);
        -- Segnale che abilita la scrittura su memoria(Sempre a zero, non dobbiamo mai scrivere da memoria)
        o_mem_we : out std_logic;
        -- Segnale abilitante la lettura in memoria
        o_mem_en : out std_logic
  );
end project_reti_logiche;
architecture structural of project_reti_logiche is
-- Segnali
signal mod_en, data_en, tmp_done, z0, z1, z2, z3, done, ten0, ten1, ten2, ten3, nd, tmp1, tmp2, tmp3, ffr, cctmp1, cctmp2, rstcc, t1,t2,nc : std_logic := '0';
signal data : std_logic_vector(17 downto 0) := (others => '0');
signal ch : std_logic_vector(1 downto 0) := (others => '0');
signal tmp_z0, tmp_z1, tmp_z2, tmp_z3 : std_logic_vector(7 downto 0) := (others =>'0');
-- Costanti: vettore nullo utile per la gestione delle uscite
constant nv : std_logic_vector(7 downto 0) := (others => '0');
-- Decoder 
component decoder is
   port (
       i_dec : in std_logic_vector(1 downto 0);
       o_dec0, o_dec1, o_dec2, o_dec3 : out std_logic
);
end component;
-- Multiplexer
component multiplexer is
 Port ( 
   i_ch0, i_ch1 : in std_logic_vector(7 downto 0);
   i_sel : in std_logic;
   o_mux : out std_logic_vector(7 downto 0)
);
end component;
-- Flip Flop D
component ff_d is
 Port ( 
  i_rst, i_clk, i_dat : in std_logic;
  out0 : out std_logic
);
end component;
-- Registro parallelo/parallelo
component reg_pp is
  Port ( 
   i_rst, i_clk, i_en : in std_logic;
   i_data : in std_logic_vector(7 downto 0);
   out_reg : out std_logic_vector(7 downto 0)
);
end component;
--Registro Shifter
  component new_reg_shift is
    port(
      i_clk, i_rst, i_data, cc0, cc1, cc2 : in std_logic;
      prec : in std_logic_vector(17 downto 0);
      out_data : out std_logic_vector(17 downto 0)
    );
  end component;
  -- Abilitatore del modulo
  component module_abilitator is
    Port ( 
      i_clk, i_rst, data  : in std_logic;
      o_ab : out std_logic
    );
  end component;
  component done_enabler is
    Port ( 
      i_rst, i_dat : in std_logic;
      out0 : out std_logic
    );
    end component;
begin
    o_mem_we <= '0';
    o_mem_en <= tmp_done;
    -- Abilitatore del modulo
    mod_abil : module_abilitator 
       port map(i_clk => i_clk, i_rst => i_rst, data => mod_en, o_ab => mod_en);
    -- Lettura di canale più indirizzo
    data_en <= mod_en and i_start;
    ffr <= i_rst or done;
    rstcc <= i_rst or done or not data_en;
    ff_cc0 : ff_d
      port map(i_rst => rstcc, i_clk => i_clk, i_dat => data_en, out0 => cctmp1);
    ff_cc1 : ff_d
      port map(i_rst => rstcc, i_clk => i_clk, i_dat => cctmp1, out0 => cctmp2);
    in_reg : new_reg_shift
      port map(i_clk => i_clk, i_rst => ffr, i_data => i_w, prec => data,cc0 => data_en, cc1 => cctmp1, cc2 => cctmp2, out_data => data);
    ch <= data(17) & data(16);
    dec : decoder
         port map(i_dec => ch, o_dec0 => z0, o_dec1 => z1, o_dec2 => z2, o_dec3 => z3);
    -- Lettura dati da memoria
    o_mem_addr <= data(15 downto 0);
    -- Immagazzinamento dei dati
   ten0 <= z0 and tmp_done;
   reg_z0 : reg_pp
      port map(i_rst => i_rst, i_clk => i_clk, i_en => ten0, i_data => i_mem_data, out_reg => tmp_z0);
   ten1 <= z1 and tmp_done;
   reg_z1 : reg_pp
      port map(i_rst => i_rst, i_clk => i_clk, i_en => ten1, i_data => i_mem_data, out_reg => tmp_z1);
   ten2 <= z2 and tmp_done;   
   reg_z2 : reg_pp
      port map(i_rst => i_rst, i_clk => i_clk, i_en => ten2, i_data => i_mem_data, out_reg => tmp_z2);
   ten3 <= z3 and tmp_done;
   reg_z3 : reg_pp
      port map(i_rst => i_rst, i_clk => i_clk, i_en => ten3, i_data => i_mem_data, out_reg => tmp_z3);
   -- Ritardo esposizione dati
   nd <= not data_en;
   done_en : done_enabler
      port map(i_rst => ffr, i_dat => nd, out0 => t1);
   nc <= not i_clk;
   ff : ff_d
    port map(i_rst => ffr, i_clk => nc, i_dat => tmp_done, out0 => t2);

  tmp_done <= t1 or t2;
  ffd1 : ff_d
    port map(i_rst => ffr, i_clk => i_clk, i_dat => tmp_done, out0 => tmp1);
  ffd2 : ff_d
    port map(i_rst => ffr, i_clk => i_clk, i_dat => tmp1, out0 => tmp2);
  ffd3 : ff_d
    port map(i_rst => ffr, i_clk => i_clk, i_dat => tmp2, out0 => tmp3);
   ffd4 : ff_d
      port map(i_rst => i_rst, i_clk => i_clk, i_dat => tmp3, out0 => done);  
   o_done <= done;
   -- Uscite
   mux0 : multiplexer
      port map(i_ch0 => nv, i_ch1 => tmp_z0, i_sel => done, o_mux => o_z0);
   mux1 : multiplexer
      port map(i_ch0 => nv, i_ch1 => tmp_z1, i_sel => done, o_mux => o_z1);
   mux2 : multiplexer
      port map(i_ch0 => nv, i_ch1 => tmp_z2, i_sel => done, o_mux => o_z2);
   mux3 : multiplexer
      port map(i_ch0 => nv, i_ch1 => tmp_z3, i_sel => done, o_mux => o_z3);
end structural;
-- Inizio descrizione componenti
-- Abilitatore del modulo
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity module_abilitator is
  Port ( 
      i_clk, i_rst, data  : in std_logic;
      o_ab : out std_logic
    );
end module_abilitator;
architecture Behavioral of module_abilitator is
    begin
        process(i_clk,i_rst,data)
        begin
          if i_rst = '1' then 
            o_ab <= '1';
          elsif rising_edge(i_clk) then
              o_ab <= data;
            end if; 
        end process;
end Behavioral;
-- Decoder
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity decoder is
  port (
    i_dec : in std_logic_vector(1 downto 0);
    o_dec0, o_dec1, o_dec2, o_dec3 : out std_logic
);
end decoder;
architecture Behavioral of decoder is
    begin
        process(i_dec)
        begin    
            case i_dec is
                when "00" =>
                    o_dec0 <= '1';
                    o_dec1 <= '0';
                    o_dec2 <= '0';
                    o_dec3 <= '0';
                when "01" =>
                    o_dec0 <= '0';
                    o_dec1 <= '1';
                    o_dec2 <= '0';
                    o_dec3 <= '0';
                when "10" =>
                    o_dec0 <= '0';
                    o_dec1 <= '0';
                    o_dec2 <= '1';
                    o_dec3 <= '0';
                when "11" =>
                    o_dec0 <= '0';
                    o_dec1 <= '0';
                    o_dec2 <= '0';
                    o_dec3 <= '1';
                when others =>
                    o_dec0 <= '0';
                    o_dec1 <= '0';
                    o_dec2 <= '0';
                    o_dec3 <= '0';
            end case;
        end process;
end Behavioral;
-- Registro parallelo/parallelo
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity reg_pp is
  Port ( 
    i_rst, i_clk, i_en : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    out_reg : out std_logic_vector(7 downto 0)
 );
end reg_pp;
architecture Behavioral of reg_pp is
    begin
        process(i_clk,i_rst,i_en,i_data)
        begin
          if i_rst = '1' then
            out_reg <= (others => '0');
          elsif rising_edge(i_clk) then
            if i_en = '1' then
              out_reg <= i_data;
            end if;
          end if;
        end process;
end Behavioral;
-- Flip-Flop D
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity ff_d is
  Port ( 
    i_rst, i_clk, i_dat : in std_logic;
    out0 : out std_logic
  );
end ff_d;
architecture Behavioral of ff_d is
    begin
    process(i_rst,i_clk)
    begin
      if i_rst = '1' then
        out0 <= '0';
      elsif rising_edge(i_clk) then
          out0 <= i_dat;
      end if;
    end process;
end Behavioral;
-- Multiplexer
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity multiplexer is
  Port ( 
   i_ch0, i_ch1 : in std_logic_vector(7 downto 0);
   i_sel : in std_logic;
   o_mux : out std_logic_vector(7 downto 0)
);
end multiplexer;
architecture Behavioral of multiplexer is
    begin
        process(i_ch0,i_ch1,i_sel)
        begin
            if i_sel = '1' then
                o_mux <= i_ch1;
            else
                o_mux <= i_ch0;
            end if;
        end process;
end Behavioral;
-- Registro ingresso
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity new_reg_shift is
  port(
      i_clk, i_rst, i_data, cc0, cc1, cc2 : in std_logic;
      prec : in std_logic_vector(17 downto 0);
      out_data : out std_logic_vector(17 downto 0)
    );
end new_reg_shift;
architecture Behavioral of new_reg_shift is
  begin
    process(i_clk, i_rst, i_data, prec, cc0, cc1, cc2)
    begin
      if i_rst = '1' then
        out_data <= (others => '0');
      elsif rising_edge(i_clk) then
        if cc2 = '1' then
          out_data <= prec(17 downto 16) & prec(14 downto 0) & i_data;
        elsif cc1 = '1' then
          out_data <= (prec(17) & i_data & prec(15 downto 0)); 
        elsif cc0 = '1' then
          out_data <= (i_data & prec(16 downto 0));
        else 
        out_data <= prec;
        end if;
      end if;
    end process;
end Behavioral;
-- Abilitatore del done
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity done_enabler is
  Port ( 
    i_rst, i_dat : in std_logic;
    out0 : out std_logic
  );
  end done_enabler;
architecture Behavioral of done_enabler is
  begin
    process(i_rst,i_dat)
    begin
      if i_rst = '1' then
        out0 <= '0';
      elsif rising_edge(i_dat) then
        out0 <= '1'; 
      end if;
    end process;
end Behavioral;