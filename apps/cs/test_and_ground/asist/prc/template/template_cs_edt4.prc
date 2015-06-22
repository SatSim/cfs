PROC $sc_$cpu_cs_edt4
;*******************************************************************************
;  Test Name:  cs_edt4
;  Test Level: Build Verification
;  Test Type:  Functional
;
;  Test Description
;	The purpose of this procedure is to generate an EEPROM Definition Table
;	for the Checksum Application that contains all empty entries.
;
;  Requirements Tested:
;	None
;
;  Prerequisite Conditions
;	None
;
;  Assumptions and Constraints
;	None.
;
;  Change History
;
;	Date		   Name		Description
;	07/18/11	Walt Moleski	Initial release.
;
;  Arguments
;	None.
;
;  Procedures Called
;	Name			Description
;      create_tbl_file_from_cvt Procedure that creates a load file from
;                               the specified arguments and cvt
;
;  Expected Test Results and Analysis
;
;**********************************************************************

local logging = %liv (log_procedure)
%liv (log_procedure) = FALSE

#include "cs_platform_cfg.h"
#include "cs_tbldefs.h"
#include "cs_msgdefs.h"

%liv (log_procedure) = logging

;**********************************************************************
; Define local variables
;**********************************************************************
LOCAL defTblId, defPktId
local CSAppName = "CS"
local ramDir = "RAM:0"
local eeDefTblName = CSAppName & "." & CS_DEF_EEPROM_TABLE_NAME

;;; Set the pkt and app IDs for the tables based upon the cpu being used
;; CPU1 is the default
defTblId = "0FAC"
defPktId = 4012

if ("$CPU" = "CPU2") then
  defTblId = "0FCA"
  defPktId = 4042
elseif ("$CPU" = "CPU3") then
  defTblId = "0FEA"
  defPktId = 4074
endif

write ";*********************************************************************"
write ";  Define the Application Definition Table "
write ";********************************************************************"
;; States are 0=CS_STATE_EMPTY; 1=CS_STATE_ENABLED; 2=CS_STATE_DISABLED;
;;            3=CS_STATE_UNDEFINED
local maxEntry = CS_MAX_NUM_EEPROM_TABLE_ENTRIES - 1

;; Clear out the rest of the table
for i = 0 to maxEntry do
  $SC_$CPU_CS_EEPROM_DEF_TABLE[i].NumBytes = 0
  $SC_$CPU_CS_EEPROM_DEF_TABLE[i].State = CS_STATE_EMPTY
  $SC_$CPU_CS_EEPROM_DEF_TABLE[i].StartAddr = 0
enddo

local endmnemonic = "$SC_$CPU_CS_EEPROM_DEF_TABLE[" & maxEntry & "].NumBytes"

;; Create the Table Load file that should fail validation
s create_tbl_file_from_cvt ("$CPU",defTblId,"EEPROM Definition Table Invalid Load","eepromdefemptytable",eeDefTblName,"$SC_$CPU_CS_EEPROM_DEF_TABLE[0].State",endmnemonic)

write ";*********************************************************************"
write ";  End procedure $SC_$CPU_cs_edt4                              "
write ";*********************************************************************"
ENDPROC
