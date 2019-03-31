local _, Vernacular = ...

local f = CreateFrame("FRAME")

f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function()
    C_Timer.After(1, function()

        for _, TRP2Language in pairs(TRP2_DB_Languages) do

            local language = Vernacular.Language(TRP2Language["Entete"])

            function language:ApplyTransformation(text)
                return Vernacular.languageHeader(self:GetName()) .. TRP2_TraductionComprehension(text, TRP2Language["HashTables"])
            end

            UIMenu_AddButton(LanguageMenu, language:GetName(), nil, function(...)
                Vernacular.selectedLanguage = language
                ChatMenu:Hide();
            end)

        end
        UIMenu_AutoSize(LanguageMenu);
    end)
end)

-- When a default game language is clicked, remove the selectedLanguage
hooksecurefunc("LanguageMenu_Click", function()
    Vernacular.selectedLanguage = nil
end)

