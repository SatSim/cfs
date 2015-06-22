PROC scx_cpu3_cs_dcr22265
;
;**********************************************************************

local logging = %liv (log_procedure)
%liv (log_procedure) = FALSE

#include "ut_statusdefs.h"
#include "ut_cfe_info.h"
#include "cfe_platform_cfg.h"
#include "cfe_evs_events.h"
#include "cfe_es_events.h"
#include "cfe_tbl_events.h"
#include "to_lab_events.h"
#include "cs_platform_cfg.h"
#include "cs_events.h"
#include "cs_tbldefs.h"
#include "cs_msgdefs.h"
#include "tst_cs_events.h"
#include "tst_tbl_events.h"

%liv (log_procedure) = logging

;**********************************************************************
; Define local variables
;**********************************************************************
LOCAL rawcmd
LOCAL stream
LOCAL defTblId, defPktId, resTblId, resPktId
local i,tblIndex,tblName,foundTbl
local CSAppName = "CS"
local ramDir = "RAM:0"
local tblDefTblName = CSAppName & "." & CS_DEF_TABLES_TABLE_NAME
local tblResTblName = CSAppName & "." & CS_RESULTS_TABLES_TABLE_NAME
local appDefTblName = CSAppName & "." & CS_DEF_APP_TABLE_NAME
local appResTblName = CSAppName & "." & CS_RESULTS_APP_TABLE_NAME
local eeDefTblName  = CSAppName & "." & CS_DEF_EEPROM_TABLE_NAME
local eeResTblName  = CSAppName & "." & CS_RESULTS_EEPROM_TABLE_NAME
local memDefTblName = CSAppName & "." & CS_DEF_MEMORY_TABLE_NAME
local memResTblName = CSAppName & "." & CS_RESULTS_MEMORY_TABLE_NAME

defTblId = "0FEC"
resTblId = "0FF0"
defPktId = 4076
resPktId = 4080

;; Other CS Tables variables
LOCAL defAppId, resAppId, defEEId, resEEId, defMemId, resMemId

defAppId = "0FED"
resAppId = "0FF1"
defEEId  = "0FEA"
resEEId  = "0FEE"
defMemId = "0FEB"
resMemId = "0FEF"

write ";*********************************************************************"
write ";  Step 1.0:  Checksum Table Test Setup."
write ";*********************************************************************"
write ";  Step 1.1: Command a Power-on Reset on CPU3."
write ";*********************************************************************"
/SCX_CPU3_ES_POWERONRESET
wait 10

close_data_center
wait 75

cfe_startup CPU3
wait 5

write ";*********************************************************************"
write ";  Step 1.2: Download the default Table Definition Table file in order"
write ";  to use it during cleanup."
write ";********************************************************************"
;; use ftp utilities to get the file
;; CS_DEF_TABLES_TABLE_FILENAME -> full path file spec.
;; Parse the filename configuration parameter for the default table
local tableFileName = CS_DEF_TABLES_TABLE_FILENAME
local slashLoc = %locate(tableFileName,"/")

;; loop until all slashes are found
while (slashLoc <> 0) do
  tableFileName = %substring(tableFileName,slashLoc+1,%length(tableFileName))
  slashLoc = %locate(tableFileName,"/")
enddo

write "==> Default Table Definition Table filename = '",tableFileName,"'"

;; Get the file in order to restore it in the cleanup steps
s ftp_file ("CF:0/apps",tableFileName,"cs_tablesorig.tbl","CPU3","G")
wait 5

write ";**********************************************************************"
write ";  Step 1.3: Display the Housekeeping pages "
write ";**********************************************************************"
page SCX_CPU3_CS_HK
page SCX_CPU3_TST_CS_HK
page SCX_CPU3_CS_TBL_DEF_TABLE
page SCX_CPU3_CS_TBL_RESULTS_TBL
page SCX_CPU3_CS_APP_DEF_TABLE
page SCX_CPU3_CS_EEPROM_DEF_TABLE
page SCX_CPU3_CS_MEM_DEF_TABLE

