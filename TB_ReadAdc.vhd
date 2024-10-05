
--+----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_STD.all;


--****************************************************************************
-- Entity declaration section start
--============================================================================
entity TB_ReadAdc is
  --+----------
  -- Generic declarations
  --+----------
  generic(
          DataVecSize_g   :integer := 56;
          WdVecSize_g     :integer := 16;
          ByteSize_g      :integer := 8;
          NibbleSize_g    :integer := 4
      );

  --+----------
  -- Port name declarations
  --+----------
  port   (
       CLK100     :in  std_logic;
       RST        :in  std_logic;
--       TEST     :in  std_logic;    
       ADC_CLK_1  :out std_logic; 
       ADC_CLK_2  :out std_logic; 
       
       i_DR1_EN   :in std_logic;
       i_DR2_EN   :in std_logic;
       
       ADC_D1      :in  std_logic_vector(WdVecSize_g-5 downto 0);
       ADC_DR1     :in  std_logic;
       
       ADC_D2      :in  std_logic_vector(WdVecSize_g-5 downto 0);
       ADC_DR2     :in  std_logic;
       
       DATA1       :out std_logic_vector(WdVecSize_g-5 downto 0);
       DATARDY1    :out std_logic;
       
       DATA2       :out std_logic_vector(WdVecSize_g-5 downto 0);
       DATARDY2    :out std_logic;
	   
	   i_stop_req  :in  std_logic 
         );

end entity TB_ReadAdc;
--============================================================================
-- Entity declaration section end
--****************************************************************************


--****************************************************************************
-- Architecture definition section start - RTL
--============================================================================
architecture ReadAdc_RTL of TB_ReadAdc is
attribute syn_noprune : boolean;
attribute syn_noprune of ReadAdc_RTL : architecture is true;
attribute syn_preserve : boolean;
attribute syn_preserve of ReadAdc_RTL: architecture is true;

  --+----------
  -- Constants, types and signals declarations start here for the architecture
  --+----------
  
  constant AdcClkFreq_c  :std_logic_vector (NibbleSize_g-3 downto 0)
                         := (others =>'0');
                         
                         
  constant CntAdcClk_c   :integer:=3;  
  signal AdcClkFreq_s    :std_logic_vector (1 downto 0)
                         := (others =>'0');  
  signal CntAdcClk_s     :integer:=0;
  signal AdcClk_s        :std_logic:='0';
  signal AdcClk_delay_1  :std_logic:='0';
  signal AdcClk_delay_2  :std_logic:='0';
  
  signal ADC_DR_FL_C1    :std_logic:='0'; 
  signal ADC_DR_FL_C2    :std_logic:='0';

  -- capture rising and falling edges
  signal ADC_DR1_IN      :std_logic:='0'; /* synthesis preserve=1*/
  signal ADC_DR2_IN      :std_logic:='0'; /* synthesis preserve=1*/
        

  signal ADC_DR_s_C1     :std_logic:='0';
  signal ADC_DR_s_C2     :std_logic:='0';
  
  signal ADC_DR_s1_C1    :std_logic:='0';
  signal ADC_DR_s1_C2    :std_logic:='0';
  
  signal ADC_DR_s2_C1    :std_logic:='0';
  signal ADC_DR_s2_C2    :std_logic:='0'; 
  
  signal ADC_D_s1_C1     :std_logic_vector(WdVecSize_g-5 downto 0) 
                      :=(others =>'0'); 
  signal ADC_D_s2_C1     :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0'); 
  signal ADC_D_E_C1      :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0');         

  signal ADC_D_s1_C2     :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0'); /* synthesis preserve=1*/
  signal ADC_D_s2_C2     :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0'); /* synthesis preserve=1*/
  signal ADC_D_E_C2      :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0'); /* synthesis preserve=1*/   
  signal s_DR1_EN     :std_logic;               
  signal s_DR2_EN     :std_logic;                 
               
  signal adc_cnt      :std_logic_vector(3 downto 0)
                      :=(others =>'0');  
  
  signal simulated_adc_cnt :integer range 0 to 99:= 0; 
  signal simulated_adc_2_cnt :integer range 0 to 99:= 0; 
                      
  type SIM_ADC_DATA_TYPE is array (0 to 99) of std_logic_vector(11 downto 0);
  signal sim_adc_data : SIM_ADC_DATA_TYPE;
  signal sim_adc_2_data : SIM_ADC_DATA_TYPE;  

  attribute syn_noprune of ADC_D_s2_C1 : signal is true;  
  attribute syn_noprune of ADC_D_s2_C2 : signal is true;   
  
  attribute syn_noprune of ADC_DR_s2_C1 : signal is true;  
  attribute syn_noprune of ADC_DR_s2_C2 : signal is true;  
  
  attribute syn_noprune of AdcClk_delay_1 : signal is true;  
  attribute syn_noprune of AdcClk_delay_2 : signal is true;
        
