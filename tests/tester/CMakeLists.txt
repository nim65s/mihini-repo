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

ADD_LUA_LIBRARY(tester DESTINATION tester EXCLUDE_FROM_ALL
  test.lua
  testmanager.lua
  targetmanager.lua
)
