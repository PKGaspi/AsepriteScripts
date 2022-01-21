--[[

Description: An Aseprite script to export all combinations of layers inside
groups.

Usage: Keep your layers organized in groups. For every group there is, only one
layer at a time will be exported, with one layer of every other group. All
possible combinations will be exported.

About: Made by Gaspi. Commissioned by AnomuraGame.
- Web: https://gaspi.games/
- Twitter: @_Gaspi

--]]

-- Import main.
local err = dofile("main.lua")
if err ~= 0 then return err end

-- Variable to keep track of number of current combination.
local combination = 0

local function exportCombinations(sprite, g, output_path)
    if #g == 0 then
        os.execute("mkdir \"" .. Dirname(output_path) .. "\"")
        sprite:saveCopyAs(output_path:gsub("{combination}", combination))
        combination = combination + 1
        return
    end

    local groups = CopyTable(g)
    -- Ignore isolated layers
    while groups[1] ~= nil and not groups[1].isGroup do
        table.remove(groups, 1)
    end

    if groups[1] == nil then return end

    local changing_group = groups[1]
    table.remove(groups, 1)
    for _, layer in ipairs(changing_group.layers) do
        layer.isVisible = true
        exportCombinations(sprite, groups, output_path)
        layer.isVisible = false
    end
end

-- Open main dialog.
local dlg = Dialog("Export combinations")
dlg:file{
    id = "directory",
    label = "Output directory:",
    filename = Sprite.filename,
    open = false
}
dlg:entry{
    id = "filename",
    label = "File name format:",
    text = "{spritename}_{combination}"
}
dlg:combobox{
    id = 'format',
    label = 'Export Format:',
    option = 'png',
    options = {'png', 'gif', 'jpg'}
}
dlg:slider{id = 'scale', label = 'Export Scale:', min = 1, max = 10, value = 1}
dlg:check{id = "save", label = "Save sprite:", selected = false}
dlg:button{id = "ok", text = "Export"}
dlg:button{id = "cancel", text = "Cancel", onclick = function() dlg:close() end}
dlg:show()

if not dlg.data.ok then return 0 end

-- Get path and filename
local output_path = Dirname(dlg.data.directory)
local filename = dlg.data.filename

if output_path == nil then
    local dlg = MsgDialog("Error", "No output directory was specified.")
    dlg:show()
    return 1
end

if not string.find(filename, "{combination}") then
    -- combination format is mandatory. Append to string.
    filename = filename .. "_{combination}"
end

filename = filename:gsub("{spritename}",
                         RemoveExtension(Basename(Sprite.filename)))
filename = filename .. '.' .. dlg.data.format


-- Finally, perform everything.
Sprite:resize(Sprite.width * dlg.data.scale, Sprite.height * dlg.data.scale)
local layers_visibility_data = HideLayers(Sprite)
exportCombinations(Sprite, Sprite.layers, output_path .. filename)
RestoreLayersVisibility(Sprite, layers_visibility_data)
Sprite:resize(Sprite.width / dlg.data.scale, Sprite.height / dlg.data.scale)

-- Save the original file if specified
if dlg.data.save then Sprite:saveAs(dlg.data.directory) end

-- Success dialog.
local dlg =
    MsgDialog("Success!", "Exported " .. combination .. " combinations.")
dlg:show()

return 0