write ";*********************************************************************"
write ";  Step 1.4: Start the TST_CS_MemTbl application in order to setup   "
write ";  the OS_Memory_Table for the Checksum (CS) application. "
write ";********************************************************************"
ut_setupevents "SCX", "CPU3", "CFE_ES", CFE_ES_START_INF_EID, "INFO", 1
ut_setupevents "SCX", "CPU3", "TST_CS_MEMTBL", 1, "INFO", 2

s load_start_app ("TST_CS_MEMTBL","CPU3","TST_CS_MemTblMain")

;; Wait for app startup events
ut_tlmwait SCX_CPU3_find_event[2].num_found_messages, 1
IF (UT_TW_Status = UT_Success) THEN
  if (SCX_CPU3_find_event[1].num_found_messages = 1) then
    write "<*> Passed - TST_CS_MEMTBL Application Started"
else
    write "<!> Failed - CFE_ES start Event Message for TST_CS_MEMTBL not received."
    write "Event Message count = ",SCX_CPU3_find_event[1].num_found_messages
  endif
else
  write "<!> Failed - TST_CS_MEMTBL Application start Event Message not received."
endif

;; These are the TST_CS HK Packet IDs since this app sends this packet
;; CPU1 is the default
stream = x'0930'

if ("CPU3" = "CPU2") then
  stream = x'0A30'
elseif ("CPU3" = "CPU3") then
  stream = x'0B30'
endif

/SCX_CPU3_TO_ADDPACKET STREAM=stream PKT_SIZE=X'0' PRIORITY=X'0' RELIABILITY=X'0' BUFLIMIT=x'4'
wait 5

write ";*********************************************************************"
write ";  Step 1.5: Start the Checksum (CS) and TST_CS applications.         "
write ";********************************************************************"
s scx_cpu3_cs_start_apps("1.5")
wait 5

;; Verify the Housekeeping Packet is being generated
;; Set the HK packet ID based upon the cpu being used
local hkPktId = "p2A4"

;; Verify the HK Packet is getting generated by waiting for the
;; sequencecount to increment twice
local seqTlmItem = hkPktId & "scnt"
local currSCnt = {seqTlmItem}
local expectedSCnt = currSCnt + 2

ut_tlmwait {seqTlmItem}, {expectedSCnt}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed (9000) - Housekeeping packet is being generated."
else
  write "<!> Failed (9000) - Housekeeping packet sequence count did not increment. Housekeeping packet is not being recieved."
endif

write ";*********************************************************************"
write ";  Step 1.6: Create & load the Tables Definition Table file to be used "
write ";  during this test."
write ";********************************************************************"
;; States are 0=Empty; 1=Enabled; 2=Disabled; 3=Undefined
SCX_CPU3_CS_TBL_DEF_TABLE[0].State = CS_STATE_ENABLED
SCX_CPU3_CS_TBL_DEF_TABLE[0].Name = tblDefTblName
SCX_CPU3_CS_TBL_DEF_TABLE[1].State = CS_STATE_DISABLED
SCX_CPU3_CS_TBL_DEF_TABLE[1].Name = tblResTblName
SCX_CPU3_CS_TBL_DEF_TABLE[2].State = CS_STATE_ENABLED
SCX_CPU3_CS_TBL_DEF_TABLE[2].Name = appDefTblName
SCX_CPU3_CS_TBL_DEF_TABLE[3].State = CS_STATE_DISABLED
SCX_CPU3_CS_TBL_DEF_TABLE[3].Name = appResTblName
SCX_CPU3_CS_TBL_DEF_TABLE[4].State = CS_STATE_ENABLED
SCX_CPU3_CS_TBL_DEF_TABLE[4].Name = eeDefTblName
SCX_CPU3_CS_TBL_DEF_TABLE[5].State = CS_STATE_DISABLED
SCX_CPU3_CS_TBL_DEF_TABLE[5].Name = eeResTblName
SCX_CPU3_CS_TBL_DEF_TABLE[6].State = CS_STATE_ENABLED
SCX_CPU3_CS_TBL_DEF_TABLE[6].Name = memDefTblName
SCX_CPU3_CS_TBL_DEF_TABLE[7].State = CS_STATE_DISABLED
SCX_CPU3_CS_TBL_DEF_TABLE[7].Name = memResTblName
SCX_CPU3_CS_TBL_DEF_TABLE[8].State = CS_STATE_DISABLED
SCX_CPU3_CS_TBL_DEF_TABLE[8].Name = "TST_CS.unknownTbl"

