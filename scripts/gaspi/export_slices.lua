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
If the user data field is empty, then no group is asigned
and the slice is exported to the root selected folder.

About:
Made by Gaspi. Commisioned by Imvested.
   - Web: https://gaspi.games/
   - Twitter: @_Gaspi

--]]

-- Auxiliar functions.

-- Source: https://stackoverflow.com/questions/9102126/lua-return-directory-path-from-path
function getPath(str,sep)
    sep=sep or'/'
    return str:match("(.*"..sep..")")
end

--[[ Sources:
  - https://codereview.stackexchange.com/questions/90177/get-file-name-with-extension-and-get-only-extension
  - https://stackoverflow.com/questions/18884396/extracting-filename-only-with-pattern-matching
--]]
function getFileName(str,sep)
   str = str:match("^.+"..sep.."(.+)$")
   return str:match("(.+)%..+")
end


local sprite = app.activeSprite
local og_bounds = sprite.bounds

-- Identify operative system.
local separator
if (string.sub(sprite.filename, 1, 1) == "/") then
   separator = "/"
else
   separator = "\\"
end

-- Ask for export path
local dlg = Dialog("Export slice groups") 
local sprite = app.activeSprite
dlg:file{ id="directory", label="Output directory:", filename=sprite.filename, open=false}
dlg:check{ id="save", label="Save sprite:", selected=false}
dlg:button{ id="ok", text="Ok"}
dlg:button{ id="cancel", text="Cancel"}
dlg:show()

if not dlg.data.ok then
  return
end

local path = getPath(dlg.data.directory, separator)
local filename = getFileName(dlg.data.directory, separator)

-- Count how many times a slice with the same name and group exist.
slice_count = {}
for _, slice in ipairs(sprite.slices) do
  local slice_path = slice.data .. separator .. slice.name
  if slice_count[slice_path] == nil then
    slice_count[slice_path] = 1
  else
    slice_count[slice_path] = slice_count[slice_path] + 1
  end
end

for _, slice in ipairs(sprite.slices) do
  -- Keep track of the origin offset.
  og_bounds.x = og_bounds.x - slice.bounds.x
  og_bounds.y = og_bounds.y - slice.bounds.y

  -- Crop the sprite to this slice.
  sprite:crop(slice.bounds)

  -- Save the cropped sprite.
  local slice_path = slice.data .. separator .. slice.name
  local file_name = path .. separator .. slice_path
  if slice_count[slice_path] ~= 1 then
    file_name = file_name .. "_" .. slice_count[slice_path]
  end
  file_name = file_name .. ".png"
  slice_count[slice_path] = slice_count[slice_path] - 1
  sprite:saveCopyAs(file_name)

end

-- Uncrop.
sprite:crop(og_bounds)

-- Save the original file if specified
if dlg.data.save then
  sprite:saveAs(dlg.data.directory)
end