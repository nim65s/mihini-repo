/*******************************************************************************
 * Copyright (c) 2012 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Gilles Cannenterre for Sierra Wireless - initial API and implementation
 *******************************************************************************/

#ifndef MODBUS_SERIALIZER_H_
#define MODBUS_SERIALIZER_H_

/**
 * @file modbus_serializer.h
 * @brief modbus serializer platform independant api.
 */

#include "modbus_types.h"
#include "serial_serializer.h"

typedef struct ModbusRequest_ {
    uint8_t slaveId;               // slave id
    ModbusFunctionCode function;   // modbus function code
    uint16_t startingAddress;      // address
    uint16_t numberOfObjects;      // number of objects (get/set)
    uint16_t byteCount;            // byte count (get/set)
        union {
        void*    pValues;
        uint32_t iValue;
    } value;                       // values (get/set)
} ModbusRequest;

typedef struct ModbusResponse_ {
    uint8_t slaveId;               // slave id
    ModbusFunctionCode function;   // modbus function code
    ModbusExceptionCode exception; // modbus exception code
    uint16_t startingAddress;      // address
    uint16_t numberOfObjects;      // number of objects (get/set)
    uint16_t byteCount;            // byte count (get/set)
    union {
        void*    pValues;
        uint32_t iValue;
    } value;                       // values (get/set)
} ModbusResponse;

typedef struct ModbusSpecifics_ {
    /* modbus protocol specifics */
    ModbusRequestMode requestMode; // modbus serial mode
    uint16_t requestTrId;          // transaction id
    uint8_t slaveAddrOffset;       // offset of the slave address in PDU
    uint8_t isCustom;              // flag set for custom requests (to not decode response)

    ModbusRequest request;         // request
    ModbusResponse response;       // response
} ModbusSpecifics;

/* init,release serializer */
swi_status_t MODBUS_SER_InitSerializer(Serializer* pSerializer, /*ModbusRequestMode*/void* mode);
void MODBUS_SER_ReleaseSerializer(Serializer* pSerializer);

/* create request */
swi_status_t MODBUS_SER_CreateRequest(Serializer* pSerializer, /*ModbusRequest*/void* pRequestData);
/* a separate function is needed for custom requests in order to be able to create custom request with
 * known function codes.
 * Fields used in ModbusRequest are slaveId, function, byteCount and value.pValues */
swi_status_t MODBUS_SER_CreateCustomRequest(Serializer* pSerializer, /*ModbusRequest*/void* pRequestData);

/* parse */
uint8_t MODBUS_SER_IsResponseComplete(Serializer* pSerializer);
swi_status_t MODBUS_SER_CheckResponse(Serializer* pSerializer);
swi_status_t MODBUS_SER_AnalyzeResponse(Serializer* pSerializer, swi_status_t status);

/* utils */
swi_status_t MODBUS_SER_GetRequestPDU(Serializer* pSerializer, uint8_t** ppBuffer, uint16_t* pBufferLength);
swi_status_t MODBUS_SER_GetResponsePDU(Serializer* pSerializer, uint8_t** ppBuffer, uint16_t* pBufferLength);
uint16_t MODBUS_SER_GetExpectedResponseLength(Serializer* pSerializer);
const char* MODBUS_SER_GetExceptionString(ModbusExceptionCode exception);

#endif /* MODBUS_SERIALIZER_H_ */
