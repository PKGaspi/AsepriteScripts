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
local script_dir = debug.getinfo(1, "S").source:match("@?(.*)[/\\]")
local M = dofile(app.fs.joinPath(script_dir, "main.lua"))
if type(M) ~= "table" then return M end

local active_sprite = M.ActiveSprite
local Sep = M.Sep
local Dirname = M.Dirname
local Basename = M.Basename
local RemoveExtension = M.RemoveExtension
local HideLayers = M.HideLayers
local CopyTable = M.CopyTable
local MsgDialog = M.MsgDialog
local LoadSettings = M.LoadSettings
local SaveSettings = M.SaveSettings

-- Load saved preferences.
local prefs = LoadSettings("export_combinations")

-- Variable to keep track of number of current combination.
local combination = 0

local function exportCombinations(sprite, g, output_path)
    if #g == 0 then
        app.fs.makeAllDirectories(Dirname(output_path))
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
    filename = prefs.directory or Dirname(active_sprite.filename),
    open = false
}
dlg:entry{
    id = "filename",
    label = "File name format:",
    text = prefs.filename or "{spritename}_{combination}"
}
dlg:combobox{
    id = 'format',
    label = 'Export Format:',
    option = prefs.format or 'png',
    options = {'png', 'gif', 'jpg'}
}
dlg:slider{id = 'scale', label = 'Export Scale:', min = 1, max = 10, value = prefs.scale or 1}
dlg:check{id = "only_visible", label = "Only visible groups:", selected = false}
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
                         RemoveExtension(Basename(active_sprite.filename)))
filename = filename .. '.' .. dlg.data.format


-- Work on a copy so the original sprite is never mutated (no undo entry).
local function performExport()
    local copy = Sprite(active_sprite)
    app.sprite = copy
    copy:resize(copy.width * dlg.data.scale, copy.height * dlg.data.scale)
    HideLayers(copy)

    -- Only keep originally-visible groups if requested. HideLayers doesn't
    -- change groups' visibility.
    local layers_to_export = {}
    for _, layer in ipairs(copy.layers) do
        if not dlg.data.only_visible or layer.isVisible then
            layers_to_export[#layers_to_export + 1] = layer
        end
    end

    exportCombinations(copy, layers_to_export, output_path .. filename)
    copy:close()
    app.sprite = active_sprite
end

performExport()

-- Save the original file if specified
if dlg.data.save then active_sprite:saveAs(active_sprite.filename) end

-- Persist settings for next run.
SaveSettings("export_combinations", {
    directory = dlg.data.directory,
    filename = dlg.data.filename,
    format = dlg.data.format,
    scale = dlg.data.scale,
})

-- Success dialog.
local dlg =
    MsgDialog("Success!", "Exported " .. combination .. " combinations.")
dlg:show()

return 0
