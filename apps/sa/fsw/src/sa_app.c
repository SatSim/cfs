/*******************************************************************************
** File: sa_app.c
**
** Purpose:
**   This file contains the source code for the SA App.
**
*******************************************************************************/

/*
**   Include Files:
*/

#include "sa_app.h"
#include "sa_app_perfids.h"
#include "sa_app_msgids.h"
#include "sa_app_msg.h"
#include "sa_app_events.h"
#include "sa_app_version.h"

/*
** global data
*/

sample_hk_tlm_t    SAMPLE_HkTelemetryPkt;
CFE_SB_PipeId_t    SAMPLE_CommandPipe;
CFE_SB_MsgPtr_t    SAMPLEMsgPtr;

static CFE_EVS_BinFilter_t  SAMPLE_EventFilters[] =
       {  /* Event ID    mask */
          {SAMPLE_STARTUP_INF_EID,       0x0000},
          {SAMPLE_COMMAND_ERR_EID,       0x0000},
          {SAMPLE_COMMANDNOP_INF_EID,    0x0000},
          {SAMPLE_COMMANDRST_INF_EID,    0x0000},
       };

/** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* SA_AppMain() -- Application entry point and main process loop          */
/*                                                                            */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * *  * * * * **/
void SA_AppMain( void )
{
    int32  status;
    uint32 RunStatus = CFE_ES_APP_RUN;

    CFE_ES_PerfLogEntry(SAMPLE_APP_PERF_ID);

    SA_AppInit();

    //test to see if it works
    CFE_ES_WriteToSysLog("Hello World!");

    /*
    ** SAMPLE Runloop
    */
    while (CFE_ES_RunLoop(&RunStatus) == TRUE)
    {
        CFE_ES_PerfLogExit(SAMPLE_APP_PERF_ID);

        /* Pend on receipt of command packet -- timeout set to 500 millisecs */
        status = CFE_SB_RcvMsg(&SAMPLEMsgPtr, SAMPLE_CommandPipe, 500);
        
        CFE_ES_PerfLogEntry(SAMPLE_APP_PERF_ID);

        if (status == CFE_SUCCESS)
        {
            SA_ProcessCommandPacket();
        }

    }

    CFE_ES_ExitApp(RunStatus);

} /* End of SA_AppMain() */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  */
/*                                                                            */
/* SA_AppInit() --  initialization                                       */
/*                                                                            */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/
void SA_AppInit(void)
{
    /*
    ** Register the app with Executive services
    */
    CFE_ES_RegisterApp() ;

    /*
    ** Register the events
    */ 
    CFE_EVS_Register(SAMPLE_EventFilters,
                     sizeof(SAMPLE_EventFilters)/sizeof(CFE_EVS_BinFilter_t),
                     CFE_EVS_BINARY_FILTER);

    /*
    ** Create the Software Bus command pipe and subscribe to housekeeping
    **  messages
    */
    CFE_SB_CreatePipe(&SAMPLE_CommandPipe, SAMPLE_PIPE_DEPTH,"SAMPLE_CMD_PIPE");
    CFE_SB_Subscribe(SAMPLE_APP_CMD_MID, SAMPLE_CommandPipe);
    CFE_SB_Subscribe(SAMPLE_APP_SEND_HK_MID, SAMPLE_CommandPipe);

    SA_ResetCounters();

    CFE_SB_InitMsg(&SAMPLE_HkTelemetryPkt,
                   SAMPLE_APP_HK_TLM_MID,
                   SAMPLE_APP_HK_TLM_LNGTH, TRUE);

    CFE_EVS_SendEvent (SAMPLE_STARTUP_INF_EID, CFE_EVS_INFORMATION,
               "SAMPLE App Initialized. Version %d.%d.%d.%d",
                SAMPLE_APP_MAJOR_VERSION,
                SAMPLE_APP_MINOR_VERSION, 
                SAMPLE_APP_REVISION, 
                SAMPLE_APP_MISSION_REV);
				
} /* End of SA_AppInit() */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/
/*  Name:  SA_ProcessCommandPacket                                            */
/*                                                                            */
/*  Purpose:                                                                  */
/*     This routine will process any packet that is received on the SA        */
/*     command pipe.                                                          */
/*                                                                            */
/* * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * *  * *  * * * * */
void SA_ProcessCommandPacket(void)
{
    CFE_SB_MsgId_t  MsgId;

    MsgId = CFE_SB_GetMsgId(SAMPLEMsgPtr);

    switch (MsgId)
    {
        case SAMPLE_APP_CMD_MID:
            SA_ProcessGroundCommand();
            break;

        case SAMPLE_APP_SEND_HK_MID:
            SA_ReportHousekeeping();
            break;

        default:
            SAMPLE_HkTelemetryPkt.sample_command_error_count++;
            CFE_EVS_SendEvent(SAMPLE_COMMAND_ERR_EID,CFE_EVS_ERROR,
			"SAMPLE: invalid command packet,MID = 0x%x", MsgId);
            break;
    }

    return;

} /* End SA_ProcessCommandPacket */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/
/*                                                                            */
/* SA_ProcessGroundCommand() -- SA ground commands                            */
/*                                                                            */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/

