-- ----------------------------------------------------------------------------
--              : Copyright (C) 2019 COM DEV International. All rights
--              : reserved. Use is subject to COM DEV International's
--              : standard license terms. Unauthorized duplication or
--              : distribution is strictly prohibited. Permission to use,
--              : copy, and distribute any of the information herein is
--              : subject to COM DEV International prior written consent.
-- ----------------------------------------------------------------------------
-- File Name    : crc16_gen.vhd
--              :
-- Project      : SMILE 
-- Author       : Muhammad Amjad
-- Created      : Jul 18, 2019
--
-- Description  : It generates CRC-16, have two version, serial and 8-bit/16-bit parall.
--
-- SVN keywords : $Rev: 42 $
--                $Author: mamjad $
--                $Date: 2019-09-01 23:56:56 -0400 (Sun, 01 Sep 2019) $
-- -----------------------------------------------------------------------------
-- Revision history : 
--   Ver   | Author             | Mod. Date     |    Changes Made:
--   v0.1  | M. Amjad           | Jul 18, 2019  |    Initial Creation
--   v0.2  | M. Bakieh          | Aug 30, 2019  |    Added ports for further testing with upper level using parallel CRC.
--          
-- -----------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all;
-------------------------------------------------------------------------------
entity crc16_gen is 
  port ( 
    i_clk                         : in std_logic;
    i_reset                       : in std_logic;
    i_8bit_data_in                : in std_logic_vector (7 downto 0);           --input data 
    i_8bit_data_in_vld            : in std_logic;                               --when high input data valid to start calcuatoin
    i_ref_crc_en                  : in std_logic;                               --when high use i_ref_crc_in as init value, else use previous value
    i_ref_crc_in                  : in std_logic_vector(15 downto 0);
    i_crc_init                    : in std_logic;                               --when high reset init to FFFF
    o_crc_data_out                : out std_logic_vector (15 downto 0);         --result of the calculation
    o_crc_data_out_vld            : out std_logic                               --when high the calculated data is valid for use by upper block
    );
end crc16_gen;
-------------------------------------------------------------------------------
architecture rtl of crc16_gen is
  signal s_old_crc                  : std_logic_vector (15 downto 0);
  signal s_new_crc                  : std_logic_vector (15 downto 0);
  signal s_8bit_data_in_vld_d1      : std_logic;
  signal s_8bit_data_in_vld_d2      : std_logic;  
-------------------------------------------------------------------------------
begin
-------------------------------------------------------------------------------	
    --o_crc_data_out <= s_old_crc;
    s_new_crc(0) <= s_old_crc(8) xor s_old_crc(12) xor i_8bit_data_in(0) xor i_8bit_data_in(4);
    s_new_crc(1) <= s_old_crc(9) xor s_old_crc(13) xor i_8bit_data_in(1) xor i_8bit_data_in(5);
    s_new_crc(2) <= s_old_crc(10) xor s_old_crc(14) xor i_8bit_data_in(2) xor i_8bit_data_in(6);
    s_new_crc(3) <= s_old_crc(11) xor s_old_crc(15) xor i_8bit_data_in(3) xor i_8bit_data_in(7);
    s_new_crc(4) <= s_old_crc(12) xor i_8bit_data_in(4);
    s_new_crc(5) <= s_old_crc(8) xor s_old_crc(12) xor s_old_crc(13) xor i_8bit_data_in(0) xor i_8bit_data_in(4) xor i_8bit_data_in(5);
    s_new_crc(6) <= s_old_crc(9) xor s_old_crc(13) xor s_old_crc(14) xor i_8bit_data_in(1) xor i_8bit_data_in(5) xor i_8bit_data_in(6);
    s_new_crc(7) <= s_old_crc(10) xor s_old_crc(14) xor s_old_crc(15) xor i_8bit_data_in(2) xor i_8bit_data_in(6) xor i_8bit_data_in(7);
    s_new_crc(8) <= s_old_crc(0) xor s_old_crc(11) xor s_old_crc(15) xor i_8bit_data_in(3) xor i_8bit_data_in(7);
    s_new_crc(9) <= s_old_crc(1) xor s_old_crc(12) xor i_8bit_data_in(4);
    s_new_crc(10) <= s_old_crc(2) xor s_old_crc(13) xor i_8bit_data_in(5);
    s_new_crc(11) <= s_old_crc(3) xor s_old_crc(14) xor i_8bit_data_in(6);
    s_new_crc(12) <= s_old_crc(4) xor s_old_crc(8) xor s_old_crc(12) xor s_old_crc(15) xor i_8bit_data_in(0) xor i_8bit_data_in(4) xor i_8bit_data_in(7);
    s_new_crc(13) <= s_old_crc(5) xor s_old_crc(9) xor s_old_crc(13) xor i_8bit_data_in(1) xor i_8bit_data_in(5);
    s_new_crc(14) <= s_old_crc(6) xor s_old_crc(10) xor s_old_crc(14) xor i_8bit_data_in(2) xor i_8bit_data_in(6);
    s_new_crc(15) <= s_old_crc(7) xor s_old_crc(11) xor s_old_crc(15) xor i_8bit_data_in(3) xor i_8bit_data_in(7);
    