--+----------
-- Start of architecture code
--+----------
begin
  --+----------
  -- Global signal assignments for the architecture.
  --+----------
  ADC_CLK_1  <= AdcCLk_s;
  ADC_CLK_2  <= AdcCLk_s;
  
  ADC_DR1_IN <= ADC_DR1;
  ADC_DR2_IN <= ADC_DR2;
  
  DATA1    <= ADC_D_E_C1;
  DATA2    <= ADC_D_E_C2;
  
  DATARDY1 <= ADC_DR_FL_C1;
  DATARDY2 <= ADC_DR_FL_C2;
  
  sim_adc_data(0)   <= x"7FA";
  sim_adc_data(1)   <= x"7F8";
  sim_adc_data(2)   <= x"7F6";
  sim_adc_data(3)   <= x"7F4";
  sim_adc_data(4)   <= x"7F2";
  sim_adc_data(5)   <= x"7EF";
  sim_adc_data(6)   <= x"7EE";
  sim_adc_data(7)   <= x"7EE";
  sim_adc_data(8)   <= x"7A6";
  sim_adc_data(9)   <= x"65A";
  sim_adc_data(10)  <= x"439";
  sim_adc_data(11)  <= x"245";
  sim_adc_data(12)  <= x"0FC";
  sim_adc_data(13)  <= x"08B";
  sim_adc_data(14)  <= x"0CC";
  sim_adc_data(15)  <= x"189";
  sim_adc_data(16)  <= x"285";
  sim_adc_data(17)  <= x"393";
  sim_adc_data(18)  <= x"483";
  sim_adc_data(19)  <= x"55C";
  sim_adc_data(20)  <= x"629";
  sim_adc_data(21)  <= x"6B1";
  sim_adc_data(22)  <= x"7FC";
  sim_adc_data(23)  <= x"771";
  sim_adc_data(24)  <= x"7B0";
  sim_adc_data(25)  <= x"7DA";
  sim_adc_data(26)  <= x"7FA";
  sim_adc_data(27)  <= x"7FA";
  sim_adc_data(28)  <= x"7FA";
  sim_adc_data(29)  <= x"7FA";
  sim_adc_data(30)  <= x"7FA";
  sim_adc_data(31)  <= x"7FA";
  sim_adc_data(32)  <= x"7FA";
  sim_adc_data(33)  <= x"7FA";
  sim_adc_data(34)  <= x"7FA";
  sim_adc_data(35)  <= x"7FA";
  sim_adc_data(36)  <= x"7FA";
  sim_adc_data(37)  <= x"7FA";
  sim_adc_data(38)  <= x"7FA";
  sim_adc_data(39)  <= x"7FA";
  sim_adc_data(40)  <= x"7FA";
  sim_adc_data(41)  <= x"7FA";
  sim_adc_data(42)  <= x"7FA";
  sim_adc_data(43)  <= x"7FA";
  sim_adc_data(44)  <= x"7FA";
  sim_adc_data(45)  <= x"7FA";
  sim_adc_data(46)  <= x"7FA";
  sim_adc_data(47)  <= x"7FA";
  sim_adc_data(48)  <= x"7FA";
  sim_adc_data(49)  <= x"7FA";
  sim_adc_data(50)  <= x"7FA";
  sim_adc_data(51)  <= x"7FA";
  sim_adc_data(52)  <= x"7FA";
  sim_adc_data(53)  <= x"7FA";
  sim_adc_data(54)  <= x"7FA";
  sim_adc_data(55)  <= x"7FA";
  sim_adc_data(56)  <= x"7FA";
  sim_adc_data(57)  <= x"7FA";
  sim_adc_data(58)  <= x"7FA";
  sim_adc_data(59)  <= x"7FA";
  sim_adc_data(60)  <= x"7FA";
  sim_adc_data(61)  <= x"7FA";
  sim_adc_data(62)  <= x"7FA";
  sim_adc_data(63)  <= x"7FA";
  sim_adc_data(64)  <= x"7FA";
  sim_adc_data(65)  <= x"7FA";
  sim_adc_data(66)  <= x"7FA";
  sim_adc_data(67)  <= x"811";
  sim_adc_data(68)  <= x"812";
  sim_adc_data(69)  <= x"812";
  sim_adc_data(70)  <= x"813";
  sim_adc_data(71)  <= x"814";
  sim_adc_data(72)  <= x"812";
  sim_adc_data(73)  <= x"812";
  sim_adc_data(74)  <= x"812";
  sim_adc_data(75)  <= x"85A";
  sim_adc_data(76)  <= x"9A6";
  sim_adc_data(77)  <= x"BC7";
  sim_adc_data(78)  <= x"DBB";
  sim_adc_data(79)  <= x"F04";
  sim_adc_data(80)  <= x"F75";
  sim_adc_data(81)  <= x"F34";
  sim_adc_data(82)  <= x"E77";
  sim_adc_data(83)  <= x"D7B";
  sim_adc_data(84)  <= x"C6D";
  sim_adc_data(85)  <= x"B7D";
  sim_adc_data(86)  <= x"AA4";
  sim_adc_data(87)  <= x"9D7";
  sim_adc_data(88)  <= x"94F";
  sim_adc_data(89)  <= x"804";
  sim_adc_data(90)  <= x"88F";
  sim_adc_data(91)  <= x"850";
  sim_adc_data(92)  <= x"826";
  sim_adc_data(93)  <= x"806";
  sim_adc_data(94)  <= x"7FA";
  sim_adc_data(95)  <= x"7FA";
  sim_adc_data(96)  <= x"7FA";
  sim_adc_data(97)  <= x"7FA";
  sim_adc_data(98)  <= x"7FA";
  sim_adc_data(99)  <= x"7FA";


  AdcClkFreqProc : process (CLK100,RST)
  begin
  
    if (RST = '1') then
         AdcCLk_s     <= '0';
    elsif (rising_edge(CLK100)) then
       if (i_stop_req = '0') then
        if(AdcClkFreq_s = "01" or AdcClkFreq_s = "11") then
            AdcCLk_s     <= not AdcCLk_s;
        else
            AdcCLk_s     <=  AdcCLk_s;
        end if;    
       end if; 
    end if;

  end process AdcClkFreqProc;
  
  AdcClkGenProc : process (CLK100,RST)
  begin

    if (RST = '1') then
         AdcClkFreq_s <= (others =>'0');
    elsif (rising_edge(CLK100)) then      
         AdcClkFreq_s <= AdcClkFreq_s +'1';
    end if;

  end process AdcClkGenProc;
  
  --Adc_clk_delay_proc : process (CLK100)
  --begin
    --if (RST = '1') then
         --AdcClk_delay_1 <= '0';
         --AdcClk_delay_2 <= '0';
    --elsif(rising_edge(CLK100)) then
        --if (i_stop_req = '0') then    
            --AdcClk_delay_1 <= AdcClk_s;
            --AdcClk_delay_2 <= AdcClk_delay_1;
        --else
            --AdcClk_delay_1 <= AdcClk_delay_1;
            --AdcClk_delay_2 <= AdcClk_delay_2;
        --end if;
    --end if;
    --end process Adc_clk_delay_proc;
  
  --+----------
  -- EdgeDetectProc:
  --       This module captures rising and falling edges
  --       of data ready flag.
  --+----------
