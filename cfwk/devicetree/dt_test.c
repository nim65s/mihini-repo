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

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "swi_devicetree.h"
#include "swi_dset.h"
#include "swi_log.h"
#include "testutils.h"

static char waitingForNotification = 1;
static swi_status_t test_dt_Get();
static swi_status_t test_dt_MultipleGet();

static swi_status_t notificationCb(swi_dset_Iterator_t *data)
{
  waitingForNotification = 0;
  test_dt_Get();
  test_dt_MultipleGet();

  return SWI_STATUS_OK;
}

static swi_status_t test_dt_Init()
{
  swi_status_t res;

  res = swi_dt_Init();

  if (res != SWI_STATUS_OK)
    return 1;

  res = swi_dt_Init();
  if (res != SWI_STATUS_OK)
    return 1;
  return 0;
}

static swi_status_t test_dt_Destroy()
{
  swi_status_t res;

  res = swi_dt_Destroy();

  if (res != SWI_STATUS_OK)
    return 1;

  res = swi_dt_Destroy();
  if (res != SWI_STATUS_OK)
    return 1;
  return 0;
}

static swi_status_t test_dt_Set()
{
  swi_status_t res;

  res = swi_dt_Init();

  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_SetString("config.toto", "toto");
  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_SetString("config.tata", "tataw");
  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_SetString("config.tata", "tata");
  if (res != SWI_STATUS_OK)
    return res;
  return 0;
}

static swi_status_t test_dt_Get()
{
  swi_status_t res;
  swi_dset_Iterator_t *set = NULL;

  res = swi_dt_Init();

  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_Get("config.toto", &set);
  if (res != SWI_STATUS_OK)
    return res;

  swi_dset_Next(set);
  if (swi_dset_GetType(set) != SWI_DSET_STRING)
    return 1;
  if (strcmp(swi_dset_ToString(set), "toto") != 0)
    return 2;
  swi_dset_Destroy(set);

  res = swi_dt_Get("config.tata", &set);
  if (res != SWI_STATUS_OK)
    return 3;

  swi_dset_Next(set);
  if (swi_dset_GetType(set) != SWI_DSET_STRING)
    return 4;
  if (strcmp(swi_dset_ToString(set), "tata") != 0)
    return 5;
  swi_dset_Destroy(set);

  res = swi_dt_Get("config", &set);
  swi_dset_Destroy(set);
  if (res != SWI_STATUS_DA_NODE)
    return 6;

  res = swi_dt_Get("unexisting_node", &set);
  if (res != SWI_STATUS_DA_NOT_FOUND)
    return 7;
  swi_dset_Destroy(set);

  res = swi_dt_Get(NULL, &set);
  if (res != SWI_STATUS_DA_NOT_FOUND)
    return 8;
  return 0;
}

static swi_status_t test_dt_MultipleGet()
{
  swi_status_t res;
  swi_dset_Iterator_t *set;
  const char * pathPtr[] = {
    "config.toto",
    "config",
    "config.tata",
    NULL
  };

  res = swi_dt_Init();

  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_MultipleGet(3, pathPtr, &set);
  if (res != SWI_STATUS_OK)
    return res;

  swi_dset_Next(set);
  if (swi_dset_GetType(set) != SWI_DSET_STRING)
    return 1;
  if (strcmp(swi_dset_ToString(set), "toto") != 0)
    return 2;

  swi_dset_Next(set);
  if (swi_dset_GetType(set) != SWI_DSET_STRING)
    return 4;
  if (strcmp(swi_dset_ToString(set), "tata") != 0)
    return 5;

  if (swi_dset_Next(set) != SWI_STATUS_DA_NOT_FOUND)
    return 6;
  swi_dset_Destroy(set);

  res = swi_dt_MultipleGet(0, pathPtr, &set);
  if (res != SWI_STATUS_DA_NOT_FOUND)
    return 7;

  res = swi_dt_MultipleGet(3, NULL, &set);
  if (res != SWI_STATUS_DA_NOT_FOUND)
    return 8;

  res = swi_dt_MultipleGet(0, NULL, &set);
  if (res != SWI_STATUS_DA_NOT_FOUND)
    return 9;

  return 0;
}

static swi_status_t test_dt_SetTypes()
{
  swi_status_t res;

  res = swi_dt_Init();
  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_SetInteger("config.toto", 0xdeadbeef);
  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_SetFloat("config.toto", 666.666);
  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_SetBool("config.toto", false);
  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_SetNull("config.toto");
  if (res != SWI_STATUS_OK)
    return res;

  return SWI_STATUS_OK;
}

static swi_status_t test_dt_Register(swi_dt_regId_t *regId)
{
  swi_status_t res;
  const char * regVarsPtr[] = {
    "config.toto",
    "config.tata",
    NULL
  };

  res = swi_dt_Init();

  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_Register(2, regVarsPtr, (swi_dt_NotifyCB_t)notificationCb, 0, NULL, regId);
  if (res != SWI_STATUS_OK)
    return res;
  return 0;
}

static swi_status_t test_dt_Unregister(swi_dt_regId_t regId)
{
  swi_status_t res;

  res = swi_dt_Init();

  if (res != SWI_STATUS_OK)
    return res;

  res = swi_dt_Unregister(regId);
  if (res != SWI_STATUS_OK)
    return res;
  return 0;
}

int main(void)
{
  swi_dt_regId_t regId = NULL;

  INIT_TEST("DT_TEST");

  CHECK_TEST(test_dt_Init());
  CHECK_TEST(test_dt_Init());
  CHECK_TEST(test_dt_Register(&regId));
  CHECK_TEST(test_dt_Set());

  while(waitingForNotification)
    ;

  CHECK_TEST(test_dt_Get());
  CHECK_TEST(test_dt_MultipleGet());
  CHECK_TEST(test_dt_Unregister(regId));
  CHECK_TEST(test_dt_SetTypes());

  CHECK_TEST(test_dt_Destroy());
  CHECK_TEST(test_dt_Destroy());
  return 0;
}