-------------------------------------------------------------------------------
crc_ctrl_proc: process (i_clk,i_reset)
begin 
    if (i_reset = '1') then
        s_old_crc <= x"FFFF";
        s_8bit_data_in_vld_d1   <= '0';
        s_8bit_data_in_vld_d2   <= '0';
        
    elsif rising_edge(i_clk) then
        if (i_crc_init = '1') then
            s_old_crc <= x"FFFF";
        elsif i_8bit_data_in_vld = '1' then
            if i_ref_crc_en = '1' then 
                s_old_crc <= i_ref_crc_in; 
            else 
                s_old_crc <= s_new_crc;
            end if;
        end if;
        --delay in-valid by two clocks to align with output result
        s_8bit_data_in_vld_d1   <=i_8bit_data_in_vld;
        s_8bit_data_in_vld_d2   <= s_8bit_data_in_vld_d1;
   end if; 
end process; 

o_crc_data_out_vld  <= s_8bit_data_in_vld_d1;
o_crc_data_out      <= s_new_crc;           -- 231111 Byu changed to s_new_crc from s_old_crc       


---------------------------------------------------------------------------------
---- CRC module for data(7:0)
----   lfsr(15:0)=1+x^5+x^12+x^16;
---------------------------------------------------------------------------------
--library ieee; 
--use ieee.std_logic_1164.all;
--
--entity crc is 
--  port ( 
--    data_in : in std_logic_vector (7 downto 0);
--    crc_en , 
--    rst, 
--    clk : in std_logic;
--    crc_out : out std_logic_vector (15 downto 0));
--end crc;
--
--architecture imp_crc of crc is 
--  signal lfsr_q: std_logic_vector (15 downto 0); 
--  signal lfsr_c: std_logic_vector (15 downto 0); 
--begin 
--    crc_out <= lfsr_q;
--
--    lfsr_c(0) <= lfsr_q(8) xor lfsr_q(12) xor data_in(0) xor data_in(4);
--    lfsr_c(1) <= lfsr_q(9) xor lfsr_q(13) xor data_in(1) xor data_in(5);
--    lfsr_c(2) <= lfsr_q(10) xor lfsr_q(14) xor data_in(2) xor data_in(6);
--    lfsr_c(3) <= lfsr_q(11) xor lfsr_q(15) xor data_in(3) xor data_in(7);
--    lfsr_c(4) <= lfsr_q(12) xor data_in(4);
--    lfsr_c(5) <= lfsr_q(8) xor lfsr_q(12) xor lfsr_q(13) xor data_in(0) xor data_in(4) xor data_in(5);
--    lfsr_c(6) <= lfsr_q(9) xor lfsr_q(13) xor lfsr_q(14) xor data_in(1) xor data_in(5) xor data_in(6);
--    lfsr_c(7) <= lfsr_q(10) xor lfsr_q(14) xor lfsr_q(15) xor data_in(2) xor data_in(6) xor data_in(7);
--    lfsr_c(8) <= lfsr_q(0) xor lfsr_q(11) xor lfsr_q(15) xor data_in(3) xor data_in(7);
--    lfsr_c(9) <= lfsr_q(1) xor lfsr_q(12) xor data_in(4);
--    lfsr_c(10) <= lfsr_q(2) xor lfsr_q(13) xor data_in(5);
--    lfsr_c(11) <= lfsr_q(3) xor lfsr_q(14) xor data_in(6);
--    lfsr_c(12) <= lfsr_q(4) xor lfsr_q(8) xor lfsr_q(12) xor lfsr_q(15) xor data_in(0) xor data_in(4) xor data_in(7);
--    lfsr_c(13) <= lfsr_q(5) xor lfsr_q(9) xor lfsr_q(13) xor data_in(1) xor data_in(5);
--    lfsr_c(14) <= lfsr_q(6) xor lfsr_q(10) xor lfsr_q(14) xor data_in(2) xor data_in(6);
--    lfsr_c(15) <= lfsr_q(7) xor lfsr_q(11) xor lfsr_q(15) xor data_in(3) xor data_in(7);
--
--
--    process (clk,rst) begin 
--      if (rst = '1') then 
--        lfsr_q <= b"1111111111111111";
--      elsif (clk'EVENT and clk = '1') then 
--        if (crc_en = '1') then 
--          lfsr_q <= lfsr_c; 
--        end if; 
--      end if; 
--    end process; 
--end architecture imp_crc;

-------------------------------------------------------------------------------
end architecture rtl; 