EdgeDetectProc_C1 : process (CLK100,RST)
  begin
    if (RST = '1') then
              ADC_DR_s_C1       <= '0';
              ADC_DR_s1_C1      <= '0';
              ADC_DR_s2_C1      <= '0';
              ADC_DR_FL_C1      <= '0';
              ADC_D_s1_C1       <= (others =>'0');
              ADC_D_s2_C1       <= (others =>'0');
              simulated_adc_cnt <= 0;
    elsif (rising_edge(CLK100)) then
        if(i_stop_req = '0') then
                ADC_DR_s_C1     <= AdcCLk_s;
                ADC_DR_s1_C1    <= ADC_DR_s_C1;
                ADC_DR_s2_C1    <= ADC_DR_s1_C1;
                ADC_D_s1_C1     <= ADC_D1;
                ADC_D_s2_C1     <= ADC_D_s1_C1;
          -- falling edge  and ADC_OR1 = '0'
           if ((ADC_DR_s1_C1 and not ADC_DR_s2_C1) = '1') then
				ADC_DR_FL_C1 <= '1';
              if(simulated_adc_cnt < 100) then
                  ADC_D_E_C1<= sim_adc_data(simulated_adc_cnt);
			      simulated_adc_cnt <= simulated_adc_cnt + 1;
			  else
			      ADC_D_E_C1<= sim_adc_data(0);
			      simulated_adc_cnt <= 1;
			  end if;
            else 
				ADC_DR_FL_C1 <= '0';
		    end if;
        end if;
    end if;
