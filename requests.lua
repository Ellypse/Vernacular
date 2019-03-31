local _, Vernacular = ...

local PREFIX = "VERN"
local REQUEST_TRANSLATION = "R"
local ANSWER_TRANSLATION = "A"
local DATA_SEPARATOR = ":"
local LOCALIZING_TEXT = " |cffCCCCCC(Requesting translation...)|r"

local activeRequests = {}
local nextMessageId = 0
local sentMessages = {}

local playerName
function Vernacular.getPlayerName()
    if not playerName then
        local name = UnitName("player")
        local realm = GetRealmName():gsub("[%s%-]", "")
        playerName = name .. "-" .. realm
    end
    return playerName
end

C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

local function onRequestedForTranslation(messageId, sender)
    local localization = sentMessages[tostring(messageId)]
    if localization then
        C_ChatInfo.SendAddonMessage(
                PREFIX,
                strjoin(DATA_SEPARATOR, ANSWER_TRANSLATION, messageId, localization),
                "WHISPER",
                sender
        )
    end
end

local function onReceivedAnswerForTranslation(messageId, translation, sender)
    activeRequests[messageId .. sender] = nil

    Vernacular.replaceMessageInChatFrames(messageId, sender, function(text)
        local linkIndex  = text:find("Hvernacular")
        if linkIndex then
            -- TODO: Improve this dirty son of hack
            local header = text:sub(0, linkIndex - 2)
            local rest = text:sub(linkIndex - 2, -1)
            local data = {strsplit(":", rest)}
            local languageName = data[4]
            return header .. Vernacular.formattedLanguageHeader(languageName, true) .. " " .. translation
        end
    end)
end

local function getData(data)
    return { strsplit(DATA_SEPARATOR, data) }
end

local f = CreateFrame("FRAME")
f:RegisterEvent("CHAT_MSG_ADDON")

f:SetScript("OnEvent", function(self, event, _, data, _, sender)
    if event == "CHAT_MSG_ADDON" then
        data = getData(data)
        local requestType = data[1]

        if requestType == REQUEST_TRANSLATION then
            local messageId = data[2]
            onRequestedForTranslation(messageId, sender)

        elseif requestType == ANSWER_TRANSLATION then
            local messageId, translation = data[2], data[3]
            onReceivedAnswerForTranslation(messageId, translation, sender)
        end

    end
end)

function Vernacular.requestForTranslation(messageId, sender)
    if sender == Vernacular.getPlayerName() then
        local localization = sentMessages[tostring(messageId)]
        onReceivedAnswerForTranslation(messageId, localization, sender)
    end

    if not activeRequests[messageId .. sender] then -- Make sure we only request once per message (multiple chat frames)
        activeRequests[messageId .. sender] = true
        C_ChatInfo.SendAddonMessage(
                PREFIX,
                strjoin(DATA_SEPARATOR, REQUEST_TRANSLATION, messageId),
                "WHISPER",
                sender
        )

        Vernacular.replaceMessageInChatFrames(messageId, sender, function(message)
            return message .. LOCALIZING_TEXT
        end)
    end
end

function Vernacular.getNextMessageId()
    nextMessageId = nextMessageId + 1
    return nextMessageId
end

function Vernacular.store(text)
    sentMessages[tostring(nextMessageId)] = text
end