;; Need to clear out the other slots
for i = 9 to CS_MAX_NUM_TABLES_TABLE_ENTRIES-1 DO
  SCX_CPU3_CS_TBL_DEF_TABLE[i].State = CS_STATE_EMPTY
  SCX_CPU3_CS_TBL_DEF_TABLE[i].Name = ""
enddo

local lastEntry = CS_MAX_NUM_TABLES_TABLE_ENTRIES - 1
local endmnemonic = "SCX_CPU3_CS_TBL_DEF_TABLE[" & lastEntry & "].Name"

;; Create the Table Load file
s create_tbl_file_from_cvt ("CPU3",defTblId,"Table Definition Table Load 1","tbl_def_tbl_ld_1",tblDefTblName,"SCX_CPU3_CS_TBL_DEF_TABLE[0].State",endmnemonic)

wait 5

;; Load the Tables file created above
s load_table("tbl_def_tbl_ld_1","CPU3")
wait 5

ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_VALIDATION_INF_EID,"INFO", 1
ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_UPDATE_SUCCESS_INF_EID,"INFO", 2

local cmdCtr = SCX_CPU3_TBL_CMDPC + 1

/SCX_CPU3_TBL_VALIDATE INACTIVE VTABLENAME=tblDefTblName

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Tables Definition Table validate command sent."
else
  write "<!> Failed - Tables Definition Table validation failed."
endif

ut_tlmwait SCX_CPU3_find_event[1].num_found_messages, 1
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Event message ",SCX_CPU3_find_event[1].eventid, " received"
else
  write "<!> Failed - Event message ",SCX_CPU3_evs_eventid," received. Expected Event message ",CFE_TBL_VALIDATION_INF_EID, "."
endif

cmdCtr = SCX_CPU3_TBL_CMDPC + 1

/SCX_CPU3_TBL_ACTIVATE ATableName=tblDefTblName

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Activate Tables Definition Table command sent properly."
else
  write "<!> Failed - Activate Tables Definition Table command."
endif

ut_tlmwait SCX_CPU3_find_event[2].num_found_messages, 1
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Tables Definition Table Updated successfully."
  Write "<*> Passed - Event Msg ",SCX_CPU3_find_event[2].eventid," Found!"
else
  write "<!> Failed - Tables Definition Table update failed."
  Write "<!> Failed - Event Message not received for activate command."
endif

wait 5

write ";*********************************************************************"
write ";  Step 1.7: Enable DEBUG Event Messages "
write ";*********************************************************************"
local cmdCtr = SCX_CPU3_EVS_CMDPC + 2

;; Enable DEBUG events for the CS and CFE_TBL applications ONLY
/SCX_CPU3_EVS_EnaAppEVTType Application=CSAppName DEBUG
wait 2
/SCX_CPU3_EVS_EnaAppEVTType Application="CFE_TBL" DEBUG

ut_tlmwait SCX_CPU3_EVS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Enable Debug events command sent properly."
else
  write "<!> Failed - Enable Debug events command."
endif

write ";*********************************************************************"
write ";  Step 1.8: Dump the Tables Definition Table."
write ";*********************************************************************"
s get_tbl_to_cvt (ramDir,tblDefTblName,"A","cpu3_deftbl1_8","CPU3",defTblId)
wait 5

write ";*********************************************************************"
write ";  Step 1.9: Dump the Other Definition Tables."
write ";*********************************************************************"
s get_tbl_to_cvt (ramDir,appDefTblName,"A","cpu3_appdeftbl1_9","CPU3",defAppId)
wait 5
s get_tbl_to_cvt (ramDir,eeDefTblName,"A","cpu3_eedeftbl1_9","CPU3",defEEId)
wait 5
s get_tbl_to_cvt (ramDir,memDefTblName,"A","cpu3_memdeftbl1_9","CPU3",defMemId)
wait 5

