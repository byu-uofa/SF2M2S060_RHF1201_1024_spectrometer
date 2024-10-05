--****************************************************************************
--    Copyright(c) 2010 Routes AstroEngineering Ltd. All Rights Reserved.
--****************************************************************************


--****************************************************************************
-- Module header section start
--============================================================================
--  TEMPLATE NUMBER     : RAEN-990-00121-FRM Rev 1.1
--  PROJECT NAME        : ORBITALS HEPT
--  MODULE NAME         : ReadAdc
--  MODULE AUTHOR       : Josée Cayer
--  DATE CREATED        : 08-Feb-10
--  MODULE PART NUMBER  : [Module part number assigned by CMO/Manufacturing]
--  MODULE VERSION      : v00.01
--  MODULE LANGUAGE     : VHDL-93
--  SUBVERSION RELEASE  :
--
--  DESCRIPTION/NOTES:
--        Module to clock data from imaging ADC and pass it on to another module
--        at 25MHz
--
-- ******--*****--******--*****--******--*****--******--*****--******--*****--
--
-- ******--*****--******--*****--******--*****--******--*****--******--*****--
--
--
-- ******--*****--******--*****--******--*****--******--*****--******--*****--
--  MODULE CHANGE HISTORY (latest release info is the first line entry)
-- ******--*****--******--*****--******--*****--******--*****--******--*****--
--
-- +--------+--------+-----------+--------------------------------------------
-- |VERSION |AUTHOR  |DATE       |DESCRIPTION OF CHANGE
-- +--------+--------+-----------+--------------------------------------------
--  v00.01     jc     08-Feb-10   Created.
--============================================================================
-- Module header section end
--****************************************************************************


--****************************************************************************
-- Libraries and packages declarations section start
--============================================================================
--+----------
--  Generic library packages applicable for all work done with VHDL. Routes
--  only uses the IEEE standard packages at this time.
--+----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_STD.all;

--+----------
--  Company standard library packages applicable for all projects. These
--  library packages contain declarations and functions specific to FPGA
--  manufacturers and families.
--+----------
--library RoutesAstro_lib;
--use RoutesAstro_lib.Xilinx_pkg.all;
--use RoutesAstro_lib.Actel_pkg.all;

--+----------
--  Specific manufacturer-defined library packages that are required to
--  support primitive instantiation or simulation of FPGA code. The packages
--  are usually specified by the chip manufacturer and the use of the packages
--  is documented in the manufacturer documentation
--+----------
--  Xilinx primitives instantiation library/packages.
--+----------

--+----------
--  Project library and packages applicable to the project. These packages
--  contain declarations and functions specific to the project and common
--  to all project assemblies and FPGAs.
--+----------
--library [Project-specific folder name_lib];
--use [Project-specific folder name_lib].[libpackage_1 name_pkg].all;
--use [Project-specific folder name_lib].[libpackage_2 name_pkg].all;
--use [Project-specific folder name_lib].[libpackage_n name_pkg].all;
--============================================================================
-- Libraries and packages declarations section end
--****************************************************************************


--****************************************************************************
-- Entity declaration section start
--============================================================================
entity ReadAdc is
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
--       TEST       :in  std_logic;    
       ADC_CLK    :out std_logic;   
       
       ADC_D1      :in  std_logic_vector(WdVecSize_g-5 downto 0);
       ADC_DR1     :in  std_logic;
       
       ADC_D2      :in  std_logic_vector(WdVecSize_g-5 downto 0);
       ADC_DR2     :in  std_logic;
       
       ADC_D3      :in  std_logic_vector(WdVecSize_g-5 downto 0);
       ADC_DR3     :in  std_logic;
       
       ADC_D4     :in  std_logic_vector(WdVecSize_g-5 downto 0);
       ADC_DR4     :in  std_logic;
       
       i_DR1_EN    : in std_logic;
       i_DR2_EN    : in std_logic;
       i_DR3_EN    : in std_logic;
       i_DR4_EN    : in std_logic;
       
       DATA1       :out std_logic_vector(WdVecSize_g-5 downto 0);
       DATARDY1    :out std_logic;
       
       DATA2       :out std_logic_vector(WdVecSize_g-5 downto 0);
       DATARDY2    :out std_logic;
       
       DATA3      :out std_logic_vector(WdVecSize_g-5 downto 0);
       DATARDY3    :out std_logic;
       
       DATA4       :out std_logic_vector(WdVecSize_g-5 downto 0);
       DATARDY4    :out std_logic;
	  
	   
	   i_stop_req  :in  std_logic 
         );

