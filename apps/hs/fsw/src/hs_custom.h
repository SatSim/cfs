/*************************************************************************
** File:
**   $Id: hs_custom.h 1.2 2015/03/03 12:16:02EST sstrege Exp  $
**
**   Copyright © 2007-2014 United States Government as represented by the 
**   Administrator of the National Aeronautics and Space Administration. 
**   All Other Rights Reserved.  
**
**   This software was created at NASA's Goddard Space Flight Center.
**   This software is governed by the NASA Open Source Agreement and may be 
**   used, distributed and modified only pursuant to the terms of that 
**   agreement.
**
** Purpose: 
**   Specification for the CFS Health and Safety (HS) mission specific
**   custom function interface
**
**   $Log: hs_custom.h  $
**   Revision 1.2 2015/03/03 12:16:02EST sstrege 
**   Added copyright information
**   Revision 1.1 2011/10/13 18:49:05EDT aschoeni 
**   Initial revision
**   Member added to project c:/MKSDATA/MKS-REPOSITORY/CFS-REPOSITORY/hs/fsw/src/project.pj
**   Revision 1.2 2010/09/29 18:27:42EDT aschoeni 
**   Added Utilization Monitoring
**   Revision 1.1 2010/09/13 16:34:38EDT aschoeni 
**   Initial revision
**   Member added to project c:/MKSDATA/MKS-REPOSITORY/CFS-REPOSITORY/hs/fsw/src/project.pj
**   Revision 1.1 2010/07/19 11:49:55EDT aschoeni 
**   Initial revision
**   Member added to project c:/MKSDATA/MKS-REPOSITORY/MMS-REPOSITORY/dev/eeprom-fsw/apps/hs/fsw/src/project.pj
**
**************************************************************************/
#ifndef _hs_custom_
#define _hs_custom_

/*************************************************************************
** Includes
*************************************************************************/
#include "cfe.h"

/*************************************************************************
** Exported Functions
*************************************************************************/

/************************************************************************/
/** \brief Initialize things needed for CPU Monitoring
**
**  \par Description
**       This function is intended to set up everything necessary for
**       CPU Utilization Monitoring at application startup. Currently,
**       this initializes the Idle Task, spawning the task itself,
**       and creating a 1Hz sync callback to mark the idle time.
**       It is called at the end of #HS_AppInit .
**       It may be updated to include other initializations, or 
**       modifications to already set parameters.
**
**  \par Assumptions, External Events, and Notes:
**       CFE_SUCCESS will be returned if all creation was performed
**       properly.
**       
**  \returns
**  \retcode #CFE_SUCCESS  \retdesc \copydoc CFE_SUCCESS \endcode
**  \retstmt Return codes from #CFE_ES_CreateChildTask \endcode
**  \retstmt Return codes from #CFE_TIME_RegisterSynchCallback  \endcode
**  \endreturns
**
*************************************************************************/
int32 HS_CustomInit(void);

/************************************************************************/
/** \brief Clean up the functionality used for Utilization Monitoring
**
**  \par Description
**       This function is intended to clean up everything necessary for
**       CPU Utilization Monitoring at application termination. Currently,
**       this terminates the Idle Task, deleting the task itself,
**       and uncreating the 1Hz sync callback that marks the idle time.
**       It is called at the end of #HS_AppMain if HS is exiting cleanly.
**
**  \par Assumptions, External Events, and Notes:
**       Any resources that will not be cleaned up automatically be CFE
**       need to be cleaned up in this function.
**
*************************************************************************/
void HS_CustomCleanup(void);

/************************************************************************/
/** \brief Stub function for Utilization Monitoring
**
**  \par Description
**       This function is used as a passthrough to call #HS_MonitorUtilization
**       but can be modified to monitor utilization differently.
**       It is called during #HS_ProcessMain every HS cycle.
**
**  \par Assumptions, External Events, and Notes:
**       None
**
*************************************************************************/
void HS_CustomMonitorUtilization(void);

/************************************************************************/
/** \brief Stub function for Getting the Current Cycle Utilization
**
**  \par Description
**       This function is used to inform the Monitor Utilization function
**       of the current cycle utilization.
**       It is called during #HS_MonitorUtilization and should return a
**       value between 0 and #HS_UTIL_PER_INTERVAL_TOTAL.
**
**  \par Assumptions, External Events, and Notes:
**       None
**
*************************************************************************/
int32 HS_CustomGetUtil(void);

/************************************************************************/
/** \brief Process Custom Commands
**
**  \par Description
**       This function allows for hs_custom.c to define custom commands.
**       It will be called for any command code not already allocated
**       to a Health and Safety command. If a custom command is found,
**       then it is responsible for incrementing the command processed
**       or command error counter as appropriate.
**
**  \par Assumptions, External Events, and Notes:
**       If a command is found, this function MUST return #CFE_SUCCESS,
**       otherwise is must not return #CFE_SUCCESS
**
*************************************************************************/
int32 HS_CustomCommands(CFE_SB_MsgPtr_t MessagePtr);


#endif /* _hs_custom_ */

/************************/
/*  End of File Comment */
/************************/

