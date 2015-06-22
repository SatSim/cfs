/*************************************************************************
** File:
**   $Id: hs_cmds.h 1.4 2015/03/03 12:16:20EST sstrege Exp  $
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
**   Specification for the CFS Health and Safety (HS) routines that
**   handle command processing
**
** Notes:
**
**   $Log: hs_cmds.h  $
**   Revision 1.4 2015/03/03 12:16:20EST sstrege 
**   Added copyright information
**   Revision 1.3 2011/10/13 18:45:25EDT aschoeni 
**   Updated for hs utilization calibration functions
**   Revision 1.2 2009/05/04 17:44:32EDT aschoeni 
**   Updated based on actions from Code Walkthrough
**   Revision 1.1 2009/05/01 13:57:41EDT aschoeni 
**   Initial revision
**   Member added to project c:/MKSDATA/MKS-REPOSITORY/CFS-REPOSITORY/hs/fsw/src/project.pj
**
**************************************************************************/
#ifndef _hs_cmds_h_
#define _hs_cmds_h_

/*************************************************************************
** Includes
*************************************************************************/
#include "cfe.h"

/*************************************************************************
** Exported Functions
*************************************************************************/
/************************************************************************/
/** \brief Process a command pipe message
**
**  \par Description
**       Processes a single software bus command pipe message. Checks
**       the message and command IDs and calls the appropriate routine
**       to handle the message.
**
**  \par Assumptions, External Events, and Notes:
**       None
**
**  \param [in]   MessagePtr   A #CFE_SB_MsgPtr_t pointer that
**                             references the software bus message
**
**  \sa #CFE_SB_RcvMsg
**
*************************************************************************/
void HS_AppPipe(CFE_SB_MsgPtr_t MessagePtr);

/************************************************************************/
/** \brief Reset counters
**
**  \par Description
**       Utility function that resets housekeeping counters to zero
**
**  \par Assumptions, External Events, and Notes:
**       None
**
**  \sa #HS_ResetCmd
**
*************************************************************************/
void HS_ResetCounters(void);

/************************************************************************/
/** \brief Verify message length
**
**  \par Description
**       Checks if the actual length of a software bus message matches
**       the expected length and sends an error event if a mismatch
**       occurs
**
**  \par Assumptions, External Events, and Notes:
**       None
**
**  \param [in]   msg              A #CFE_SB_MsgPtr_t pointer that
**                                 references the software bus message
**
**  \param [in]   ExpectedLength   The expected length of the message
**                                 based upon the command code
**
**  \returns
**  \retstmt Returns TRUE if the length is as expected      \endcode
**  \retstmt Returns FALSE if the length is not as expected \endcode
**  \endreturns
**
**  \sa #HS_LEN_ERR_EID
**
*************************************************************************/
boolean HS_VerifyMsgLength(CFE_SB_MsgPtr_t msg,
                           uint16          ExpectedLength);
/************************************************************************/
/** \brief Manages HS tables
**
**  \par Description
**       Manages load requests for the AppMon, EventMon, ExeCount and MsgActs
**       tables and update notification for the AppMon and MsgActs tables.
**       Also releases and acquires table addresses. Gets called at the start
**       of each processing cycle and on initialization.
**
**  \par Assumptions, External Events, and Notes:
**       None
**
**  \sa #CFE_TBL_Manage
**
*************************************************************************/
void HS_AcquirePointers(void);

#endif /* _hs_cmds_h_ */

/************************/
/*  End of File Comment */
/************************/
