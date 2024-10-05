
--+----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_STD.all;

--+----------
entity TimeStampCtrl is
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
       CLK100        :in  std_logic;
       RST           :in  std_logic;
       DATARDY1      :in  std_logic;
       DATARDY2      :in  std_logic;
       TIMESTAMP_C1  :out std_logic_vector(DataVecSize_g-WdVecSize_g-1 downto 0);
       TIMESTAMP_C2  :out std_logic_vector(DataVecSize_g-WdVecSize_g-1 downto 0)
         );

end entity TimeStampCtrl;
--============================================================================
-- Entity declaration section end
--****************************************************************************


--****************************************************************************
-- Architecture definition section start - RTL
--============================================================================
architecture TimeStampCtrl_RTL of TimeStampCtrl is
attribute syn_preserve : boolean;
attribute syn_preserve of TimeStampCtrl_RTL: architecture is true;
  --+----------
  -- Constants, types and signals declarations start here for the architecture
  --+----------
  
  signal TimeStamp_s_C1 :std_logic_vector(DataVecSize_g-WdVecSize_g-1 downto 0)
                      :=(others=>'0');  
  signal TimeStamp_s_C2 :std_logic_vector(DataVecSize_g-WdVecSize_g-1 downto 0)
                      :=(others=>'0');
--+----------
-- Start of architecture code
--+----------
begin
  --+----------
  -- Global signal assignments for the architecture.
  --+----------
  TIMESTAMP_C1 <= TimeStamp_s_C1;
  TIMESTAMP_C2 <= TimeStamp_s_C2;
    --+----------
  TimeStampProc_C1 : process (CLK100)
  begin
    if (rising_edge(CLK100))then
      if (RST = '1' ) then
        TimeStamp_s_C1 <=(others=>'0');
      elsif(DATARDY1 ='1') then
        TimeStamp_s_C1 <= TimeStamp_s_C1 + 1;
      else
        TimeStamp_s_C1 <= TimeStamp_s_C1;
      end if;
    end if;
  end process  TimeStampProc_C1;
  
  TimeStampProc_C2 : process (CLK100)
  begin
    if (rising_edge(CLK100))then
      if (RST = '1' ) then
        TimeStamp_s_C2 <=(others=>'0');
      elsif(DATARDY2 ='1') then
        TimeStamp_s_C2 <= TimeStamp_s_C2 + 1;
      else
        TimeStamp_s_C2 <= TimeStamp_s_C2;
      end if;
    end if;
  end process  TimeStampProc_C2;

end architecture TimeStampCtrl_RTL;
--============================================================================
-- Architecture definition section end - RTL
--****************************************************************************