write ";*********************************************************************"
write ";  Step 2.0: Valid Command and Functionality Test."
write ";*********************************************************************"
write ";  Step 2.1: Send the Enable Checksum command."
write ";*********************************************************************"
ut_setupevents "SCX", "CPU3", {CSAppName}, CS_ENABLE_ALL_INF_EID, "INFO", 1

cmdCtr = SCX_CPU3_CS_CMDPC + 1
;; Send the Enable All Command
/SCX_CPU3_CS_EnableAll

ut_tlmwait SCX_CPU3_CS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed (1003;8000) - CS EnableALL command sent properly."
else
  write "<!> Failed (1003;8000) - CS EnableALL command did not increment CMDPC."
endif

;; Check for the event message
ut_tlmwait SCX_CPU3_find_event[1].num_found_messages, 1
if (UT_TW_Status = UT_Success) then
  write "<*> Passed (1003;8000) - Expected Event Msg ",CS_ENABLE_ALL_INF_EID," rcv'd."
else
  write "<!> Failed (1003;8000) - Event message ", SCX_CPU3_evs_eventid," rcv'd. Expected Event Msg ",CS_ENABLE_ALL_INF_EID,"."
endif

;; Send the Disable OS Checksumming Command
/SCX_CPU3_CS_DisableOS
wait 1

;; Send the Disable CFE Core Checksumming Command
/SCX_CPU3_CS_DisableCFECore
wait 1

;; Disable Eeprom Checksumming if it is enabled
/SCX_CPU3_CS_DisableEeprom
wait 1

;; Disable User-defined Memory Checksumming if it is enabled
/SCX_CPU3_CS_DisableMemory
wait 1

;; Disable Application Checksumming if it is enabled
/SCX_CPU3_CS_DisableApps

wait 5

write ";*********************************************************************"
write ";  Step 2.2: Send the Enable Tables Checksum command."
write ";*********************************************************************"
ut_setupevents "SCX", "CPU3", {CSAppName}, CS_ENABLE_TABLES_INF_EID, "INFO", 1

cmdCtr = SCX_CPU3_CS_CMDPC + 1

;; Send the Enable Tables Command
/SCX_CPU3_CS_EnableTables

ut_tlmwait SCX_CPU3_CS_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed (1003;5001) - CS EnableTables command sent properly."
else
  write "<!> Failed (1003;5001) - CS EnableTables command did not increment CMDPC."
endif

;; Check for the event message
ut_tlmwait SCX_CPU3_find_event[1].num_found_messages, 1
if (UT_TW_Status = UT_Success) then
  write "<*> Passed (1003;5001) - Expected Event Msg ",CS_ENABLE_TABLES_INF_EID," rcv'd."
else
  write "<!> Failed (1003;5001) - Event message ", SCX_CPU3_evs_eventid," rcv'd. Expected Event Msg ",CS_ENABLE_TABLES_INF_EID,"."
endif

wait 5

write ";*********************************************************************"
write ";  Step 2.3: Dump the Table Results Table."
write ";*********************************************************************"
cmdCtr = SCX_CPU3_TBL_CMDPC + 1

s get_tbl_to_cvt (ramDir,tblResTblName,"A","cpu3_tblrestbl2_3","CPU3",resTblId)
wait 5

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed (5008) - Dump of Table Results Table successful."
else
  write "<!> Failed (5008) - Dump of Table Results Table did not increment TBL_CMDPC."
endif

write ";*********************************************************************"
write ";  Step 2.4: Verify that Tables are being checksummed."
write ";*********************************************************************"
;; In order to do this, I must constantly dump the Results table and monitor
;; the Baseline CRC values
local keepDumpingResults=TRUE
local dumpFileName = "cpu3_tblrestbl2_4"

