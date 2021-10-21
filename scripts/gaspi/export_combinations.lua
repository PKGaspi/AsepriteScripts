--[[

Description: 
An Aseprite script to export all combinations of layers inside groups.

Usage:
Keep your layers organized in groups. For every group there is,
only one layer at a time will be exported, with one layer of every
other group. All possible combinations will be exported.

About:
Made by Gaspi. Commissioned by AnomuraGame.
- Web: https://gaspi.games/
- Twitter: @_Gaspi

--]]

-- Auxiliar functions.

combination = 0
-- Source: https://stackoverflow.com/questions/9102126/lua-return-directory-path-from-path
function getPath(str,sep)
    sep=sep or'/'
    return str:match("(.*"..sep..")")
end

--[[ Sources:
- https://codereview.stackexchange.com/questions/90177/get-file-name-with-extension-and-get-only-extension
- https://stackoverflow.com/questions/18884396/extracting-filename-only-with-pattern-matching
--]]
function getFileName(str,sep)
    str = str:match("^.+"..sep.."(.+)$")
    return str:match("(.+)%..+")
end

local function copyTable(original)
    local copy = {}
    for i, value in ipairs(original) do
        copy[i] = value
    end
    return copy
end

-- Hides all layers and sublayers inside a group, returning a list with all initial states of each layer's visibility.
function hideLayers(sprite)
    local layerVisibility = {}
    for i,layer in ipairs(sprite.layers) do
        -- Avoid group layers.
        if (not layer.isGroup) then
            layerVisibility[i] = layer.isVisible
            layer.isVisible = false
        else 
            layerVisibility[i] = hideLayers(layer)
        end
    end
    return layerVisibility
end

-- Restore layers visibility.
function restoreLayersVisibility(sprite, layerVisibility)
    for i,layer in ipairs(sprite.layers) do
        -- Avoid group layers.
        if not layer.isGroup then
            layer.isVisible = layerVisibility[i]
        else
            restoreLayersVisibility(layer, layerVisibility[i])
        end
    end
end

function exportCombinations(sprite, g, pathPrefix, pathSufix, format)
    if #g == 0 then
        sprite:saveCopyAs(pathPrefix .. combination .. pathSufix .. format)
        combination = combination + 1
        return
    end
    
    local groups = copyTable(g)
    -- Ignore isolated layers
    while groups[1] ~= nil and not groups[1].isGroup do
        table.remove(groups, 1)
    end
    
    if groups[1] == nil then
        return
    end
    
    local changingGroup = groups[1]
    table.remove(groups, 1)
    for i, layer in ipairs(changingGroup.layers) do
        layer.isVisible = true
        exportCombinations(sprite, groups, pathPrefix, pathSufix, format)
        layer.isVisible = false
    end
end

local sprite = app.activeSprite
if sprite == nil then
    -- Show error, no sprite active.
    local dlg = Dialog("Error")
    dlg:label{  id = 0,
    text = "No sprite is currently active. Please, open a sprite first and run the script with it active."
}
dlg:button{ id = 1, text = "Close",
onclick = function()
    dlg:close()
end
}
dlg:show()
return
end


-- Ask for export path
local dlg = Dialog("Export combinations") 
local sprite = app.activeSprite
dlg:file{ id="directory", label="Output directory:", filename=sprite.filename, open=false}
dlg:combobox{ id='format', label='Export Format:', option='gif', options={'png', 'gif', 'jpg'}}
dlg:slider{ id='scale', label='Export Scale:', min=1, max=10, value=1}
dlg:check{ id="save", label="Save sprite:", selected=false}
dlg:button{ id="ok", text="Export" }
dlg:button{ id="cancel", text="Cancel", 
onclick = function()
    dlg:close()
end
}
dlg:show()

if not dlg.data.ok then
    return
end

-- Identify operative system.
local separator = string.sub(sprite.filename, 1, 1) == '/' and '/' or '\\'
-- Get path and filename
local path = getPath(dlg.data.directory, separator)
local filename = getFileName(dlg.data.directory, separator)


sprite:resize(sprite.width * dlg.data.scale, sprite.height * dlg.data.scale)
local layersVisibility = hideLayers(sprite)
exportCombinations(sprite, sprite.layers, path .. filename .. '_', '', '.' .. dlg.data.format)
restoreLayersVisibility(sprite, layersVisibility)
sprite:resize(sprite.width / dlg.data.scale, sprite.height / dlg.data.scale)

-- Save the original file if specified
if dlg.data.save then
    sprite:saveAs(dlg.data.directory)
end