end entity ReadAdc;
--============================================================================
-- Entity declaration section end
--****************************************************************************


--****************************************************************************
-- Architecture definition section start - RTL
--============================================================================
architecture ReadAdc_RTL of ReadAdc is
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
  signal AdcClkFreq_s    :std_logic_vector (NibbleSize_g-2 downto 0)
                         := (others =>'0');  
  signal CntAdcClk_s     :integer:=0;
  signal AdcClk_s        :std_logic:='0';
  signal AdcClk_delay_1    :std_logic:='0';
  signal AdcClk_delay_2    :std_logic:='0';
  
  signal ADC_DR_FL_C1    :std_logic:='0'; 
  signal ADC_DR_FL_C2    :std_logic:='0';
  signal ADC_DR_FL_C3    :std_logic:='0';
  signal ADC_DR_FL_C4    :std_logic:='0';

  -- capture rising and falling edges
  signal ADC_DR1_IN      :std_logic:='0'; /* synthesis preserve=1*/
  signal ADC_DR2_IN      :std_logic:='0'; /* synthesis preserve=1*/
  signal ADC_DR3_IN      :std_logic:='0'; /* synthesis preserve=1*/
  signal ADC_DR4_IN      :std_logic:='0'; /* synthesis preserve=1*/
        

  signal ADC_DR_s_C1     :std_logic:='0';
  signal ADC_DR_s_C2     :std_logic:='0';
  signal ADC_DR_s_C3     :std_logic:='0';
  signal ADC_DR_s_C4     :std_logic:='0';
  
  signal ADC_DR_s1_C1    :std_logic:='0';
  signal ADC_DR_s1_C2    :std_logic:='0';
  signal ADC_DR_s1_C3    :std_logic:='0';
  signal ADC_DR_s1_C4    :std_logic:='0'; 
  
  signal ADC_DR_s2_C1    :std_logic:='0';
  signal ADC_DR_s2_C2    :std_logic:='0'; 
  signal ADC_DR_s2_C3    :std_logic:='0';  
  signal ADC_DR_s2_C4    :std_logic:='0';
  
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
                      
  signal ADC_D_s1_C3     :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0'); /* synthesis preserve=1*/
  signal ADC_D_s2_C3     :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0'); /* synthesis preserve=1*/
  signal ADC_D_E_C3      :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0'); /* synthesis preserve=1*/   
                      
  signal ADC_D_s1_C4     :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0'); /* synthesis preserve=1*/
  signal ADC_D_s2_C4     :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0'); /* synthesis preserve=1*/
  signal ADC_D_E_C4      :std_logic_vector(WdVecSize_g-5 downto 0)
                      :=(others =>'0'); /* synthesis preserve=1*/  
  signal s_DR1_EN     :std_logic;               
  signal s_DR2_EN     :std_logic;               
  signal s_DR3_EN     :std_logic;               
  signal s_DR4_EN     :std_logic;    
               
  signal adc_cnt      :std_logic_vector(3 downto 0)
                      :=(others =>'0');  
  
  signal simulated_adc_cnt           : integer:=0       ;
  
  type SIM_ADC_DATA_TYPE is array (0 to 99) of std_logic_vector(11 downto 0);
  signal sim_adc_data : SIM_ADC_DATA_TYPE;	
  

  attribute syn_noprune of ADC_D_s2_C1 : signal is true;  
  attribute syn_noprune of ADC_D_s2_C2 : signal is true;  
  attribute syn_noprune of ADC_D_s2_C3 : signal is true;  
  attribute syn_noprune of ADC_D_s2_C4 : signal is true;  
  
  attribute syn_noprune of ADC_DR_s2_C1 : signal is true;  
  attribute syn_noprune of ADC_DR_s2_C2 : signal is true;  
  attribute syn_noprune of ADC_DR_s2_C3 : signal is true;  
  attribute syn_noprune of ADC_DR_s2_C4 : signal is true;  
  
  attribute syn_noprune of AdcClk_delay_1 : signal is true;  
  attribute syn_noprune of AdcClk_delay_2 : signal is true;
        
