--- These are helpers took and modified from the UnlimitedChatMessage add-on from Cyprias
--- https://wow.curseforge.com/projects/unlimitedchatmessage
--- Redistributed under the same GNU GENERAL PUBLIC LICENSE version 3
---
--- This helpers are NOT used in order to reproduce the same feature as UnlimitedChatMessage
--- but to support splitting messages made longer by the usage of this add-on before sending them in chat

local _, Vernacular = ...


local defaultMaxLetters = 200; -- Smaller limit, to take into account the language header

-- UTF-8 Reference:
-- 0xxxxxxx - 1 byte UTF-8 codepoint (ASCII character)
-- 110yyyxx - First byte of a 2 byte UTF-8 codepoint
-- 1110yyyy - First byte of a 3 byte UTF-8 codepoint
-- 11110zzz - First byte of a 4 byte UTF-8 codepoint
-- 10xxxxxx - Inner byte of a multi-byte UTF-8 codepoint

local function chsize(char)
    if not char then
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end


local function utf8sub(str, startByte, numBytes)
    local currentIndex = startByte
    local returnedBytes = 0;

    while numBytes > 0 and currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + chsize(char)
        numBytes = numBytes - chsize(char)
        returnedBytes = returnedBytes + chsize(char)
    end
    return str:sub(startByte, currentIndex - 1), returnedBytes
end

local function GetShorterString(longMsg)
    local shortText, sizeBytes = utf8sub(longMsg, 1, defaultMaxLetters - 1)
    local remainingPart = longMsg:sub(sizeBytes + 1, longMsg:len())
    return shortText, remainingPart;
end


function Vernacular.SplitIntoChunks(longMsg)
    local splitMessageLinks = {};

    local words = {}
    for v in longMsg:gmatch("[^ ]+") do
        --Check if 'word' is longer then 254 characters. (wtf?) anyway split long string at the 254 char mark.
        if v:len() > defaultMaxLetters then
            local shortPart, remainingPart = nil, v;
            local i=1;
            while remainingPart and remainingPart:len() > 0 do
                shortPart, remainingPart = GetShorterString(remainingPart);
                if shortPart and shortPart ~= "" then
                    table.insert(words, shortPart)
                end

                if i>10 then break; end
                i=i+1;
            end
        else
            table.insert(words, v)
        end
    end

    local temp = "";
    local chunks = {}
    for i=1, #words do
        if temp:len() + words[i]:len() <= (defaultMaxLetters - 1) then
            if temp:len() > 0 then
                temp = temp.." "..words[i];
            else
                temp = words[i];
            end

        else
            temp = temp:gsub("\001\002%d+\003\004", function(link)
                local index = tonumber(link:match("(%d+)"));
                return splitMessageLinks[index] or link;
            end);

            table.insert(chunks, temp);
            temp = words[i];
        end
    end

    if temp:len() > 0 then
        temp = temp:gsub("\001\002%d+\003\004", function(link)
            local index = tonumber(link:match("(%d+)"));
            return splitMessageLinks[index] or link;
        end);

        table.insert(chunks, temp);
    end

    return chunks;
end