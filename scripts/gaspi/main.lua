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

-- Check if this is being run directly.
if debug.getinfo(2) == nil then
   print("Don't run this directly!")
   return
end

-- Identify current sprite.
Sprite = app.activeSprite
if Sprite == nil then
   -- Show error, no sprite active.
   local dlg = Dialog("Error")
   dlg:label{
      id = 0,
      text = "No sprite is currently active. Please, open a sprite first and run again."
   }
   dlg:newrow()
   dlg:button{id = 1, text = "Close", onclick = function() dlg:close() end}
   dlg:show()
   return 1
end
-- Identify operative system.
Sep = string.sub(app.activeSprite.filename, 1, 1) == "/" and "/" or "\\"


-- Auxiliary functions

-- Path handling.

-- Return the path to the dir containing a file.
-- Source: https://stackoverflow.com/questions/9102126/lua-return-directory-path-from-path
function Dirname(str)
   return str:match("(.*" .. Sep .. ")")
end

-- Return the name of a file given its full path.
--[[
   Sources:
   - https://codereview.stackexchange.com/questions/90177/get-file-name-with-extension-and-get-only-extension
   - https://stackoverflow.com/questions/18884396/extracting-filename-only-with-pattern-matching
--]]
function Basename(str)
   str = str:match("^.+" .. Sep .. "(.+)$")
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

return 0