--+----------
-- Start of architecture code
--+----------
begin
  --+----------
  -- Global signal assignments for the architecture.
  --+----------
  ADC_CLK    <= AdcCLk_s;
  
  ADC_DR1_IN <= ADC_DR1;
  ADC_DR2_IN <= ADC_DR2;
  ADC_DR3_IN <= ADC_DR3;
  ADC_DR4_IN <= ADC_DR4;
  
  DATA1    <= ADC_D_E_C1;
  DATA2    <= ADC_D_E_C2;
  DATA3    <= ADC_D_E_C3;
  DATA4    <= ADC_D_E_C4;
    
  DATARDY1 <= ADC_DR_FL_C1;
  DATARDY2 <= ADC_DR_FL_C2;
  DATARDY3 <= ADC_DR_FL_C3;
  DATARDY4 <= ADC_DR_FL_C4;
  
  s_DR1_EN <= i_DR1_EN;
  s_DR2_EN <= i_DR2_EN;
  s_DR3_EN <= i_DR3_EN;
  s_DR4_EN <= i_DR4_EN;
  
   
  AdcClkFreqProc : process (CLK100)
  begin
  
    if (RST = '1') then
         AdcCLk_s     <= '0';
    elsif (rising_edge(CLK100)) then
       if (i_stop_req = '0' and AdcClkFreq_s = "011") then
          AdcCLk_s     <= not AdcCLk_s;
       else
          AdcCLk_s     <=  AdcCLk_s;
       end if; 
    end if;

  end process AdcClkFreqProc;
  
  AdcClkGenProc : process (CLK100)
  begin

    if (RST = '1') then
         AdcClkFreq_s <= (others =>'0');
    elsif (rising_edge(CLK100)) then      
        if (AdcClkFreq_s = "011") then
         AdcClkFreq_s <= (others =>'0');
        else
         AdcClkFreq_s <= AdcClkFreq_s +'1';
        end if; 
    end if;

  end process AdcClkGenProc;
  
  Adc_clk_delay_proc : process (CLK100)
  begin
    if (RST = '1') then
         AdcClk_delay_1 <= '0';
         AdcClk_delay_2 <= '0';
    elsif(rising_edge(CLK100)) then
        if (i_stop_req = '0') then    
            AdcClk_delay_1 <= AdcClk_s;
            AdcClk_delay_2 <= AdcClk_delay_1;
        else
            AdcClk_delay_1 <= AdcClk_delay_1;
            AdcClk_delay_2 <= AdcClk_delay_2;
        end if;
    end if;
    end process Adc_clk_delay_proc;
  
  --+----------
  -- EdgeDetectProc:
  --       This module captures rising and falling edges
  --       of data ready flag.
  --+----------
