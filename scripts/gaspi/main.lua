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
function M.Dirname(str)
   local dir = app.fs.filePath(str)
   if dir == "" then return nil end
   return dir .. app.fs.pathSeparator
end

function M.Basename(str)
   return app.fs.fileName(str)
end

function M.RemoveExtension(str)
   return app.fs.fileTitle(str)
end

-- Sprite handling.

-- Hides all layers and sub-layers inside a group, returning a list with all
-- initial states of each layer's visibility. Groups keep their own visibility.
function M.HideLayers(sprite)
   local data = {} -- Save visibility status of each layer here.
   for i,layer in ipairs(sprite.layers) do
      if layer.isGroup then
         -- Recursive for groups.
         data[i] = M.HideLayers(layer)
      else
         data[i] = layer.isVisible
         layer.isVisible = false
      end
   end
   return data
end

-- Restore layers visibility.
function M.RestoreLayersVisibility(sprite, data)
   for i,layer in ipairs(sprite.layers) do
      if layer.isGroup then
         -- Recursive for groups.
         M.RestoreLayersVisibility(layer, data[i])
      else
         layer.isVisible = data[i]
      end
   end
end

-- Dialog
function M.MsgDialog(title, msg)
   local dlg = Dialog(title)
   dlg:label{
      id = "msg",
      text = msg
   }
   dlg:newrow()
   dlg:button{id = "close", text = "Close", onclick = function() dlg:close() end }
   return dlg
end

-- Other

function M.CopyTable(original)
   local copy = {}
   for i, value in ipairs(original) do
       copy[i] = value
   end
   return copy
end

-- Settings persistence.
-- Each script stores its preferences in its own JSON file next to the scripts,
-- using Aseprite's built-in json namespace (Aseprite v1.3-rc5+).

local settings_dir = debug.getinfo(1, "S").source:match("@?(.*)[/\\]")

local function settingsFile(scope)
   return app.fs.joinPath(settings_dir, scope .. ".settings.json")
end

function M.LoadSettings(scope)
   if json == nil then return {} end
   local f = io.open(settingsFile(scope), "r")
   if not f then return {} end
   local content = f:read("a")
   f:close()
   local ok, settings = pcall(json.decode, content)
   if not ok or settings == nil then return {} end
   return settings
end

function M.SaveSettings(scope, settings)
   if json == nil then return end
   local f = io.open(settingsFile(scope), "w")
   if f then
      f:write(json.encode(settings))
      f:close()
   end
end

-- Path separator from Aseprite's API (works on all platforms).
M.Sep = app.fs.pathSeparator

-- Current sprite. Not called "Sprite" to avoid shadowing the API's Sprite class.
M.ActiveSprite = app.sprite
if M.ActiveSprite == nil then
   -- Show error, no sprite active.
   local dlg = M.MsgDialog("Error", "No sprite is currently active. Please, open a sprite first and run again.")
   dlg:show()
   return 1
end

if app.fs.filePath(M.ActiveSprite.filename) == "" then
   -- Error, can't identify OS when the sprite isn't saved somewhere.
   local dlg = M.MsgDialog("Error", "Current sprite is not associated to a file. Please, save your sprite and run again.")
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