while (keepDumpingResults = TRUE) do
  s get_tbl_to_cvt (ramDir,tblResTblName,"A",dumpFileName,"CPU3",resTblId)
  wait 3

  ;; Loop for each valid entry in the results table
  for i = 0 to CS_MAX_NUM_TABLES_TABLE_ENTRIES-1 DO
    ;; If the CRC has been computed AND the CRC is not zero -> Stop
    if (p@SCX_CPU3_CS_TBL_RESULT_TABLE[i].ComputedYet = "TRUE") AND ;;
       (SCX_CPU3_CS_TBL_RESULT_TABLE[i].BaselineCRC <> 0) AND ;;
       (keepDumpingResults = TRUE) then
      keepDumpingResults = FALSE
    endif
  enddo
enddo

;; Will not get here if checksumming is not being calculated
write "<*> Passed (5000) - Table Checksumming is occurring."

write ";*********************************************************************"
write ";  Step 2.5: Load the application definition table. Verify that the "
write ";  CRC is recomputed after the load has been activated. "
write ";*********************************************************************"
;; NOTE: This step assumes that the CRC has been computed already
;; Save the CRC for the table being loaded below
local appDefCRC=0

;; Loop for the App Definition Table entry in the results table
for i = 0 to CS_MAX_NUM_TABLES_TABLE_ENTRIES-1 DO
  if (SCX_CPU3_CS_TBL_RESULT_TABLE[i].Name = appDefTblName) then
    appDefCRC = SCX_CPU3_CS_TBL_RESULT_TABLE[i].BaselineCRC
    break
  endif
enddo

; Create the table load file
s scx_cpu3_cs_adt1
wait 5

cmdCtr = SCX_CPU3_TBL_CMDPC + 1

start load_table ("app_def_tbl_ld_1", "CPU3")

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Load command executed successfully."
else
  write "<!> Failed - Load command did not execute successfully."
endif

ut_tlmwait SCX_CPU3_find_event[1].num_found_messages, 1
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Event message ",SCX_CPU3_find_event[1].eventid, " received"
else
  write "<!> Failed - Event message ",SCX_CPU3_evs_eventid," received. Expected Event message ",CFE_TBL_FILE_LOADED_INF_EID, "."
endif

;; Validate the load
ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_VAL_REQ_MADE_INF_EID, "DEBUG", 1
ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_VALIDATION_INF_EID, "INFO", 2

cmdCtr = SCX_CPU3_TBL_CMDPC + 1

/SCX_CPU3_TBL_VALIDATE INACTIVE VTABLENAME=appDefTblName

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Table Definition Table validate command sent."
  if (SCX_CPU3_find_event[1].num_found_messages = 1) then
    write "<*> Passed - Event Msg ",SCX_CPU3_find_event[1].eventid," Found!"
  else
    write "<!> Failed - Event Message not received for Validate command."
  endif
else
  write "<!> Failed - Table Definition Table validation failed."
endif

;; Check for the event message
ut_tlmwait SCX_CPU3_find_event[2].num_found_messages, 1

;; Activate the load
ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_LOAD_PEND_REQ_INF_EID, "DEBUG", 1

cmdCtr = SCX_CPU3_TBL_CMDPC + 1

/SCX_CPU3_TBL_ACTIVATE ATableName=appDefTblName

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Activate command sent properly."
else
  write "<!> Failed - Activate command not sent properly."
endif

;**** If the event was generated, the Activate occurred!!!
ut_tlmwait SCX_CPU3_find_event[1].num_found_messages, 1
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Event message ",SCX_CPU3_find_event[1].eventid, " received"
else
  write "<!> Failed - Event message ",SCX_CPU3_evs_eventid," received. Expected Event message ",CFE_TBL_LOAD_PEND_REQ_INF_EID, "."
endif 

write ";*********************************************************************"
write ";  Step 2.6: Load the EEPROM definition table. Verify that the "
write ";  CRC is recomputed after the load has been activated. "
write ";*********************************************************************"
;; Save the CRC for the table being loaded below
local eeDefCRC=0

;; Loop for the EEPROM Definition Table entry in the results table
for i = 0 to CS_MAX_NUM_TABLES_TABLE_ENTRIES-1 DO
  if (SCX_CPU3_CS_TBL_RESULT_TABLE[i].Name = eeDefTblName) then
    eeDefCRC = SCX_CPU3_CS_TBL_RESULT_TABLE[i].BaselineCRC
    break
  endif