EdgeDetectProc_C1 : process (CLK100)
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
    if(i_stop_req = '0' and s_DR1_EN = '1') then
              ADC_DR_s_C1     <= ADC_DR1_IN;
              ADC_DR_s1_C1    <= ADC_DR_s_C1;
              ADC_DR_s2_C1    <= ADC_DR_s1_C1;
              ADC_D_s1_C1     <= ADC_D1;
              ADC_D_s2_C1     <= ADC_D_s1_C1;
      -- falling edge  and ADC_OR1 = '0'
       if ((ADC_DR_s2_C1 and not ADC_DR_s1_C1) = '1') then
              ADC_DR_FL_C1 <= '1';
			  ADC_D_E_C1<= ADC_D_s1_C1;
       else
              ADC_DR_FL_C1 <= '0';
       end if;
   elsif(i_stop_req = '0' and s_DR2_EN = '1') then         
              ADC_DR_s_C1     <= ADC_DR2_IN;
              ADC_DR_s1_C1    <= ADC_DR_s_C1;
              ADC_DR_s2_C1    <= ADC_DR_s1_C1;
              ADC_D_s1_C1     <= ADC_D1;
              ADC_D_s2_C1     <= ADC_D_s1_C1;

      if ((ADC_DR_s2_C1 and not ADC_DR_s1_C1) = '1') then
              ADC_DR_FL_C1 <= '1';
			  ADC_D_E_C1<= ADC_D_s1_C1;
      else
              ADC_DR_FL_C1 <= '0';
      end if;

   elsif(i_stop_req = '0' and s_DR3_EN = '1') then         
              ADC_DR_s_C1     <= ADC_DR3_IN;
              ADC_DR_s1_C1    <= ADC_DR_s_C1;
              ADC_DR_s2_C1    <= ADC_DR_s1_C1;
              ADC_D_s1_C1     <= ADC_D1;
              ADC_D_s2_C1     <= ADC_D_s1_C1;
	  
      if ((ADC_DR_s2_C1 and not ADC_DR_s1_C1) = '1') then
              ADC_DR_FL_C1 <= '1';
			  ADC_D_E_C1<= ADC_D_s1_C1;
      else
              ADC_DR_FL_C1 <= '0';
      end if;
      
   elsif(i_stop_req = '0' and s_DR4_EN = '1') then             
      ADC_DR_s_C1     <= ADC_DR4_IN;
      ADC_DR_s1_C1    <= ADC_DR_s_C1;
      ADC_DR_s2_C1    <= ADC_DR_s1_C1;
      ADC_D_s1_C1     <= ADC_D1;
	  ADC_D_s2_C1     <= ADC_D_s1_C1;

      if ((ADC_DR_s2_C1 and not ADC_DR_s1_C1) = '1') then
              ADC_DR_FL_C1 <= '1';
			  ADC_D_E_C1<= ADC_D_s1_C1;
      else
              ADC_DR_FL_C1 <= '0';
      end if;     
   end if;
end if;
end process  EdgeDetectProc_C1;



EdgeDetectProc_C2 : process (CLK100)
  begin
if (RST = '1') then
      ADC_DR_s_C2    <= '0';
      ADC_DR_s1_C2   <= '0';
      ADC_DR_s2_C2   <= '0';
      ADC_DR_FL_C2   <= '0';
      ADC_D_s1_C2    <= (others =>'0');
      ADC_D_s2_C2    <= (others =>'0');
elsif(rising_edge(CLK100)) then
   
   if(i_stop_req = '0' and s_DR1_EN = '1') then
      ADC_DR_s_C2     <= ADC_DR1_IN;
      ADC_DR_s1_C2    <= ADC_DR_s_C2;
      ADC_DR_s2_C2    <= ADC_DR_s1_C2;
      ADC_D_s1_C2     <= ADC_D2;
	  ADC_D_s2_C2     <= ADC_D_s1_C2;
      -- falling edge  and ADC_OR2 = '0'
        if ((ADC_DR_s2_C2  and not ADC_DR_s1_C2 ) = '1') then   
              ADC_DR_FL_C2 <= '1';
			  ADC_D_E_C2<= ADC_D_s1_C2;
        else
              ADC_DR_FL_C2 <= '0';
        end if;
         
    elsif(i_stop_req = '0' and s_DR2_EN = '1') then
      ADC_DR_s_C2     <= ADC_DR2_IN;
      ADC_DR_s1_C2    <= ADC_DR_s_C2;
      ADC_DR_s2_C2    <= ADC_DR_s1_C2;
      ADC_D_s1_C2     <= ADC_D2;
	  ADC_D_s2_C2     <= ADC_D_s1_C2;

        if ((ADC_DR_s2_C2  and not ADC_DR_s1_C2 ) = '1') then   
              ADC_DR_FL_C2 <= '1';
			  ADC_D_E_C2<= ADC_D_s1_C2;
        else
              ADC_DR_FL_C2 <= '0';
        end if;
        
    elsif(i_stop_req = '0' and s_DR3_EN = '1') then    
      ADC_DR_s_C2     <= ADC_DR3_IN;
      ADC_DR_s1_C2    <= ADC_DR_s_C2;
      ADC_DR_s2_C2    <= ADC_DR_s1_C2;
      ADC_D_s1_C2     <= ADC_D2;
	  ADC_D_s2_C2     <= ADC_D_s1_C2;

        if ((ADC_DR_s2_C2  and not ADC_DR_s1_C2 ) = '1') then   
              ADC_DR_FL_C2 <= '1';
			  ADC_D_E_C2<= ADC_D_s1_C2;
        else
              ADC_DR_FL_C2 <= '0';
        end if;
        
    elsif(i_stop_req = '0' and s_DR4_EN = '1') then       
      ADC_DR_s_C2     <= ADC_DR4_IN;
      ADC_DR_s1_C2    <= ADC_DR_s_C2;
      ADC_DR_s2_C2    <= ADC_DR_s1_C2;
      ADC_D_s1_C2     <= ADC_D2;
	  ADC_D_s2_C2     <= ADC_D_s1_C2;

        if ((ADC_DR_s2_C2  and not ADC_DR_s1_C2 ) = '1') then   
              ADC_DR_FL_C2 <= '1';
			  ADC_D_E_C2<= ADC_D_s1_C2;
        else
              ADC_DR_FL_C2 <= '0';
        end if;
                
    end if;
