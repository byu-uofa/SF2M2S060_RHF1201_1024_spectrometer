library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_STD.all;


entity LPDDR_FIFO_IF is

Port(
	i_clk                           :in  std_logic;
	i_reset                         :in  std_logic;
    
    s_tx_fifo_almost_full_tlm       :in  std_logic;                     -- output from UART_TOP UART_TX_FIFO
    o_tx_dv_tlm_s                   :out std_logic;                     -- output to the TX FIFO
	adc_data_tx_byte		        :out std_logic_vector(7 downto 0);  -- 8-bit adc data slice for serial port
    
    msc_read_adc_fifo_1		        :in  std_logic; 
    rd_en_adc_fifo_1			    :out std_logic;
	adc_data_rd_1      		        :in  std_logic_vector(11 downto 0); -- positive bin data from the adc_FIFO
    adc_fifo_empty_1                :in  std_logic;                     -- output from adc fifo 
    
    msc_read_adc_fifo_2		        :in  std_logic; 
    rd_en_adc_fifo_2			    :out std_logic;
	adc_data_rd_2      		        :in  std_logic_vector(11 downto 0); -- negtative bin data from the adc_FIFO
    adc_fifo_empty_2                :in  std_logic;                     -- output from adc fifo 
    
    msc_read_peak_fifo_1		    :in  std_logic; 
    rd_en_peak_fifo_1			    :out std_logic;
	peak_data_rd_1       		    :in  std_logic_vector(11 downto 0); -- data from the adc_FIFO
    peak_fifo_empty_1               :in  std_logic;                     -- output from adc fifo 

    msc_read_peak_fifo_2		    :in  std_logic; 
    rd_en_peak_fifo_2			    :out std_logic;
	peak_data_rd_2     		        :in  std_logic_vector(11 downto 0); -- data from the adc_FIFO
    peak_fifo_empty_2               :in  std_logic                      -- output from adc fifo 

	);

end entity;

	
architecture LPDDR_FIFO_IF_RTL of LPDDR_FIFO_IF is 
type st_ddr_to_uart_state_type is (ST_IDLE, ST_DATA_NUM, ST_TX_WAIT_RD_START,ST_TX_WORD_BYTE00, ST_TX_WORD_BYTE0, ST_TX_WORD_BYTE1, ST_TX_WORD_BYTE2,ST_LAST_BYTE_CHK);

	
signal s_tx_data_word		:std_logic_vector(31 downto 0);
signal sm_ddr_to_uart_state :st_ddr_to_uart_state_type;
signal adc_data_cnt         :std_logic_vector(19 downto 0);
signal msc_read_cmd_valid   :std_logic;
signal fifo_empty_valid     :std_logic;
--signal tx_done              :std_logic;
--signal msc_ckc_1            :std_logic := '0';
--signal msc_ckc_2            :std_logic := '0';
	
	
begin

--msc_ckc_1 <= msc_read_adc_fifo_1 and adc_fifo_empty_1;
--msc_ckc_2 <= msc_read_adc_fifo_2 and adc_fifo_empty_2;
--
--tx_done <= msc_ckc_1 or msc_ckc_2;

