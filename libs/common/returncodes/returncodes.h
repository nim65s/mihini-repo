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
* @file
* @brief Common return codes.
*
* This header provides an homogeneous return code namespace for all framework APIs.
*  @ingroup common
*
*/

#ifndef RETURNCODES_INCLUDE_GUARD
#define RETURNCODES_INCLUDE_GUARD

/**
* @enum rc_ReturnCode_t
* \brief Return code constants
* All error codes are negative.
*/
typedef enum
{
  RC_OK                  =    0,  ///< Successful.
  RC_NOT_FOUND           =   -1,  ///< The referenced item does not exist or could not be found.
  RC_OUT_OF_RANGE        =   -2,  ///< An index or other value is out of range.
  RC_NO_MEMORY           =   -3,  ///< Insufficient memory is available.
  RC_NOT_PERMITTED       =   -4,  ///< Current user does not have permission to perform requested action.
  RC_UNSPECIFIED_ERROR   =   -5,  ///< An unspecified error happened.
  RC_COMMUNICATION_ERROR =   -6,  ///< Communications error.
  RC_TIMEOUT             =   -7,  ///< A time-out occurred.
  RC_OVERFLOW            =   -8,  ///< An overflow occurred or would have occurred.
  RC_UNDERFLOW           =   -9,  ///< An underflow occurred or would have occurred.
  RC_WOULD_BLOCK         =  -10,  ///< Would have blocked if non-blocking behaviour was not requested.
  RC_DEADLOCK            =  -11,  ///< Would have caused a deadlock.
  RC_BAD_FORMAT          =  -12,  ///< Inputs or data are not formated correctly.
  RC_DUPLICATE           =  -13,  ///< Duplicate entry found or operation already performed.
  RC_BAD_PARAMETER       =  -14,  ///< Parameter is not valid.
  RC_CLOSED              =  -15,  ///< The file, stream or object was closed.
  RC_IO_ERROR            =  -16,  ///< An IO error occured.
  RC_NOT_IMPLEMENTED     =  -17,  ///< This feature is not implemented.
  RC_BUSY                =  -18,  ///< The compoenent or service is busy.
  RC_NOT_INITIALIZED     =  -19,  ///< The service or object is not initialized
  RC_END                 =  -20,  ///< The file, stream or buffer reached the end.
  RC_NOT_AVAILABLE       =  -21,  ///< The service is not available.
} rc_ReturnCode_t;


/**
* \brief Convert a rc_ReturnCode_t into string representing the ReturnCode
* Returns a const string or NULL if the code does not exist.
*/
const char *rc_returncode2string( rc_ReturnCode_t n);


/**
* \brief Convert a ReturnCode string into a rc_ReturnCode_t value
* Returns the code value (negative or null value) or 1 is the string does not
* represent a known error name.
*/
rc_ReturnCode_t rc_string2returncode( const char *name);


#endif // RETURNCODES_INCLUDE_GUARD