end if;
end process  EdgeDetectProc_C2;

EdgeDetectProc_C3 : process (CLK100)
  begin
    if (RST = '1') then
      ADC_DR_s_C3    <= '0';
      ADC_DR_s1_C3   <= '0';
      ADC_DR_s2_C3   <= '0';
      ADC_DR_FL_C3   <= '0';
      ADC_D_s1_C3    <= (others =>'0');
      ADC_D_s2_C3    <= (others =>'0');
   elsif(rising_edge(CLK100)) then
   
    if(i_stop_req = '0' and s_DR1_EN = '1') then
      ADC_DR_s_C3     <= ADC_DR1_IN;
      ADC_DR_s1_C3    <= ADC_DR_s_C3;
      ADC_DR_s2_C3    <= ADC_DR_s1_C3;
      ADC_D_s1_C3     <= ADC_D3;
	  ADC_D_s2_C3     <= ADC_D_s1_C3;

         if ((ADC_DR_s2_C3 and not ADC_DR_s1_C3) = '1') then
              ADC_DR_FL_C3 <= '1';
              ADC_D_E_C3<= ADC_D_s1_C3;
         else
              ADC_DR_FL_C3 <= '0';
         end if;
      
    elsif(i_stop_req = '0' and s_DR2_EN = '1') then
      ADC_DR_s_C3     <= ADC_DR2_IN;
      ADC_DR_s1_C3    <= ADC_DR_s_C3;
      ADC_DR_s2_C3    <= ADC_DR_s1_C3;
      ADC_D_s1_C3     <= ADC_D3;
	  ADC_D_s2_C3     <= ADC_D_s1_C3;

         if ((ADC_DR_s2_C3 and not ADC_DR_s1_C3) = '1') then
              ADC_DR_FL_C3 <= '1';
              ADC_D_E_C3<= ADC_D_s1_C3;
         else
              ADC_DR_FL_C3 <= '0';
         end if;
     
    elsif(i_stop_req = '0' and s_DR3_EN = '1') then
      ADC_DR_s_C3     <= ADC_DR3_IN;
      ADC_DR_s1_C3    <= ADC_DR_s_C3;
      ADC_DR_s2_C3    <= ADC_DR_s1_C3;
      ADC_D_s1_C3     <= ADC_D3;
	  ADC_D_s2_C3     <= ADC_D_s1_C3;

         if ((ADC_DR_s2_C3 and not ADC_DR_s1_C3) = '1') then
              ADC_DR_FL_C3 <= '1';
              ADC_D_E_C3<= ADC_D_s1_C3;
         else
              ADC_DR_FL_C3 <= '0';
         end if;
         
    elsif(i_stop_req = '0' and s_DR4_EN = '1') then
      ADC_DR_s_C3     <= ADC_DR4_IN;
      ADC_DR_s1_C3    <= ADC_DR_s_C3;
      ADC_DR_s2_C3    <= ADC_DR_s1_C3;
      ADC_D_s1_C3     <= ADC_D3;
	  ADC_D_s2_C3     <= ADC_D_s1_C3;

         if ((ADC_DR_s2_C3 and not ADC_DR_s1_C3) = '1') then
              ADC_DR_FL_C3 <= '1';
              ADC_D_E_C3<= ADC_D_s1_C3;
         else
              ADC_DR_FL_C3 <= '0';
         end if;
         
   end if;
