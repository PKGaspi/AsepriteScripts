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

function M.Dirname(str)
   return app.fs.filePath(str) .. app.fs.pathSeparator
end

function M.Basename(str)
   return app.fs.fileName(str)
end

function M.RemoveExtension(str)
   return app.fs.fileTitle(str)
end

-- Sprite handling.

-- Hides all layers and sub-layers inside a group, returning a list with all
-- initial states of each layer's visibility (including groups themselves).
function M.HideLayers(sprite)
   local data = {} -- Save visibility status of each layer here.
   for i,layer in ipairs(sprite.layers) do
      if layer.isGroup then
         -- Save group visibility, then recurse into children.
         data[i] = { groupVisible = layer.isVisible, children = M.HideLayers(layer) }
         layer.isVisible = false
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
         layer.isVisible = data[i].groupVisible
         M.RestoreLayersVisibility(layer, data[i].children)
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

-- Path separator from Aseprite's API (works on all platforms).
M.Sep = app.fs.pathSeparator

-- Current sprite.
M.Sprite = app.activeSprite
if M.Sprite == nil then
   -- Show error, no sprite active.
   local dlg = M.MsgDialog("Error", "No sprite is currently active. Please, open a sprite first and run again.")
   dlg:show()
   return 1
end

if app.fs.filePath(M.Sprite.filename) == "" then
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
   dlg:button{id = "layers", text = "Export layers", onclick = function() dofile(script_dir .. "/export_layers.lua") end}
   dlg:newrow()
   dlg:button{id = "slices", text = "Export slices", onclick = function() dofile(script_dir .. "/export_slices.lua") end}
   dlg:newrow()
   dlg:button{id = "combinations", text = "Export combinations", onclick = function() dofile(script_dir .. "/export_combinations.lua") end}
   dlg:newrow()
   dlg:button{id = "close", text = "Close", onclick = function() dlg:close() end }
   dlg:show()
end

return M
