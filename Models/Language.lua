local _, Vernacular = ...

function Vernacular.Language(name)
    local _name = name

    return {

        ApplyTransformations = --[[ Override ]] function(_, text)
            return text
        end,

        GetName = function()
            return _name
        end
    }
end