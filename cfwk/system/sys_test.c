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

#include <stdlib.h>
#include "swi_system.h"
#include "swi_log.h"

#define CALL_TEST(call)                \
do {                                    \
  swi_status_t res;                \
                          \
  res = call;                                \
  SWI_LOG("DT_TEST", (res == SWI_STATUS_OK) ? INFO : ERROR,  #call "...%s\n", (res == SWI_STATUS_OK) ? "OK" : "FAIL"); \
  if (res != SWI_STATUS_OK)                        \
    {                                    \
      SWI_LOG("DT_TEST", ERROR, "Test failed with status code %d\n", res); \
      return 1;                                \
  }                                    \
} while(0)

static int test_sys_Init()
{
  swi_status_t res;

  res = swi_sys_Init();
  return res != SWI_STATUS_OK ? 1 : 0;
}

static int test_sys_Destroy()
{
  swi_status_t res;

  res = swi_sys_Destroy();
  return res != SWI_STATUS_OK ? 1 : 0;
}

static int test_sys_Reboot(const char *reason)
{
  swi_status_t res;

  res = swi_sys_Reboot(reason);
  return res != SWI_STATUS_OK ? 1 : 0;
}

int main(void)
{
  swi_log_setlevel(INFO, "DT_TEST", NULL);

  CALL_TEST(test_sys_Init());
  CALL_TEST(test_sys_Init());
  CALL_TEST(test_sys_Reboot("TEST1 FOR REBOOT"));
  CALL_TEST(test_sys_Reboot("TEST2 FOR REBOOT"));
  CALL_TEST(test_sys_Reboot(""));
  CALL_TEST(test_sys_Reboot(NULL));
  CALL_TEST(test_sys_Destroy());
  CALL_TEST(test_sys_Destroy());
  return 0;
}
