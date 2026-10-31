--[[

Description: 
An Aseprite script to export all slices as .png files in groups.

Usage:
Slices are exported to .png files. The name of the files
are the name of the slices. To group different slices,
use the user data field of the slice as the group number.
You can create subgroups to save the files in nested folders
by using the path separator symbol of your operative system
(which is "/" for GNU/Linux and "\" for Windows). For example:
"group1\subgroup1\subsubgroup1" (Windows)
"group1/subgroup1/subsubgroup2" (Linux)
"group1\subgroup2"              (Windows)
"group1\subgroup2\subsubgroup2" (Windows)
"group1\subgroup2\subsubgroup2" (Windows)
If the user data field is empty, then no group is assigned
and the slice is exported to the root selected folder.

About:
Made by Gaspi. Commissioned by Imvested.
   - Web: https://gaspi.games/
   - Twitter: @_Gaspi

--]]

-- Import main.
local script_dir = debug.getinfo(1, "S").source:match("@?(.*)[/\\]")
local M = dofile(app.fs.joinPath(script_dir, "main.lua"))
if type(M) ~= "table" then return M end

local active_sprite = M.active_sprite
local sep = M.sep
local dirname = M.dirname
local basename = M.basename
local remove_extension = M.remove_extension
local msg_dialog = M.msg_dialog
local load_settings = M.load_settings
local save_settings = M.save_settings

-- Load saved preferences.
local prefs = load_settings("export_slices")

-- Open main dialog.
local dlg = Dialog("Export slices")
dlg:file{
    id = "directory",
    label = "Output directory:",
    filename = prefs.directory or dirname(active_sprite.filename),
    open = false
}
dlg:entry{
    id = "filename",
    label = "File name format:",
    text = prefs.filename or ("{slicedata}" .. sep .. "{slicename}")
}
dlg:combobox{
    id = "format",
    label = "Export Format:",
    option = prefs.format or "png",
    options = {"png", "gif", "jpg"}
}
dlg:slider{id = "scale", label = "Export Scale:", min = 1, max = 10, value = prefs.scale or 1}
dlg:check{id = "save", label = "Save sprite:", selected = false}
dlg:button{id = "ok", text = "Export"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

if not dlg.data.ok then return 0 end

-- Get path and filename
local output_path = dirname(dlg.data.directory)
local filename = dlg.data.filename .. "." .. dlg.data.format

if output_path == nil then
    local msg_dlg = msg_dialog("Error", "No output directory was specified.")
    msg_dlg:show()
    return 1
end

filename = filename:gsub("{spritename}",
                         remove_extension(basename(active_sprite.filename)))

-- Export each slice by cropping a temporary copy (no undo entry on original).
local function perform_export()
    -- Count how many times a slice with the same name and group exist.
    local slice_count = {}
    for _, slice in ipairs(active_sprite.slices) do
        local slice_id = slice.data .. sep .. slice.name
        if slice_count[slice_id] == nil then
            slice_count[slice_id] = 1
        else
            slice_count[slice_id] = slice_count[slice_id] + 1
        end
    end

    -- Scale once, then duplicate the scaled copy for each slice to crop it.
    local scaled = Sprite(active_sprite)
    scaled:resize(scaled.width * dlg.data.scale, scaled.height * dlg.data.scale)

    for _, slice in ipairs(active_sprite.slices) do
        local copy = Sprite(scaled)

        -- Scale the slice bounds to match the resized copy.
        local scaled_bounds = Rectangle(
            slice.bounds.x * dlg.data.scale,
            slice.bounds.y * dlg.data.scale,
            slice.bounds.width * dlg.data.scale,
            slice.bounds.height * dlg.data.scale
        )
        copy:crop(scaled_bounds)

        local slice_id = slice.data .. sep .. slice.name
        local slice_filename = filename:gsub("{slicename}", slice.name)
        slice_filename = slice_filename:gsub("{slicedata}", slice.data)
        if slice_count[slice_id] > 1 then
            slice_filename = slice_filename .. "_" .. slice_count[slice_id]
        end

        app.fs.makeAllDirectories(dirname(output_path .. slice_filename))
        slice_count[slice_id] = slice_count[slice_id] - 1
        copy:saveCopyAs(output_path .. slice_filename)
        copy:close()
    end

    scaled:close()
    app.sprite = active_sprite
end

perform_export()

-- Save the original file if specified
if dlg.data.save then active_sprite:saveAs(active_sprite.filename) end

-- Persist settings for next run.
save_settings("export_slices", {
    directory = dlg.data.directory,
    filename = dlg.data.filename,
    format = dlg.data.format,
    scale = dlg.data.scale,
})

-- Success dialog.
local msg_dlg = msg_dialog("Success!", "Exported " .. #active_sprite.slices .. " slices.")
msg_dlg:show()

return 0
