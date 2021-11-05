--[[

Description:
A script to save all different layers in different .png files.

Made by Gaspi.
   - Itch.io: https://gaspi.itch.io/
   - Twitter: @_Gaspi
--]]

-- Import main.
local err = dofile("main.lua")
if err ~= 0 then return err end

-- Exports every layer individually.
local function exportLayers(sprite, rootLayer, pathPrefix, pathSufix)
   for _, layer in ipairs(rootLayer.layers) do
      if layer.isGroup then
         -- Recursive for groups.
         exportLayers(sprite, layer, pathPrefix .. "_" .. layer.name, pathSufix)
      else
         -- Individual layer. Export it.
         layer.isVisible = true
         local layerName = "_" .. string.lower(layer.name)
         sprite:saveCopyAs(pathPrefix .. layerName .. pathSufix .. ".png")
         layer.isVisible = false
      end
   end
end

-- Add a '_' to the filename if it has multiple frames. The frame number is
-- added automatically.
local suffix = #Sprite.frames > 1 and "_" or ""

-- Finally, perform everything.
local layerVisibilityData = HideLayers(Sprite)
exportLayers(Sprite, Sprite, Dirname(Sprite.filename) .. Basename(Sprite.filename), suffix)
RestoreLayersVisibility(Sprite, layerVisibilityData)