end process  EdgeDetectProc_C1;



EdgeDetectProc_C2 : process (CLK100,RST)
begin
    if (RST = '1') then
      ADC_DR_s_C2    <= '0';
      ADC_DR_s1_C2   <= '0';
      ADC_DR_s2_C2   <= '0';
      ADC_DR_FL_C2   <= '0';
      ADC_D_s1_C2    <= (others =>'0');
      ADC_D_s2_C2    <= (others =>'0');
      simulated_adc_2_cnt <= 0;    
    elsif(rising_edge(CLK100)) then
       if(i_stop_req = '0') then
          ADC_DR_s_C2     <= AdcCLk_s;
          ADC_DR_s1_C2    <= ADC_DR_s_C2;
          ADC_DR_s2_C2    <= ADC_DR_s1_C2;
          ADC_D_s1_C2     <= ADC_D2;
          ADC_D_s2_C2     <= ADC_D_s1_C2;
          -- falling edge  and ADC_OR2 = '0'
            if ((ADC_DR_s1_C2  and not ADC_DR_s2_C2 ) = '1') then   
              ADC_DR_FL_C2 <= '1';
              if(simulated_adc_2_cnt < 100) then
                  ADC_D_E_C2<= sim_adc_data(simulated_adc_2_cnt);
			      simulated_adc_2_cnt <= simulated_adc_2_cnt + 1;
			  else
			      ADC_D_E_C2<= sim_adc_data(0);
			      simulated_adc_2_cnt <= 1;
			  end if;		
            else
                ADC_DR_FL_C2 <= '0';
            end if;
        end if;
    end if;
end process  EdgeDetectProc_C2;

  

end architecture ReadAdc_RTL ;
--============================================================================
-- Architecture definition section end - RTL
--****************************************************************************


--****************************************************************************
-- Module trailer section starts
--============================================================================
--
--
--
--
--
--============================================================================
-- Module trailer section ends
--****************************************************************************
