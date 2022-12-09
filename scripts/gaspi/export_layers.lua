--[[

Description:
A script to save all different layers in different files.

Made by Gaspi.
   - Itch.io: https://gaspi.itch.io/
   - Twitter: @_Gaspi
--]]

-- Import main.
local err = dofile("main.lua")
if err ~= 0 then return err end

-- Variable to keep track of the number of layers exported.
local n_layers = 0
-- Exports every layer individually.
local function exportLayers(sprite, root_layer, filename, group_sep, data)
    for _, layer in ipairs(root_layer.layers) do
        local filename = filename
        if layer.isGroup then
            -- Recursive for groups.
            local previousVisibility = layer.isVisible
            layer.isVisible = true
            filename = filename:gsub("{layergroups}",
                                     layer.name .. group_sep .. "{layergroups}")
            exportLayers(sprite, layer, filename, group_sep, data)
            layer.isVisible = previousVisibility
        else
            -- Individual layer. Export it.
            layer.isVisible = true
            filename = filename:gsub("{layergroups}", "")
            filename = filename:gsub("{layername}", layer.name)
            os.execute("mkdir \"" .. Dirname(filename) .. "\"")
            if data.spritesheet then
                app.command.ExportSpriteSheet{
                    ui=false,
                    askOverwrite=false,
                    type=SpriteSheetType.HORIZONTAL,
                    columns=0,
                    rows=0,
                    width=0,
                    height=0,
                    bestFit=false,
                    textureFilename=filename,
                    dataFilename="",
                    dataFormat=SpriteSheetDataFormat.JSON_HASH,
                    borderPadding=0,
                    shapePadding=0,
                    innerPadding=0,
                    trim=data.trim,
                    mergeDuplicates=data.mergeDuplicates,
                    extrude=false,
                    openGenerated=false,
                    layer="",
                    tag="",
                    splitLayers=false,
                    listLayers=layer,
                    listTags=true,
                    listSlices=true,
                }
            else
                sprite:saveCopyAs(filename)
            end
            layer.isVisible = false
            n_layers = n_layers + 1
        end
    end
end

-- Open main dialog.
local dlg = Dialog("Export slices")
dlg:file{
    id = "directory",
    label = "Output directory:",
    filename = Sprite.filename,
    open = false
}
dlg:entry{
    id = "filename",
    label = "File name format:",
    text = "{layergroups}{layername}"
}
dlg:combobox{
    id = 'format',
    label = 'Export Format:',
    option = 'png',
    options = {'png', 'gif', 'jpg'}
}
dlg:combobox{
    id = 'group_sep',
    label = 'Group separator:',
    option = Sep,
    options = {Sep, '-', '_'}
}
dlg:slider{id = 'scale', label = 'Export Scale:', min = 1, max = 10, value = 1}
dlg:check{
    id = "spritesheet",
    label = "Export as spritesheet:",
    selected = false,
    onclick = function()
        -- Show this options only if spritesheet is checked.
        dlg:modify{
            id = "trim",
            visible = dlg.data.spritesheet
        }
        dlg:modify{
            id = "mergeDuplicates",
            visible = dlg.data.spritesheet
        }
    end
}
dlg:check{
    id = "trim",
    label = "  Trim:",
    selected = false,
    visible = false
}
dlg:check{
    id = "mergeDuplicates",
    label = "  Merge duplicates:",
    selected = false,
    visible = false
}
dlg:check{id = "save", label = "Save sprite:", selected = false}
dlg:button{id = "ok", text = "Export"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

if not dlg.data.ok then return 0 end

-- Get path and filename
local output_path = Dirname(dlg.data.directory)
local filename = dlg.data.filename .. "." .. dlg.data.format

if output_path == nil then
    local dlg = MsgDialog("Error", "No output directory was specified.")
    dlg:show()
    return 1
end

local group_sep = dlg.data.group_sep
filename = filename:gsub("{spritename}",
                         RemoveExtension(Basename(Sprite.filename)))
filename = filename:gsub("{groupseparator}", group_sep)

-- Finally, perform everything.
Sprite:resize(Sprite.width * dlg.data.scale, Sprite.height * dlg.data.scale)
local layers_visibility_data = HideLayers(Sprite)
exportLayers(Sprite, Sprite, output_path .. filename, group_sep, dlg.data)
RestoreLayersVisibility(Sprite, layers_visibility_data)
Sprite:resize(Sprite.width / dlg.data.scale, Sprite.height / dlg.data.scale)

-- Save the original file if specified
if dlg.data.save then Sprite:saveAs(dlg.data.directory) end

-- Success dialog.
local dlg = MsgDialog("Success!", "Exported " .. n_layers .. " layers.")
dlg:show()

return 0