void SA_ProcessGroundCommand(void)
{
    uint16 CommandCode;

    CommandCode = CFE_SB_GetCmdCode(SAMPLEMsgPtr);

    /* Process "known" SAMPLE app ground commands */
    switch (CommandCode)
    {
        case SAMPLE_APP_NOOP_CC:
            SAMPLE_HkTelemetryPkt.sample_command_count++;
            CFE_EVS_SendEvent(SAMPLE_COMMANDNOP_INF_EID,CFE_EVS_INFORMATION,
			"SAMPLE: NOOP command");
            break;

        case SAMPLE_APP_RESET_COUNTERS_CC:
            SA_ResetCounters();
            break;

        /* default case already found during FC vs length test */
        default:
            break;
    }
    return;

} /* End of SA_ProcessGroundCommand() */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/
/*  Name:  SA_ReportHousekeeping                                              */
/*                                                                            */
/*  Purpose:                                                                  */
/*         This function is triggered in response to a task telemetry request */
/*         from the housekeeping task. This function will gather the Apps     */
/*         telemetry, packetize it and send it to the housekeeping task via   */
/*         the software bus                                                   */
/* * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * *  * *  * * * * */
void SA_ReportHousekeeping(void)
{
    CFE_SB_TimeStampMsg((CFE_SB_Msg_t *) &SAMPLE_HkTelemetryPkt);
    CFE_SB_SendMsg((CFE_SB_Msg_t *) &SAMPLE_HkTelemetryPkt);
    return;

} /* End of SA_ReportHousekeeping() */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/
/*  Name:  SA_ResetCounters                                               */
/*                                                                            */
/*  Purpose:                                                                  */
/*         This function resets all the global counter variables that are     */
/*         part of the task telemetry.                                        */
/*                                                                            */
/* * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * *  * *  * * * * */
void SA_ResetCounters(void)
{
    /* Status of commands processed by the SAMPLE App */
    SAMPLE_HkTelemetryPkt.sample_command_count       = 0;
    SAMPLE_HkTelemetryPkt.sample_command_error_count = 0;

    CFE_EVS_SendEvent(SAMPLE_COMMANDRST_INF_EID, CFE_EVS_INFORMATION,
		"SAMPLE: RESET command");
    return;

} /* End of SA_ResetCounters() */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/
/*                                                                            */
/* SA_VerifyCmdLength() -- Verify command packet length                       */
/*                                                                            */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/
boolean SA_VerifyCmdLength(CFE_SB_MsgPtr_t msg, uint16 ExpectedLength)
{     
    boolean result = TRUE;

    uint16 ActualLength = CFE_SB_GetTotalMsgLength(msg);

    /*
    ** Verify the command packet length.
    */
    if (ExpectedLength != ActualLength)
    {
        CFE_SB_MsgId_t MessageID   = CFE_SB_GetMsgId(msg);
        uint16         CommandCode = CFE_SB_GetCmdCode(msg);

        CFE_EVS_SendEvent(SAMPLE_LEN_ERR_EID, CFE_EVS_ERROR,
           "Invalid msg length: ID = 0x%X,  CC = %d, Len = %d, Expected = %d",
              MessageID, CommandCode, ActualLength, ExpectedLength);
        result = FALSE;
        SAMPLE_HkTelemetryPkt.sample_command_error_count++;
    }

    return(result);

} /* End of SA_VerifyCmdLength() */

