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

-- Auxiliary functions

-- Path handling.

-- Return the path to the dir containing a file.
-- Source: https://stackoverflow.com/questions/9102126/lua-return-directory-path-from-path
function Dirname(str)
   return str:match("(.*" .. Sep .. ")")
end

-- Return the name of a file given its full path..
-- Source: https://codereview.stackexchange.com/questions/90177/get-file-name-with-extension-and-get-only-extension
function Basename(str)
   return str:match("^.*" .. Sep .. "(.+)$") or str
end

-- Return the name of a file excluding the extension, this being, everything after the dot.
-- Source: https://stackoverflow.com/questions/18884396/extracting-filename-only-with-pattern-matching
function RemoveExtension(str)
   return str:match("(.+)%..+")
end

-- Sprite handling.

-- Hides all layers and sub-layers inside a group, returning a list with all
-- initial states of each layer's visibility.
function HideLayers(sprite)
   local data = {} -- Save visibility status of each layer here.
   for i,layer in ipairs(sprite.layers) do
      if layer.isGroup then
         -- Recursive for groups.
         data[i] = HideLayers(layer)
      else
         data[i] = layer.isVisible
         layer.isVisible = false
      end
   end
   return data
end

-- Restore layers visibility.
function RestoreLayersVisibility(sprite, data)
   for i,layer in ipairs(sprite.layers) do
      if layer.isGroup then
         -- Recursive for groups.
         RestoreLayersVisibility(layer, data[i])
      else
         layer.isVisible = data[i]
      end
   end
end

-- Dialog
function MsgDialog(title, msg)
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

function CopyTable(original)
   local copy = {}
   for i, value in ipairs(original) do
       copy[i] = value
   end
   return copy
end

-- Current sprite.
Sprite = app.activeSprite
if Sprite == nil then
   -- Show error, no sprite active.
   local dlg = MsgDialog("Error", "No sprite is currently active. Please, open a sprite first and run again.")
   dlg:show()
   return 1
end

-- Identify operative system.
Sep = string.sub(Sprite.filename, 1, 1) == "/" and "/" or "\\"

if Dirname(Sprite.filename) == nil then
   -- Error, can't identify OS when the sprite isn't saved somewhere.
   local dlg = MsgDialog("Error", "Current sprite is not associated to a file. Please, save your sprite and run again.")
   dlg:show()
   return 1
end

-- Check if this is being run directly.
if debug.getinfo(2) == nil then
   local dlg = Dialog("Gaspi scripts")
   dlg:label{id = "msg", text = "What can I help you with?"}
   dlg:newrow()
   dlg:button{id = "layers", text = "Export layers", onclick = function() dofile("export_layers.lua") end}
   dlg:newrow()
   dlg:button{id = "slices", text = "Export slices", onclick = function() dofile("export_slices.lua") end}
   dlg:newrow()
   dlg:button{id = "combinations", text = "Export combinations", onclick = function() dofile("export_combinations.lua") end}
   dlg:newrow()
   dlg:button{id = "close", text = "Close", onclick = function() dlg:close() end }
   dlg:show()
end

return 0