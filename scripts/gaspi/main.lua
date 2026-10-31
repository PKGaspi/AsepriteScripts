--[[

Description:
Main Aseprite script to use my other scripts and supply some common functions.

Usage:
Simply run this script and select which script to use in the menu.

About:
Made by Gaspi.
- Web: https://gaspi.games/
- Twitter: @_Gaspi

--]]

local M = {}

-- Path handling — thin wrappers around Aseprite's app.fs API.

-- Return the path to the dir containing a file (with a trailing separator), or
-- nil if the given path has no directory part.
function M.dirname(str)
    local dir = app.fs.filePath(str)
    if dir == "" then return nil end
    return dir .. app.fs.pathSeparator
end

function M.basename(str)
    return app.fs.fileName(str)
end

function M.remove_extension(str)
    return app.fs.fileTitle(str)
end

-- Replaces every occurrence of placeholder (e.g. "{layername}") in str with
-- value. "%" in value is escaped so names like "50%" can't break gsub.
function M.replace_placeholder(str, placeholder, value)
    local escaped_value = tostring(value):gsub("%%", "%%%%")
    local result = str:gsub(placeholder, escaped_value)
    return result
end

-- Sprite handling.

-- Hides all layers and sub-layers inside a group, returning a list with all
-- initial states of each layer's visibility. Groups keep their own visibility.
function M.hide_layers(sprite)
    local data = {} -- Save visibility status of each layer here.
    for i,layer in ipairs(sprite.layers) do
        if layer.isGroup then
            -- Recursive for groups.
            data[i] = M.hide_layers(layer)
        else
            data[i] = layer.isVisible
            layer.isVisible = false
        end
    end
    return data
end

-- Saves a copy of the current state of the sprite to path. Aseprite saves a
-- multi-frame sprite as a numbered sequence of files when the format has no
-- animation, which can overwrite other exports whose names end in a number
-- (e.g. "_1.png"). So for those formats each frame is rendered and saved on its
-- own as "<title>_<frame>.<ext>".
function M.save_sprite_copy(sprite, path)
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

-- Dialog
function M.msg_dialog(title, msg)
    local dlg = Dialog(title)
    dlg:label{
        id = "msg",
        text = msg
    }
    dlg:newrow()
    dlg:button{id = "close", text = "Close", onclick = function() dlg:close() end }
    return dlg
end

-- Settings persistence.
-- Each script stores its preferences in its own JSON file next to the scripts,
-- using Aseprite's built-in json namespace (Aseprite v1.3-rc5+).

local settings_dir = debug.getinfo(1, "S").source:match("@?(.*)[/\\]")

local function settings_file(scope)
    return app.fs.joinPath(settings_dir, scope .. ".settings.json")
end

function M.load_settings(scope)
    if json == nil then return {} end
    local f = io.open(settings_file(scope), "r")
    if not f then return {} end
    local content = f:read("a")
    f:close()
    local ok, settings = pcall(json.decode, content)
    if not ok or settings == nil then return {} end
    return settings
end

function M.save_settings(scope, settings)
    if json == nil then return end
    local f = io.open(settings_file(scope), "w")
    if f then
        f:write(json.encode(settings))
        f:close()
    end
end

-- Path separator from Aseprite's API (works on all platforms).
M.sep = app.fs.pathSeparator

-- Current sprite. Not called "Sprite" to avoid shadowing the API's Sprite class.
M.active_sprite = app.sprite
if M.active_sprite == nil then
    -- Show error, no sprite active.
    local dlg = M.msg_dialog("Error", "No sprite is currently active. Please, open a sprite first and run again.")
    dlg:show()
    return 1
end

if app.fs.filePath(M.active_sprite.filename) == "" then
    -- Error, can't identify OS when the sprite isn't saved somewhere.
    local dlg = M.msg_dialog("Error", "Current sprite is not associated to a file. Please, save your sprite and run again.")
    dlg:show()
    return 1
end

-- Check if this is being run directly.
if debug.getinfo(2) == nil then
    local script_dir = debug.getinfo(1, "S").source:match("@?(.*)[/\\]")
    local dlg = Dialog("Gaspi scripts")
    dlg:label{id = "msg", text = "What can I help you with?"}
    dlg:newrow()
    dlg:button{id = "layers", text = "Export layers", onclick = function() dofile(app.fs.joinPath(script_dir, "export_layers.lua")) end}
    dlg:newrow()
    dlg:button{id = "slices", text = "Export slices", onclick = function() dofile(app.fs.joinPath(script_dir, "export_slices.lua")) end}
    dlg:newrow()
    dlg:button{id = "combinations", text = "Export combinations", onclick = function() dofile(app.fs.joinPath(script_dir, "export_combinations.lua")) end}
    dlg:newrow()
    dlg:button{id = "close", text = "Close", onclick = function() dlg:close() end }
    dlg:show()
end

return M
