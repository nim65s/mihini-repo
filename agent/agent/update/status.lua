local M = { }

local num2string = {
    [200]  = "OK",
    [473] = "INVALID_UPDATE_PATH",
    [474] = "MISSING_INSTALL_SCRIPT",
    [475] = "CANNOT_LOAD_INSTALL_SCRIPT",
    [476] = "CANNOT_RUN_INSTALL_SCRIPT",
    [477] = "APPLICATION_CONTAINER_NOT_RUNNING",
    [478] = "UPDATER_ERROR",
    [558] = "WRONG_PARAMS"
}

local string2num = { }

for k, v in pairs(num2string) do string2num[v]=k end

function M.tonumber(str)
    checks('string')
    return assert(string2num[str], "Unknown M3DA status name")
end

function M.tostring(num)
    checks('number')
    return assert(num2string[num], "Unknown M3DA status number")
end

return M