tx_data_to_uart_proc: process (i_clk, i_reset)
begin
    if i_reset = '1' then
    
        rd_en_adc_fifo_1		    <= '0';
        rd_en_adc_fifo_2		    <= '0';
        
        rd_en_peak_fifo_1		    <= '0';
        rd_en_peak_fifo_2		    <= '0';
                                
        o_tx_dv_tlm_s           <= '0';
		adc_data_tx_byte	    <= (others => '0');
        s_tx_data_word          <= (others => '0');
        adc_data_cnt            <= (others => '0');
        sm_ddr_to_uart_state    <= ST_IDLE;
  
    elsif rising_edge (i_clk) then

        case sm_ddr_to_uart_state is

            when ST_IDLE =>
                if msc_read_adc_fifo_1 = '1' and adc_fifo_empty_1 = '0' then
                    rd_en_adc_fifo_1     <= '1';
                    sm_ddr_to_uart_state <= ST_DATA_NUM;
                    
                elsif msc_read_adc_fifo_2 = '1' and adc_fifo_empty_2 = '0' then
                    rd_en_adc_fifo_2       <= '1';
                    sm_ddr_to_uart_state <= ST_DATA_NUM; 
                
                elsif msc_read_peak_fifo_1 = '1' and peak_fifo_empty_1 = '0' then
                    rd_en_peak_fifo_1     <= '1';
                    sm_ddr_to_uart_state  <= ST_DATA_NUM;
                
                elsif msc_read_peak_fifo_2 = '1' and peak_fifo_empty_2 = '0' then
                    rd_en_peak_fifo_2     <= '1';
                    sm_ddr_to_uart_state  <= ST_DATA_NUM;

                else
                    adc_data_cnt            <= (others => '0');
                    sm_ddr_to_uart_state    <= ST_IDLE;
                end if;
            
            when ST_DATA_NUM =>
                    rd_en_adc_fifo_1        <= '0';
                    rd_en_adc_fifo_2        <= '0';  
                    rd_en_peak_fifo_1       <= '0';
                    rd_en_peak_fifo_2       <= '0';  
            
                if msc_read_adc_fifo_1 = '1' then
                    adc_data_cnt         <= adc_data_cnt + '1';
                    s_tx_data_word       <= adc_data_cnt & adc_data_rd_1;
                    sm_ddr_to_uart_state <= ST_TX_WORD_BYTE2;
                    
                elsif msc_read_adc_fifo_2 = '1' then
                    adc_data_cnt         <= adc_data_cnt + '1';
                    s_tx_data_word       <= adc_data_cnt & adc_data_rd_2;
                    sm_ddr_to_uart_state <= ST_TX_WORD_BYTE2; 
                
                elsif msc_read_peak_fifo_1 = '1' then
                    adc_data_cnt          <= adc_data_cnt + '1';
                    s_tx_data_word        <= adc_data_cnt & peak_data_rd_1;
                    sm_ddr_to_uart_state  <= ST_TX_WORD_BYTE2;
                
                elsif msc_read_peak_fifo_2 = '1'  then
                    adc_data_cnt          <= adc_data_cnt + '1';
                    s_tx_data_word        <= adc_data_cnt & peak_data_rd_2;
                    sm_ddr_to_uart_state  <= ST_TX_WORD_BYTE2;

                else
                    adc_data_cnt            <= (others => '0');
                    sm_ddr_to_uart_state    <= ST_IDLE;
                end if;

			when ST_TX_WORD_BYTE2 =>
				if s_tx_fifo_almost_full_tlm = '0' then
					adc_data_tx_byte  <= s_tx_data_word(31 downto 24);
					o_tx_dv_tlm_s    <= '1';
					sm_ddr_to_uart_state    <= ST_TX_WORD_BYTE1;
			    end if;
				
			when ST_TX_WORD_BYTE1 =>
				if s_tx_fifo_almost_full_tlm = '0' then
					adc_data_tx_byte  <= s_tx_data_word(23 downto 16);
					o_tx_dv_tlm_s    <= '1';
					sm_ddr_to_uart_state    <= ST_TX_WORD_BYTE0;
			    end if;
			
			when ST_TX_WORD_BYTE0 =>
				if s_tx_fifo_almost_full_tlm = '0' then
					adc_data_tx_byte  <= s_tx_data_word(15 downto 8);
					o_tx_dv_tlm_s    <= '1';
					sm_ddr_to_uart_state    <= ST_TX_WORD_BYTE00;
			    end if;
                
  			when ST_TX_WORD_BYTE00 =>
				if s_tx_fifo_almost_full_tlm = '0' then
					adc_data_tx_byte  <= s_tx_data_word(7 downto 0);
					o_tx_dv_tlm_s    <= '1';
					sm_ddr_to_uart_state    <= ST_LAST_BYTE_CHK;
			    end if;              
                
			
			when ST_LAST_BYTE_CHK =>
				if s_tx_fifo_almost_full_tlm = '0' then
					o_tx_dv_tlm_s      <= '0';
					sm_ddr_to_uart_state    <= ST_IDLE;
			    end if;   
                
            when others =>
                sm_ddr_to_uart_state <= ST_IDLE;

      end case;
        
    end if;
  end process;
  
--tx_done_flag_to_master_ctrl_proc: process(i_clk, i_reset) 
--begin
   --if i_reset = '1' then
    --tx_done_msc_flag  <= '0';
   --elsif rising_edge (i_clk) then
        --if (tx_done = '1') and (o_tx_dv_tlm_s = '0') then
            --tx_done_msc_flag  <= '1';
        --else
            --tx_done_msc_flag  <= '0';
        --end if;
   --end if;
--end process;
    
end architecture LPDDR_FIFO_IF_RTL;
	