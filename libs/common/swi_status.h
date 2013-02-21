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

/**
* @defgroup common common
* This group contains common files for Swi libraries
*/


/**
* @file
* @brief Common status codes.
*
* This header gives an homogeneous status code namespace for all SWI APIs.
*  @ingroup common
*
* <HR>
*/


#ifndef SWI_STATUS_INCLUDE_GUARD
#define SWI_STATUS_INCLUDE_GUARD


/**
* Homogeneous status codes for SWI APIs.
*/

#define SWI_STATUS(cat, code) (((cat)<<8) | (code))

/**
* @enum swi_StatusCategory_t
* \brief Status categories
*
* This enum is 'statically' enumerated. It is FORBIDDEN to change any of the following values.
* When new error category is needed, just add an entry in the enum.
*/
typedef enum
{
  SWI_CAT_SYSTEM      = 0, ///< System related status codes.
  SWI_CAT_AWTDA       = 1, ///< AwtDa protocol object related status codes.
  SWI_CAT_NETWORK     = 2, ///< Network related error codes.
  SWI_CAT_SERIAL      = 3, ///< Serial related codes.
  SWI_CAT_DA          = 4  ///< Data Access related codes (Device Tree, Data reception, etc.).
} swi_StatusCategory_t;


/**
* @enum swi_status_t
* \brief Return status constants
*
* This enum is 'statically' enumerated. It is FORBIDDEN to change any of the following values.
* When new error is needed, just add an entry in the enum.
*
*/
typedef enum
{
  SWI_STATUS_OK                                 = 0,                                    ///< SWI_STATUS_OK

  // System related status codes
  SWI_STATUS_UNKNOWN_ERROR                      = SWI_STATUS(SWI_CAT_SYSTEM, 1),        ///< SWI_STATUS_UNKNOWN_ERROR
  SWI_STATUS_ASYNC                              = SWI_STATUS(SWI_CAT_SYSTEM, 2),        ///< SWI_STATUS_ASYNC
  SWI_STATUS_BUSY                               = SWI_STATUS(SWI_CAT_SYSTEM, 3),        ///< SWI_STATUS_BUSY
  SWI_STATUS_ALLOC_FAILED                       = SWI_STATUS(SWI_CAT_SYSTEM, 4),        ///< SWI_STATUS_ALLOC_FAILED
  SWI_STATUS_NOT_ENOUGH_MEMORY                  = SWI_STATUS(SWI_CAT_SYSTEM, 5),        ///< SWI_STATUS_NOT_ENOUGH_MEMORY
  SWI_STATUS_RESOURCE_INITIALIZATION_FAILED     = SWI_STATUS(SWI_CAT_SYSTEM, 6),        ///< SWI_STATUS_RESOURCE_INITIALIZATION_FAILED
  SWI_STATUS_RESOURCE_NOT_INITIALIZED           = SWI_STATUS(SWI_CAT_SYSTEM, 7),        ///< SWI_STATUS_RESOURCE_NOT_INITIALIZED
  SWI_STATUS_CONTEXT_IS_CORRUPTED               = SWI_STATUS(SWI_CAT_SYSTEM, 8),        ///< SWI_STATUS_CONTEXT_IS_CORRUPTED
  SWI_STATUS_READ_BUFFER_EOS                    = SWI_STATUS(SWI_CAT_SYSTEM, 9),        ///< SWI_STATUS_READ_BUFFER_EOS
  SWI_STATUS_CORRUPTED_BUFFER                   = SWI_STATUS(SWI_CAT_SYSTEM, 10),       ///< SWI_STATUS_CORRUPTED_BUFFER
  SWI_STATUS_WRONG_PARAMS                       = SWI_STATUS(SWI_CAT_SYSTEM, 11),       ///< SWI_STATUS_WRONG_PARAMS
  SWI_STATUS_EMPTY                              = SWI_STATUS(SWI_CAT_SYSTEM, 12),       ///< SWI_STATUS_EMPTY
  SWI_STATUS_SERVICE_UNAVAILABLE                = SWI_STATUS(SWI_CAT_SYSTEM, 13),       ///< SWI_STATUS_SERVICE_UNAVAILABLE
  SWI_STATUS_ASYNC_FORBIDDEN_CALL               = SWI_STATUS(SWI_CAT_SYSTEM, 14),       ///< SWI_STATUS_ASYNC_FORBIDDEN_CALL
  SWI_STATUS_UNKNOWN_COMMAND                    = SWI_STATUS(SWI_CAT_SYSTEM, 15),       ///< SWI_STATUS_UNKNOWN_COMMAND
  SWI_STATUS_OPERATION_FAILED                   = SWI_STATUS(SWI_CAT_SYSTEM, 16),       ///< SWI_STATUS_OPERATION_FAILED
  //
  SWI_STATUS_INVALID_PATH                       = SWI_STATUS(SWI_CAT_SYSTEM, 17),       ///< SWI_STATUS_INVALID_PATH

  // AwtDa protocol object related status codes
  SWI_STATUS_OBJECT_NOT_INITIALIZED             = SWI_STATUS(SWI_CAT_AWTDA, 0),         ///< SWI_STATUS_OBJECT_NOT_INITIALIZED /* = 256 */
  SWI_STATUS_INVALID_OBJECT_TYPE                = SWI_STATUS(SWI_CAT_AWTDA, 1),         ///< SWI_STATUS_INVALID_OBJECT_TYPE
  SWI_STATUS_INVALID_OBJECT_CONTENT             = SWI_STATUS(SWI_CAT_AWTDA, 2),         ///< SWI_STATUS_INVALID_OBJECT_CONTENT
  SWI_STATUS_NOT_A_LIST                         = SWI_STATUS(SWI_CAT_AWTDA, 3),         ///< SWI_STATUS_NOT_A_LIST
  SWI_STATUS_NOT_A_MAP                          = SWI_STATUS(SWI_CAT_AWTDA, 4),         ///< SWI_STATUS_NOT_A_MAP
  SWI_STATUS_ITEM_NOT_FOUND                     = SWI_STATUS(SWI_CAT_AWTDA, 5),         ///< SWI_STATUS_ITEM_NOT_FOUND
  SWI_STATUS_BYTECODE_NOT_SUPPORTED             = SWI_STATUS(SWI_CAT_AWTDA, 6),         ///< SWI_STATUS_BYTECODE_NOT_SUPPORTED
  SWI_STATUS_OBJECT_CREATION_FAILED             = SWI_STATUS(SWI_CAT_AWTDA, 7),         ///< SWI_STATUS_OBJECT_CREATION_FAILED
  SWI_STATUS_VALUE_OUT_OF_BOUND                 = SWI_STATUS(SWI_CAT_AWTDA, 8),         ///< SWI_STATUS_VALUE_OUT_OF_BOUND

  // Network related error codes
  SWI_STATUS_SERVER_UNREACHABLE                 = SWI_STATUS(SWI_CAT_NETWORK, 0),       ///< SWI_STATUS_SERVER_UNREACHABLE /* = 512 */
  SWI_STATUS_SERVER_FAILURE                     = SWI_STATUS(SWI_CAT_NETWORK, 1),       ///< SWI_STATUS_SERVER_FAILURE
  SWI_STATUS_IPC_READ_ERROR                     = SWI_STATUS(SWI_CAT_NETWORK, 2),       ///< SWI_STATUS_IPC_READ_ERROR
  SWI_STATUS_IPC_WRITE_ERROR                    = SWI_STATUS(SWI_CAT_NETWORK, 3),       ///< SWI_STATUS_IPC_WRITE_ERROR
  SWI_STATUS_IPC_TIMEOUT                        = SWI_STATUS(SWI_CAT_NETWORK, 4),       ///< SWI_STATUS_IPC_TIMEOUT
  SWI_STATUS_IPC_BROKEN                         = SWI_STATUS(SWI_CAT_NETWORK, 5),       ///< SWI_STATUS_IPC_BROKEN

  // Serial related codes
  SWI_STATUS_SERIAL_ERROR                       = SWI_STATUS_UNKNOWN_ERROR,             ///< SWI_STATUS_SERIAL_ERROR - 1
  SWI_STATUS_SERIAL_STACK_NOT_READY             = SWI_STATUS_BUSY,                      ///< SWI_STATUS_SERIAL_STACK_NOT_READY - 3

  SWI_STATUS_SERIAL_RESPONSE_TIMEOUT            = SWI_STATUS(SWI_CAT_SERIAL, 10),       ///< SWI_STATUS_SERIAL_RESPONSE_TIMEOUT - 778
  SWI_STATUS_SERIAL_RESPONSE_EXCEPTION          = SWI_STATUS(SWI_CAT_SERIAL, 11),       ///< SWI_STATUS_SERIAL_RESPONSE_EXCEPTION - 779
  SWI_STATUS_SERIAL_RESPONSE_INVALID_FRAME      = SWI_STATUS(SWI_CAT_SERIAL, 12),       ///< SWI_STATUS_SERIAL_RESPONSE_INVALID_FRAME - 780
  SWI_STATUS_SERIAL_RESPONSE_BAD_CHECKSUM       = SWI_STATUS(SWI_CAT_SERIAL, 13),       ///< SWI_STATUS_SERIAL_RESPONSE_BAD_CHECKSUM - 782
  SWI_STATUS_SERIAL_RESPONSE_INCOMPLETE_FRAME   = SWI_STATUS(SWI_CAT_SERIAL, 14),       ///< SWI_STATUS_SERIAL_RESPONSE_INCOMPLETE_FRAME - 783
  SWI_STATUS_SERIAL_RESPONSE_BAD_SLAVE          = SWI_STATUS(SWI_CAT_SERIAL, 15),       ///< SWI_STATUS_SERIAL_RESPONSE_BAD_SLAVE - 784
  SWI_STATUS_SERIAL_RESPONSE_BAD_FUNCTION       = SWI_STATUS(SWI_CAT_SERIAL, 16),       ///< SWI_STATUS_SERIAL_RESPONSE_BAD_FUNCTION - 785
  SWI_STATUS_SERIAL_RESPONSE_SHORT_FRAME        = SWI_STATUS(SWI_CAT_SERIAL, 17),       ///< SWI_STATUS_SERIAL_RESPONSE_SHORT_FRAME - 786

  SWI_STATUS_SERIAL_INIT_CONTEXT_NULL           = SWI_STATUS_RESOURCE_NOT_INITIALIZED,  ///< SWI_STATUS_SERIAL_INIT_CONTEXT_NULL - 788
  SWI_STATUS_SERIAL_INIT_NULL_POINTER           = SWI_STATUS_ALLOC_FAILED,              ///< SWI_STATUS_SERIAL_INIT_UART_BUFFER_NULL - 789
  SWI_STATUS_SERIAL_INIT_CANNOT_CAPTURE_UART    = SWI_STATUS(SWI_CAT_SERIAL, 22),       ///< SWI_STATUS_SERIAL_INIT_CANNOT_CAPTURE_UART - 790
  SWI_STATUS_SERIAL_INIT_CANNOT_SET_MESSAGE     = SWI_STATUS(SWI_CAT_SERIAL, 23),       ///< SWI_STATUS_SERIAL_INIT_CANNOT_SET_MESSAGE - 791
  SWI_STATUS_SERIAL_INIT_STACK_READY            = SWI_STATUS_OK,                        ///< SWI_STATUS_SERIAL_INIT_STACK_READY - 0
  SWI_STATUS_SERIAL_INIT_CANNOT_SET_FLOW_CONTROL= SWI_STATUS(SWI_CAT_SERIAL, 25),       ///< SWI_STATUS_SERIAL_INIT_CANNOT_SET_FLOW_CONTROL - 793

  SWI_STATUS_SERIAL_REQUEST_PARAMETER_ERROR     = SWI_STATUS_WRONG_PARAMS,              ///< SWI_STATUS_SERIAL_REQUEST_PARAMETER_ERROR - 11


  //Data Access related codes (Tree extension, etc)
  SWI_STATUS_DA_NOT_FOUND                       = SWI_STATUS(SWI_CAT_DA, 0),            ///< SWI_STATUS_DA_NOT_FOUND - 1024
  SWI_STATUS_DA_BAD_TYPE                        = SWI_STATUS(SWI_CAT_DA, 1),            ///< SWI_STATUS_DA_BAD_TYPE - 1025
  SWI_STATUS_DA_BAD_CONTENT                     = SWI_STATUS(SWI_CAT_DA, 2),            ///< SWI_STATUS_DA_BAD_CONTENT - 1026
  SWI_STATUS_DA_PERMISSION_REFUSED              = SWI_STATUS(SWI_CAT_DA, 3),            ///< SWI_STATUS_DA_PERMISSION_REFUSED - 1027
  SWI_STATUS_DA_UNSUPPORTED_ACTION              = SWI_STATUS(SWI_CAT_DA, 4),            ///< SWI_STATUS_DA_UNSUPPORTED_ACTION -1028
  SWI_STATUS_DA_NODE                            = SWI_STATUS(SWI_CAT_DA, 5),            ///< SWI_STATUS_DA_NODE - 1029



} swi_status_t;

#endif /* SWI_STATUS_INCLUDE_GUARD */

