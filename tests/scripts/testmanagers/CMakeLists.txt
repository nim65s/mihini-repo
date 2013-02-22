#*******************************************************************************
# Copyright (c) 2012 Sierra Wireless and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     Sierra Wireless - initial API and implementation
#*******************************************************************************

ADD_LUA_LIBRARY(embeddedtestmanagers DESTINATION tests/managers EXCLUDE_FROM_ALL
  automatedunittest.lua
  RATlinux.lua
  RATcommon.lua
  TestFwk.lua
  TestOnCommitFwk.lua
  startOnCommitTests.lua
  TestDailyFwk.lua
  startDailyTests.lua
  starttests.lua
  linux/x86/applicationcontainer.lua
  linux/x86/migrationhelper.lua
  common/commands.lua
  common/configstore.lua
  common/datapersistence.lua
  common/ftplogstore.lua
  common/generalfeatures.lua
  common/softwareupdate.lua
)
