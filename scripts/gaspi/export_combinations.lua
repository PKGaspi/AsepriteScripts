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
local MsgDialog = M.MsgDialog
local LoadSettings = M.LoadSettings
local SaveSettings = M.SaveSettings

-- Load saved preferences.
local prefs = LoadSettings("export_combinations")

-- Variable to keep track of number of current combination.
local combination = 0

-- Returns the top-level groups of the sprite that take part in the
-- combinations. Isolated layers and empty groups are ignored.
local function collectGroups(sprite, only_visible)
    local groups = {}
    for _, layer in ipairs(sprite.layers) do
        if layer.isGroup and #layer.layers > 0
           and (not only_visible or layer.isVisible) then
            groups[#groups + 1] = layer
        end
    end
    return groups
end

-- Saves the current state of the sprite to path. Aseprite saves a multi-frame
-- sprite with a name ending in a number (e.g. "_1.png") as a numbered sequence
-- that overwrites the next combinations, so for formats without animation
-- each frame is rendered and saved on its own as "<title>_<frame>.<ext>".
local function saveCombination(sprite, path)
    if #sprite.frames == 1 or app.fs.fileExtension(path) == "gif" then
        sprite:saveCopyAs(path)
        return
    end

    local path_title = app.fs.filePathAndTitle(path)
    local extension = app.fs.fileExtension(path)
    local image = Image(sprite.spec)
    for frame_number = 1, #sprite.frames do
        image:clear()
        image:drawSprite(sprite, frame_number)
        image:saveAs{
            filename = path_title .. "_" .. frame_number .. "." .. extension,
            palette = sprite.palettes[1]
        }
    end
end

-- Exports every combination of one layer per group, from groups[i] onwards.
local function exportCombinations(sprite, groups, i, output_path)
    if i > #groups then
        combination = combination + 1
        local combination_path = output_path:gsub("{combination}", combination)
        app.fs.makeAllDirectories(Dirname(combination_path))
        saveCombination(sprite, combination_path)
        return
    end

    for _, layer in ipairs(groups[i].layers) do
        layer.isVisible = true
        exportCombinations(sprite, groups, i + 1, output_path)
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

if #collectGroups(active_sprite, dlg.data.only_visible) == 0 then
    local msg = "No layer groups with layers were found in the sprite."
    if dlg.data.only_visible then
        msg = "No visible layer groups with layers were found in the sprite."
    end
    local dlg = MsgDialog("Error", msg)
    dlg:show()
    return 1
end

-- Work on a copy so the original sprite is never mutated (no undo entry).
local function performExport()
    local copy = Sprite(active_sprite)
    app.sprite = copy
    copy:resize(copy.width * dlg.data.scale, copy.height * dlg.data.scale)
    HideLayers(copy)

    -- HideLayers doesn't change groups' visibility, so "only visible" still
    -- works on the copy.
    local groups = collectGroups(copy, dlg.data.only_visible)
    exportCombinations(copy, groups, 1, output_path .. filename)
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
