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

ADD_SUBDIRECTORY(core)
ADD_SUBDIRECTORY(config)
ADD_SUBDIRECTORY(testsuites)
ADD_SUBDIRECTORY(customfiles)
ADD_SUBDIRECTORY(racontestwrapper)

ADD_LUA_LIBRARY(testsauto DESTINATION testsauto EXCLUDE_FROM_ALL)

ADD_DEPENDENCIES(testsauto tester testconfig testsuites testspecific)



