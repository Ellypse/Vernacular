local _, Vernacular = ...

local HEADER_SEPARATOR = ":"
local CHAT_LINK_CODE = "vernacular";
local CHAT_LINK_LENGTHS = CHAT_LINK_CODE:len();
local FORMATTED_LINK_FORMAT = "|H" ..  CHAT_LINK_CODE .. HEADER_SEPARATOR .. "%s" .. HEADER_SEPARATOR .. "%s" .. HEADER_SEPARATOR .. "%s" .. HEADER_SEPARATOR .. "|h%s|h|r";
local FIND_LINK_CODE_FORMAT = "H" .. CHAT_LINK_CODE .. HEADER_SEPARATOR .. "%s" .. HEADER_SEPARATOR .. "%s"

local tonguesCompatibility = true -- Hard coded for now, we'll provide a nice option later

local RAW_TAG_PATTERN = "[%s" .. HEADER_SEPARATOR .. "v" .. HEADER_SEPARATOR .. "%s] " -- This is the raw tag to be sent in chat
local TONGUES_RAW_TAG = "[%s] "
local FIND_RAW_TAG_PATTERN = "%[([^%]]+)" .. HEADER_SEPARATOR .. "v" .. HEADER_SEPARATOR .. "([^%]]+)%]";
local TONGUES_FIN_TAG = "%[([^%]]+)%]"

local POSSIBLE_CHANNELS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_CHANNEL"
};

local LINK_COLOR = RAID_CLASS_COLORS.MONK
local LOCALIZED_COLOR = RAID_CLASS_COLORS.PRIEST

local MAIN_LANGUAGE_ID = GetDefaultLanguage()

-- Hard hook SendChatMessage
local oldSendChatMessage = SendChatMessage
SendChatMessage = function(text , chatType , languageIndex , channel)
    local modifiedText = text
    if text and text ~= "" and
        Vernacular.selectedLanguage and Vernacular.selectedLanguage.ApplyTransformation and
        tContains(POSSIBLE_CHANNELS, "CHAT_MSG_" .. chatType)
    then
        local messageChunks = Vernacular.SplitIntoChunks(text)
        for _, chunk in ipairs(messageChunks) do
            modifiedText = Vernacular.selectedLanguage:ApplyTransformation(chunk)
            Vernacular.store(chunk)
            oldSendChatMessage(modifiedText, chatType , MAIN_LANGUAGE_ID , channel)
        end
    else
        oldSendChatMessage(modifiedText, chatType , languageIndex , channel)
    end
end

function Vernacular.languageHeader(languageName)
    if tonguesCompatibility then
        return TONGUES_RAW_TAG:format(languageName)
    else
        return RAW_TAG_PATTERN:format(languageName, Vernacular.getNextMessageId())
    end
end

function Vernacular.formattedLanguageHeader(languageName, isLocalized)
   return (isLocalized and LOCALIZED_COLOR or LINK_COLOR):WrapTextInColorCode("[" .. languageName .. "]")
end


local function generateFormattedLink(languageName, playerName, messageID)
    return FORMATTED_LINK_FORMAT:format(playerName, messageID, languageName, Vernacular.formattedLanguageHeader(languageName, false));
end

-- MessageEventFilter to look for Total RP 3 chat links and format the message accordingly
local function lookForChatLinks(_, chatType, message, playerName, ...)
    if chatType == "CHAT_MSG_WHISPER_INFORM" then
        playerName = Vernacular.getPlayerName()
    end
    message = gsub(message, FIND_RAW_TAG_PATTERN, function(text, messageID)
        if messageID then
            Vernacular.requestForTranslation(messageID, playerName)
        end
        return generateFormattedLink(text, playerName, messageID)
    end)
    message = gsub(message, TONGUES_FIN_TAG, function(language)
        Vernacular.requestForTonguesTranslation(language, playerName, chatType)
        return generateFormattedLink(language, playerName, "TONGUES_" .. language)
    end)
    return false, message, playerName, ...;
end

function Vernacular.replaceMessageInChatFrames(messageId, sender, closure)
    local findMessagePattern = FIND_LINK_CODE_FORMAT:format(sender, messageId)
    local function shouldChangeMessage(text, ...)
        if text and text:find(messageId) and text:find(findMessagePattern, 1, true) then
            return true
        end
    end

    local function changeMessage(text, ...)
        return closure(text), ...
    end

    for i = 1, FCF_GetNumActiveChatFrames() do
        local chatWindow = _G["ChatFrame"..i];
        if chatWindow and chatWindow.TransformMessages then
            chatWindow:TransformMessages(shouldChangeMessage, changeMessage);
        end
    end
end

hooksecurefunc("ChatFrame_OnHyperlinkShow", function(_, link)
    local linkType = link:sub(1, CHAT_LINK_LENGTHS);

    if linkType == CHAT_LINK_CODE then
        local data = { strsplit(HEADER_SEPARATOR, link) }
        local messageId = data[3]
        local sender = data[2]

        Vernacular.requestForTranslation(messageId, sender)
    end
end)

-- Sadly we need this so that Blizzard's code doesn't raise an error because we clicked on a link it doesn't understand
local OriginalSetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link, ...)
    if (link and link:sub(0, CHAT_LINK_LENGTHS) == CHAT_LINK_CODE) then
        return
    end
    return OriginalSetHyperlink(self, link, ...);
end

for _, channel in pairs(POSSIBLE_CHANNELS) do
    ChatFrame_AddMessageEventFilter(channel, lookForChatLinks);
end