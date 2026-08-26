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

-- Settings persistence.
-- Stores preferences as a simple JSON file next to the scripts.
-- ponytail: hand-rolled flat JSON for tables with string/number/bool values only.
-- Upgrade path: use a full JSON lib if nested structures are ever needed.

local settings_dir = debug.getinfo(1, "S").source:match("@?(.*)[/\\]")
local settings_file = settings_dir .. app.fs.pathSeparator .. "settings.json"

local function encodeJson(tbl)
   local parts = {}
   for k, v in pairs(tbl) do
      local val
      if type(v) == "string" then
         val = '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
      elseif type(v) == "boolean" then
         val = v and "true" or "false"
      else
         val = tostring(v)
      end
      parts[#parts + 1] = '"' .. k .. '":' .. val
   end
   return "{" .. table.concat(parts, ",") .. "}"
end

local function decodeJson(str)
   -- Minimal parser for flat {key: value} objects.
   local tbl = {}
   for k, v in str:gmatch('"([^"]+)"%s*:%s*(".-[^\\]"|%d+%.?%d*|true|false)') do
      if v == "true" then
         tbl[k] = true
      elseif v == "false" then
         tbl[k] = false
      elseif v:sub(1,1) == '"' then
         tbl[k] = v:sub(2, -2):gsub('\\"', '"'):gsub('\\\\', '\\')
      else
         tbl[k] = tonumber(v)
      end
   end
   return tbl
end

function M.LoadSettings(scope)
   local f = io.open(settings_file, "r")
   if not f then return {} end
   local content = f:read("*a")
   f:close()
   local all = decodeJson(content)
   -- Filter keys by scope prefix.
   if not scope then return all end
   local result = {}
   local prefix = scope .. "."
   for k, v in pairs(all) do
      if k:sub(1, #prefix) == prefix then
         result[k:sub(#prefix + 1)] = v
      end
   end
   return result
end

function M.SaveSettings(scope, data)
   -- Load existing, merge scoped keys, write back.
   local all = M.LoadSettings(nil)
   -- Remove old keys for this scope.
   local prefix = scope .. "."
   for k in pairs(all) do
      if k:sub(1, #prefix) == prefix then
         all[k] = nil
      end
   end
   -- Write new scoped keys.
   for k, v in pairs(data) do
      all[prefix .. k] = v
   end
   local f = io.open(settings_file, "w")
   if f then
      f:write(encodeJson(all))
      f:close()
   end
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