end if;
end process  EdgeDetectProc_C3;

EdgeDetectProc_C4 : process (CLK100)
  begin
    if (RST = '1') then
      ADC_DR_s_C4    <= '0';
      ADC_DR_s1_C4   <= '0';
      ADC_DR_s2_C4   <= '0';
      ADC_DR_FL_C4   <= '0';
      ADC_D_s1_C4    <= (others =>'0');
      ADC_D_s2_C4    <= (others =>'0');
   elsif(rising_edge(CLK100)) then
   
    if(i_stop_req = '0' and s_DR1_EN = '1') then
      ADC_DR_s_C4     <= ADC_DR1_IN;
      ADC_DR_s1_C4    <= ADC_DR_s_C4;
      ADC_DR_s2_C4    <= ADC_DR_s1_C4;
      ADC_D_s1_C4     <= ADC_D4;
	  ADC_D_s2_C4     <= ADC_D_s1_C4;

         if ((ADC_DR_s2_C4 and not ADC_DR_s1_C4) = '1') then
              ADC_DR_FL_C4 <= '1';
              ADC_D_E_C4<= ADC_D_s1_C4;
         else
              ADC_DR_FL_C4 <= '0';
         end if;   
      
    elsif(i_stop_req = '0' and s_DR2_EN = '1') then
      ADC_DR_s_C4     <= ADC_DR2_IN;
      ADC_DR_s1_C4    <= ADC_DR_s_C4;
      ADC_DR_s2_C4    <= ADC_DR_s1_C4;
      ADC_D_s1_C4     <= ADC_D4;
	  ADC_D_s2_C4     <= ADC_D_s1_C4;
	  
         if ((ADC_DR_s2_C4 and not ADC_DR_s1_C4) = '1') then
              ADC_DR_FL_C4 <= '1';
              ADC_D_E_C4<= ADC_D_s1_C4;
         else
              ADC_DR_FL_C4 <= '0';
         end if;   
     
    elsif(i_stop_req = '0' and s_DR3_EN = '1') then
       ADC_DR_s_C4     <= ADC_DR3_IN;
       ADC_DR_s1_C4    <= ADC_DR_s_C4;
       ADC_DR_s2_C4    <= ADC_DR_s1_C4;
       ADC_D_s1_C4     <= ADC_D4;
	   ADC_D_s2_C4     <= ADC_D_s1_C4;

         if ((ADC_DR_s2_C4 and not ADC_DR_s1_C4) = '1') then
              ADC_DR_FL_C4 <= '1';
              ADC_D_E_C4<= ADC_D_s1_C4;
         else
              ADC_DR_FL_C4 <= '0';
         end if;   
         
    elsif(i_stop_req = '0' and s_DR4_EN = '1') then
       ADC_DR_s_C4     <= ADC_DR4_IN;
       ADC_DR_s1_C4    <= ADC_DR_s_C4;
       ADC_DR_s2_C4    <= ADC_DR_s1_C4;
       ADC_D_s1_C4     <= ADC_D4;
	   ADC_D_s2_C4     <= ADC_D_s1_C4;

         if ((ADC_DR_s2_C4 and not ADC_DR_s1_C4) = '1') then
              ADC_DR_FL_C4 <= '1';
              ADC_D_E_C4<= ADC_D_s1_C4;
         else
              ADC_DR_FL_C4 <= '0';
         end if;   

    end if;
end if;
end process  EdgeDetectProc_C4;
  

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
