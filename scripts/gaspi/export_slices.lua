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
local err = dofile("main.lua")
if err ~= 0 then return err end


-- Ask for export path
local dlg = Dialog("Export slice groups")
dlg:file{ id="directory", label="Output directory:", filename=Sprite.filename, open=false }
dlg:check{ id="save", label="Save sprite:", selected=false }
dlg:button{ id="ok", text="Ok" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()

if not dlg.data.ok then
  return 0
end

local out_path = Dirname(dlg.data.directory)

-- Save original bounds to restore later.
local og_bounds = Sprite.bounds

-- Count how many times a slice with the same name and group exist.
local slice_count = {}
for _, slice in ipairs(Sprite.slices) do
  local slice_path = slice.data .. Sep .. slice.name
  if slice_count[slice_path] == nil then
    slice_count[slice_path] = 1
  else
    slice_count[slice_path] = slice_count[slice_path] + 1
  end
end

-- Export slices.
for _, slice in ipairs(Sprite.slices) do
  -- Keep track of the origin offset.
  og_bounds.x = og_bounds.x - slice.bounds.x
  og_bounds.y = og_bounds.y - slice.bounds.y

  -- Crop the sprite to this slice's size and position.
  Sprite:crop(slice.bounds)

  -- Save the cropped sprite.
  local slice_path = slice.data .. Sep .. slice.name
  local file_name = out_path .. Sep .. slice_path
  if slice_count[slice_path] > 1 then
    file_name = file_name .. "_" .. slice_count[slice_path]
  end
  file_name = file_name .. ".png"
  slice_count[slice_path] = slice_count[slice_path] - 1
  Sprite:saveCopyAs(file_name)
end

-- Restore original bounds.
Sprite:crop(og_bounds)

-- Save the original file if specified
if dlg.data.save then
  Sprite:saveAs(dlg.data.directory)
end