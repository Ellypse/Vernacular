local _, Vernacular = ...

local PREFIX = "VERN"
local REQUEST_TRANSLATION = "R"
local ANSWER_TRANSLATION = "A"
local DATA_SEPARATOR = ":"
local LOCALIZING_TEXT = " |cffCCCCCC(Requesting translation...)|r"

local activeRequests = {}
local nextMessageId = 0
local sentMessages = {}
local lastSentMessage = ""

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

f:SetScript("OnEvent", function(self, event, prefix, data, _, sender)
    if event == "CHAT_MSG_ADDON" then
        if prefix == "Tongues2" then
            Vernacular.onTonguesReceived(event, prefix, data, _, sender)
            return
        end
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
    lastSentMessage = text
    sentMessages[tostring(nextMessageId)] = text
end


-----------------------------
--- Tongues
-----------------------------

C_ChatInfo.RegisterAddonMessagePrefix("Tongues2")

local serializer = LibStub("AceSerializer-3.0");

Vernacular.TONGUES_LANGUAGES = {
    "Orcish",
    "Common",
    "Zandali",
    "Dwarvish",
    "Draenei",
    "Gnomish",
    "Darnassian",
    "Forsaken",
    "Gutterspeak",
    "Taurahe",
    "Thalassian",
    "Gilnean",
    "Nether",
    "Ursine",
    "Kodo",
    "Wyvern",
    "Seal",
    "Bird",
    "Ravenspeech",
    "Equine",
    "Binary",
    "Moonkin",
    "Trentish",
    "Dark Iron",
    "Kalimag",
    "Demonic",
    "Eredun",
    "Titan",
    "Draconic",
    "Nerubian",
    "Qiraji",
    "Nerglish",
    "Nazja",
    "Scourge"
}

function Vernacular.onTonguesReceived(_, _, data, chatType, sender)
    local success, deserializedData = serializer:Deserialize(data)
    if not success then return end
    local type = deserializedData[1]
    if type == "RT" then
        local _, _, channel, frame, language = unpack(deserializedData)
        C_ChatInfo.SendAddonMessage("Tongues2", serializer:Serialize({ "TR", channel, frame, language, lastSentMessage}), "WHISPER", sender)
    elseif type == "TR" then
        local _, _, _, language, text = unpack(deserializedData)
        onReceivedAnswerForTranslation("TONGUES_" .. language, text, sender)
    end
end

function Vernacular.requestForTonguesTranslation(language, player, chatType)
    local messageId = "TONGUES_" .. language
    if not activeRequests[messageId .. player] then
        activeRequests[messageId .. player] = true
        C_ChatInfo.SendAddonMessage("Tongues2", serializer:Serialize({ "RT", 100, chatType, 1, language, lastSentMessage}), "WHISPER", player)
        Vernacular.replaceMessageInChatFrames(messageId, player, function(message)
            return message .. LOCALIZING_TEXT
        end)
    end
end