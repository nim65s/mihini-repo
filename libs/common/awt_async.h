/*******************************************************************************
 * Copyright (c) 2012 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Sierra Wireless - initial API and implementation
 *******************************************************************************/

#ifndef __AWT_ASYNC_H__
#define __AWT_ASYNC_H__

#include "swi_status.h"


/**
 * @file awt_async.h
 * @brief Common stuff that is used for ASYNC APIs.
 *
 * General note for all @b ASYNC APIs:@n
 * The return code of an asynchronous function gives important information on the behavior of the function call process,
 * it returns an swi_status_t :
 *  - SWI_STATUS_ASYNC : when the action has been taken care of. An event will be triggered in order
 *        to inform the user how the asynchronous operations went. (Status will be OK or an ERROR )
 *  - SWI_STATUS_OK : when the action requested was actually able to be done synchronously. No further action is
 *        requested, no event will be triggered for this request (because it already completed !)
 *  - SWI_STATUS_BUSY : The action requested is not possible at that moment because some resources are not available.
 *        This error usually happens when an asynchronous function was called a second time before the first asynchronous call actually
 *        completed (an asynchronous call is complete if it returned OK synchronously or an event was called to signal
 *        the end of the process). This return code will not provoke a special event.
 *  - SOME_OTHER_ERRORS_CODE : when an error happens synchronously (before executing the asynchronous part of the call). This
 *        conclude the asynchronous call. This return code will not provoke a special event.
 * @ingroup common
 */



/**
 * @enum AwtEvent
 * \brief Event types for asynchronous event callbacks: AwtCom or AwtDaHL libraries.
 */
typedef enum
{
  AWTDACOM_INIT_EVENT,
  AWTDACOM_FORCE_CONNECTION_TO_SERVER_EVENT,
  AWTDACOM_RECEIVE_DATA_EVENT,
  AWTDACOM_SEND_DATA_EVENT,

  AWTDAHL_DATAMANAGER_CREATE_EVENT,
  AWTDAHL_DATAMANAGER_FLUSH_EVENT,
  AWTDAHL_RECEIVED_RESPONSE_EVENT,
  AWTDAHL_RECEIVED_MESSAGE_EVENT,

} AwtEvent;


/**
 * AWT Event callback.
 * Prototype of the callback used to signal events.
 * @param event the event being signaled. The event is actually linked to an asynchronous functionality
 * @param status the status of the functionality being event'ed.
 */
typedef void (*AwtEventCallback) (void* pContext, AwtEvent event, swi_status_t status, void* pUserData);


/**
 * Asynchronous main function type.
 * See AWT_ASYNC_Run for more details.
 */
typedef void (*AwtAsyncMain) (int argc, char **argv);

/**
 * Asynchronous thread.
 * When using the asynchronous API, the user must provide a running thread.
 * All calls of the asynchronous API must be done in that thread, since the API is not thread-safe in itself.
 * The call to this function returns only when the user wants to terminate the application calling AWT_ASYNC_End.
 * This function will initialize the asynchronous framework and then call the asynchronous main function given as
 * parameter.
 * If the asynchronous framework is already running, a call to this function return directly.
 */
swi_status_t AWT_ASYNC_Run(int argc, char **argv, AwtAsyncMain asyncMain);

/**
 * Ask the Asynchronous framework to stop.
 * This will cause the AWT_ASYNC_Run function to return.
 * This function must be called within the thread that called AWT_ASYNC_Run.
 */
swi_status_t AWT_ASYNC_Terminate();




#endif // __AWT_ASYNC_H__
