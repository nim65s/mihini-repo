/*******************************************************************************
 * Copyright (c) 2012 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Romain Perier      for Sierra Wireless - initial API and implementation
 *******************************************************************************/

#include <unistd.h>
#include "swi_log.h"
#include "swi_status.h"

#define INIT_TEST(name)                \
  static const char *__testname = name;        \
  swi_log_setlevel(INFO, __testname, NULL)

#define CHECK_TEST(call)            \
do {                                    \
  swi_status_t res;                \
  res = call;                    \
  while (res == SWI_STATUS_IPC_BROKEN) {        \
    res = call;                                 \
    sleep(2);                                   \
  }                                             \
  SWI_LOG(__testname, (res == SWI_STATUS_OK) ? INFO : ERROR,  #call "...%s\n", (res == SWI_STATUS_OK) ? "OK" : "FAIL");  \
  if (res != SWI_STATUS_OK)                                                                       \
  {                                    \
      SWI_LOG(__testname, ERROR, "Test failed with status code %d\n", res);                                              \
      return 1;                                \
  }                                                                                   \
} while(0)
