/*******************************************************************************
 * Copyright (c) 2012 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Laurent Barthelemy for Sierra Wireless - initial API and implementation
 *     Romain Perier      for Sierra Wireless - initial API and implementation
 *******************************************************************************/

#include <string.h>
#include <stdint.h>
#include "swi_system.h"
#include "swi_log.h"
#include "emp.h"
#include "yajl_gen.h"
#include "yajl_helpers.h"

#define SWI_SYS_ERROR 1

static uint8_t module_initialized = 0;

swi_status_t swi_sys_Init()
{
  swi_status_t res;

  if (module_initialized)
    return SWI_STATUS_OK;

  res = emp_parser_init(SWI_EMP_INIT_NO_CMDS);
  if (res != SWI_STATUS_OK)
    return res;
  module_initialized = 1;
  return SWI_STATUS_OK;
}

swi_status_t swi_sys_Destroy()
{
  swi_status_t res = SWI_STATUS_OK;

  if (module_initialized)
  {
    res = emp_parser_destroy(SWI_EMP_DESTROY_NO_CMDS);
    module_initialized = 0;
  }
  return res;
}

swi_status_t swi_sys_Reboot(const char* reasonPtr)
{
  char *payload = NULL;
  size_t payloadLen = 0;
  swi_status_t res;
  yajl_gen gen;

  YAJL_GEN_ALLOC(gen);

  if (reasonPtr == NULL)
    goto emp_send;

  YAJL_GEN_STRING(reasonPtr, "reasonPtr");
  YAJL_GEN_GET_BUF(payload, payloadLen);
emp_send:
  res = emp_send_and_wait_response(EMP_REBOOT, 0, payload, payloadLen, NULL, NULL);
  yajl_gen_clear(gen);
  yajl_gen_free(gen);
  return res;
}