enddo

;; Create the table load file
s scx_cpu3_cs_edt1
wait 5

cmdCtr = SCX_CPU3_TBL_CMDPC + 1

start load_table ("eeprom_def_ld_1", "CPU3")

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Load command executed successfully."
else
  write "<!> Failed - Load command did not execute successfully."
endif

ut_tlmwait SCX_CPU3_find_event[1].num_found_messages, 1
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Event message ",SCX_CPU3_find_event[1].eventid, " received"
else
  write "<!> Failed - Event message ",SCX_CPU3_evs_eventid," received. Expected Event message ",CFE_TBL_FILE_LOADED_INF_EID, "."
endif

;; Validate the load
ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_VAL_REQ_MADE_INF_EID, "DEBUG", 1
ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_VALIDATION_INF_EID, "INFO", 2

cmdCtr = SCX_CPU3_TBL_CMDPC + 1

/SCX_CPU3_TBL_VALIDATE INACTIVE VTABLENAME=eeDefTblName

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Table Definition Table validate command sent."
  if (SCX_CPU3_find_event[1].num_found_messages = 1) then
    write "<*> Passed - Event Msg ",SCX_CPU3_find_event[1].eventid," Found!"
  else
    write "<!> Failed - Event Message not received for Validate command."
  endif
else
  write "<!> Failed - Table Definition Table validation failed."
endif

;; Check for the event message
ut_tlmwait SCX_CPU3_find_event[2].num_found_messages, 1

;; Activate the load
ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_LOAD_PEND_REQ_INF_EID, "DEBUG", 1

cmdCtr = SCX_CPU3_TBL_CMDPC + 1

/SCX_CPU3_TBL_ACTIVATE ATableName=eeDefTblName

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Activate command sent properly."
else
  write "<!> Failed - Activate command not sent properly."
endif

;**** If the event was generated, the Activate occurred!!!
ut_tlmwait SCX_CPU3_find_event[1].num_found_messages, 1
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Event message ",SCX_CPU3_find_event[1].eventid, " received"
else
  write "<!> Failed - Event message ",SCX_CPU3_evs_eventid," received. Expected Event message ",CFE_TBL_LOAD_PEND_REQ_INF_EID, "."
endif 

write ";*********************************************************************"
write ";  Step 2.7: Load Memory Definition table. Verify that the "
write ";  CRC is recomputed after the load has been activated. "
write ";*********************************************************************"
;; Save the CRC for the table being loaded below
local memDefCRC=0

;; Loop for the Memory Definition Table entry in the results table
for i = 0 to CS_MAX_NUM_TABLES_TABLE_ENTRIES-1 DO
  if (SCX_CPU3_CS_TBL_RESULT_TABLE[i].Name = memDefTblName) then
    memDefCRC = SCX_CPU3_CS_TBL_RESULT_TABLE[i].BaselineCRC
    break
  endif
enddo

;; Create the table load file
s scx_cpu3_cs_mdt1
wait 5

cmdCtr = SCX_CPU3_TBL_CMDPC + 1

start load_table ("usrmem_def_ld_1", "CPU3")

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Load command executed successfully."
else
  write "<!> Failed - Load command did not execute successfully."
endif

ut_tlmwait SCX_CPU3_find_event[1].num_found_messages, 1
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Event message ",SCX_CPU3_find_event[1].eventid, " received"
else
  write "<!> Failed - Event message ",SCX_CPU3_evs_eventid," received. Expected Event message ",CFE_TBL_FILE_LOADED_INF_EID, "."
endif

;; Validate the load
ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_VAL_REQ_MADE_INF_EID, "DEBUG", 1
ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_VALIDATION_INF_EID, "INFO", 2

cmdCtr = SCX_CPU3_TBL_CMDPC + 1

/SCX_CPU3_TBL_VALIDATE INACTIVE VTABLENAME=memDefTblName

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Table Definition Table validate command sent."
  if (SCX_CPU3_find_event[1].num_found_messages = 1) then
    write "<*> Passed - Event Msg ",SCX_CPU3_find_event[1].eventid," Found!"
  else
    write "<!> Failed - Event Message not received for Validate command."
  endif
