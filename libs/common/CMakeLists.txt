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

CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
PROJECT(LIB_MIHINI_COMMON)

ADD_LIBRARY(lib_pointerlist STATIC pointer_list.c)
SET_TARGET_PROPERTIES(lib_pointerlist PROPERTIES
    COMPILE_FLAGS -fPIC # necessary so that the lib can be used linked in a static code or a shared library
    OUTPUT_NAME pointerlist)

ADD_PUBLIC_HEADER(lib_pointerlist swi_status.h)

ADD_LIBRARY(lib_swi_log SHARED swi_log.c)
SET_TARGET_PROPERTIES(lib_swi_log PROPERTIES OUTPUT_NAME Swi_log)
