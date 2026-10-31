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

local active_sprite = M.active_sprite
local dirname = M.dirname
local basename = M.basename
local remove_extension = M.remove_extension
local replace_placeholder = M.replace_placeholder
local save_sprite_copy = M.save_sprite_copy
local msg_dialog = M.msg_dialog
local load_settings = M.load_settings
local save_settings = M.save_settings

-- Load saved preferences.
local prefs = load_settings("export_combinations")

-- Variable to keep track of number of current combination.
local combination = 0

-- Returns the top-level groups of the sprite that take part in the
-- combinations. Isolated layers and empty groups are ignored.
local function collect_groups(sprite, only_visible)
    local groups = {}
    for _, layer in ipairs(sprite.layers) do
        if layer.isGroup and #layer.layers > 0
           and (not only_visible or layer.isVisible) then
            groups[#groups + 1] = layer
        end
    end
    return groups
end

-- Hides isolated top-level layers and every layer directly inside the
-- combination groups. Sub-groups keep their contents' visibility, so each
-- sub-group is exported as a whole when it's its group's chosen layer.
local function hide_combination_layers(sprite, groups)
    for _, layer in ipairs(sprite.layers) do
        if not layer.isGroup then layer.isVisible = false end
    end
    for _, group in ipairs(groups) do
        for _, layer in ipairs(group.layers) do
            layer.isVisible = false
        end
    end
end

-- Exports every combination of one layer per group, from groups[i] onwards.
local function export_combinations(sprite, groups, i, output_path)
    if i > #groups then
        combination = combination + 1
        local combination_path = replace_placeholder(output_path, "{combination}", combination)
        app.fs.makeAllDirectories(dirname(combination_path))
        save_sprite_copy(sprite, combination_path)
        return
    end

    for _, layer in ipairs(groups[i].layers) do
        layer.isVisible = true
        export_combinations(sprite, groups, i + 1, output_path)
        layer.isVisible = false
    end
end

-- Open main dialog.
local dlg = Dialog("Export combinations")
dlg:file{
    id = "directory",
    label = "Output directory:",
    filename = prefs.directory or dirname(active_sprite.filename),
    open = false
}
dlg:entry{
    id = "filename",
    label = "File name format:",
    text = prefs.filename or "{spritename}_{combination}"
}
dlg:combobox{
    id = "format",
    label = "Export Format:",
    option = prefs.format or "png",
    options = {"png", "gif", "jpg"}
}
dlg:slider{id = "scale", label = "Export Scale:", min = 1, max = 10, value = prefs.scale or 1}
dlg:check{id = "only_visible", label = "Only visible groups:", selected = false}
dlg:check{id = "save", label = "Save sprite:", selected = false}
dlg:button{id = "ok", text = "Export"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

if not dlg.data.ok then return 0 end

-- Get path and filename
local output_path = dirname(dlg.data.directory)
local filename = dlg.data.filename

if output_path == nil then
    local msg_dlg = msg_dialog("Error", "No output directory was specified.")
    msg_dlg:show()
    return 1
end

if not filename:find("{combination}", 1, true) then
    -- combination format is mandatory. Append to string.
    filename = filename .. "_{combination}"
end

filename = replace_placeholder(filename, "{spritename}",
                               remove_extension(basename(active_sprite.filename)))
filename = filename .. "." .. dlg.data.format

if #collect_groups(active_sprite, dlg.data.only_visible) == 0 then
    local msg = "No layer groups with layers were found in the sprite."
    if dlg.data.only_visible then
        msg = "No visible layer groups with layers were found in the sprite."
    end
    local msg_dlg = msg_dialog("Error", msg)
    msg_dlg:show()
    return 1
end

-- Work on a copy so the original sprite is never mutated (no undo entry).
local function perform_export()
    local copy = Sprite(active_sprite)
    app.sprite = copy
    copy:resize(copy.width * dlg.data.scale, copy.height * dlg.data.scale)
    local groups = collect_groups(copy, dlg.data.only_visible)
    hide_combination_layers(copy, groups)
    export_combinations(copy, groups, 1, output_path .. filename)
    copy:close()
    app.sprite = active_sprite
end

perform_export()

-- Save the original file if specified
if dlg.data.save then active_sprite:saveAs(active_sprite.filename) end

-- Persist settings for next run.
save_settings("export_combinations", {
    directory = dlg.data.directory,
    filename = dlg.data.filename,
    format = dlg.data.format,
    scale = dlg.data.scale,
})

-- Success dialog.
local msg_dlg =
    msg_dialog("Success!", "Exported " .. combination .. " combinations.")
msg_dlg:show()

return 0