else
  write "<!> Failed - Table Definition Table validation failed."
endif

;; Check for the event message
ut_tlmwait SCX_CPU3_find_event[2].num_found_messages, 1

;; Activate the load
ut_setupevents "SCX","CPU3","CFE_TBL",CFE_TBL_LOAD_PEND_REQ_INF_EID, "DEBUG", 1

cmdCtr = SCX_CPU3_TBL_CMDPC + 1

/SCX_CPU3_TBL_ACTIVATE ATableName=memDefTblName

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Activate command sent properly."
else
  write "<!> Failed - Activate command not sent properly."
endif

;**** If the event was generated, the Activate occurred!!!
ut_tlmwait SCX_CPU3_find_event[1].num_found_messages, 1
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Event message ",SCX_CPU3_find_event[1].eventid, " received"
else
  write "<!> Failed - Event message ",SCX_CPU3_evs_eventid," received. Expected Event message ",CFE_TBL_LOAD_PEND_REQ_INF_EID, "."
endif 

;; Wait for the CRC to get recomputed
wait 30

write ";*********************************************************************"
write ";  Step 2.8: Dump the results table and verify that the CRC for the "
write ";  table used in the above steps has been recomputed. "
write ";*********************************************************************"
cmdCtr = SCX_CPU3_TBL_CMDPC + 1

s get_tbl_to_cvt (ramDir,tblResTblName,"A","cs_tblrestbl2_8","CPU3",resTblId)
wait 5

ut_tlmwait SCX_CPU3_TBL_CMDPC, {cmdCtr}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - Dump of Table Results Table successful."
else
  write "<!> Failed - Dump of Table Results Table did not increment TBL_CMDPC."
endif

wait 10

;; Verify that the table's CRC has been recalculated
for i = 0 to CS_MAX_NUM_TABLES_TABLE_ENTRIES - 1 DO
  if (SCX_CPU3_CS_TBL_RESULT_TABLE[i].Name = appDefTblName) then
    if (SCX_CPU3_CS_TBL_RESULT_TABLE[i].BaselineCRC <> appDefCRC) then
      write "<*> Passed - ",appDefTblName, "'s CRC has been recomputed on update."
    else
      write "<!> Failed - ",appDefTblName,"'s CRC was not recomputed on update."
    endif
  endif

  if (SCX_CPU3_CS_TBL_RESULT_TABLE[i].Name = eeDefTblName) then
    if (SCX_CPU3_CS_TBL_RESULT_TABLE[i].BaselineCRC <> eeDefCRC) then
      write "<*> Passed - ",eeDefTblName, "'s CRC has been recomputed on update."
    else
      write "<!> Failed - ",eeDefTblName,"'s CRC was not recomputed on update."
    endif
  endif

  if (SCX_CPU3_CS_TBL_RESULT_TABLE[i].Name = memDefTblName) then
    if (SCX_CPU3_CS_TBL_RESULT_TABLE[i].BaselineCRC <> eeDefCRC) then
      write "<*> Passed - ",memDefTblName, "'s CRC has been recomputed on update."
    else
      write "<!> Failed - ",memDefTblName,"'s CRC was not recomputed on update."
    endif
  endif
enddo

wait 5

write ";*********************************************************************"
write ";  Step 3.0: Clean-up. "
write ";*********************************************************************"
write ";  Step 3.1: Upload the default Application Code Segment Definition   "
write ";  table downloaded in step 1.1. "
write ";*********************************************************************"
s ftp_file ("CF:0/apps","cs_tablestbl.tblORIG",tableFileName,"CPU3","P")

write ";*********************************************************************"
write ";  Step 3.2: Send the Power-On Reset command. "
write ";*********************************************************************"
/SCX_CPU3_ES_POWERONRESET
wait 10

close_data_center
wait 75

cfe_startup CPU3
wait 5

write ";*********************************************************************"
write ";  End procedure SCX_CPU3_cs_dcr22265"
write ";*********************************************************************"
ENDPROC
