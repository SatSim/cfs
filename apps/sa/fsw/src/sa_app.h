/*******************************************************************************
** File: sample_app.h
**
** Purpose:
**   This file is main hdr file for the SAMPLE application.
**
**
*******************************************************************************/

#ifndef _sample_app_h_
#define _sample_app_h_

/*
** Required header files.
*/
#include "cfe.h"
#include "cfe_error.h"
#include "cfe_evs.h"
#include "cfe_sb.h"
#include "cfe_es.h"

#include <string.h>
#include <errno.h>
#include <unistd.h>

/***********************************************************************/

#define SAMPLE_PIPE_DEPTH                     32

/************************************************************************
** Type Definitions
*************************************************************************/

/****************************************************************************/
/*
** Local function prototypes.
**
** Note: Except for the entry point (SAMPLE_AppMain), these
**       functions are not called from any other source module.
*/
void SA_AppMain(void);
void SA_AppInit(void);
void SA_ProcessCommandPacket(void);
void SA_ProcessGroundCommand(void);
void SA_ReportHousekeeping(void);
void SA_ResetCounters(void);

boolean SA_VerifyCmdLength(CFE_SB_MsgPtr_t msg, uint16 ExpectedLength);

#endif /* _sample_app_h_ */
