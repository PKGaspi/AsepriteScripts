--[[

Description:
A script to save all different layers in different files.

Made by Gaspi.
   - Itch.io: https://gaspi.itch.io/
   - Twitter: @_Gaspi
Further Contributors:
    - Levy E ("StoneLabs")
    - David Höchtl ("DavidHoechtl")
    - Demonkiller8973
--]]

-- Import main.
local script_dir = debug.getinfo(1, "S").source:match("@?(.*)[/\\]")
local M = dofile(script_dir .. "/main.lua")
if type(M) ~= "table" then return M end

local Sprite = M.Sprite
local Sep = M.Sep
local Dirname = M.Dirname
local Basename = M.Basename
local RemoveExtension = M.RemoveExtension
local HideLayers = M.HideLayers
local MsgDialog = M.MsgDialog

-- Variable to keep track of the number of layers exported.
local n_layers = 0


-- Function to calculate the bounding box of non-transparent content in a layer.
-- Uses cel.bounds (already tight per-cel) instead of iterating every pixel.
-- ponytail: O(cels) instead of O(width*height*frames). Upgrade path: none needed.
local function calculateBoundingBox(layer)
    local minX, minY, maxX, maxY = nil, nil, nil, nil
    for _, cel in ipairs(layer.cels) do
        local b = cel.bounds
        if not minX or b.x < minX then minX = b.x end
        if not minY or b.y < minY then minY = b.y end
        if not maxX or b.x + b.width > maxX then maxX = b.x + b.width end
        if not maxY or b.y + b.height > maxY then maxY = b.y + b.height end
    end
    if not minX then return nil end
    return Rectangle(minX, minY, maxX - minX, maxY - minY)
end

-- Exports every layer individually.
local function exportLayers(sprite, root_layer, filename, group_sep, data)
    for _, layer in ipairs(root_layer.layers) do
        local prefix = data.exclusion_prefix or "_"
        -- Skip layer with specified prefix and prefix is not empty
        if data.exclude_prefix and prefix ~= "" and string.sub(layer.name, 1, #prefix) == prefix then
            goto continue
        end
        local filename = filename
        if layer.isGroup then
            -- Recursive for groups.
            local previousVisibility = layer.isVisible
            layer.isVisible = true
            filename = filename:gsub("{layergroups}",
                                     layer.name .. group_sep .. "{layergroups}")
            exportLayers(sprite, layer, filename, group_sep, data)
            layer.isVisible = previousVisibility
        else
            -- Ignore reference layers.
            if layer.isReference then
                goto continue
            end

            -- Individual layer. Export it.
            layer.isVisible = true
            filename = filename:gsub("{layergroups}", "")
            filename = filename:gsub("{layername}", layer.name)
            app.fs.makeAllDirectories(Dirname(filename))
            if data.spritesheet then
                local sheettype=SpriteSheetType.HORIZONTAL
                if (data.tagsplit == "To Rows") then
                    sheettype=SpriteSheetType.ROWS
                elseif (data.tagsplit == "To Columns") then
                    sheettype=SpriteSheetType.COLUMNS
                end
                app.command.ExportSpriteSheet{
                    ui=false,
                    askOverwrite=false,
                    type=sheettype,
                    columns=0,
                    rows=0,
                    width=0,
                    height=0,
                    bestFit=false,
                    textureFilename=filename,
                    dataFilename="",
                    dataFormat=SpriteSheetDataFormat.JSON_HASH,
                    borderPadding=0,
                    shapePadding=0,
                    innerPadding=0,
                    trimSprite=data.trimSprite,
                    trim=data.trimCells,
                    trimByGrid=data.trimByGrid,
                    mergeDuplicates=data.mergeDuplicates,
                    extrude=false,
                    openGenerated=false,
                    layer="",
                    tag="",
                    splitLayers=false,
                    splitTags=(data.tagsplit ~= "No"),
                    listLayers=layer,
                    listTags=true,
                    listSlices=true,
                }
            elseif data.trim then -- Trim the layer
                local boundingRect = calculateBoundingBox(layer)
                if not boundingRect then goto continue end -- All-transparent layer, skip.
                -- make a selection on the active layer
                app.activeLayer = layer;
                sprite.selection = Selection(boundingRect);
                
                -- create a new sprite from that selection
                app.command.NewSpriteFromSelection()
                
                -- save it as png
                app.command.SaveFile {
                    ui=false,
                    filename=filename
                }
                app.command.CloseFile()
                
                app.activeSprite = layer.sprite  -- Set the active sprite to the current layer's sprite
                sprite.selection = Selection();
            else
                sprite:saveCopyAs(filename)
            end
            layer.isVisible = false
            n_layers = n_layers + 1
        end
        ::continue::
    end
end

-- Open main dialog.
local dlg = Dialog("Export layers")
dlg:file{
    id = "directory",
    label = "Output directory:",
    filename = Sprite.filename,
    open = false
}
dlg:entry{
    id = "filename",
    label = "File name format:",
    text = "{layergroups}{layername}"
}
dlg:combobox{
    id = 'format',
    label = 'Export Format:',
    option = 'png',
    options = {'png', 'gif', 'jpg'}
}
dlg:combobox{
    id = 'group_sep',
    label = 'Group separator:',
    option = Sep,
    options = {Sep, '-', '_'}
}
dlg:slider{id = 'scale', label = 'Export Scale:', min = 1, max = 10, value = 1}
dlg:check{
    id = "spritesheet",
    label = "Export as spritesheet:",
    selected = false,
    onclick = function()
        -- Hide these options when spritesheet is checked.
        dlg:modify{
            id = "trim",
            visible = not dlg.data.spritesheet
        }
        -- Show these options when spritesheet is checked.
        dlg:modify{
            id = "trimSprite",
            visible = dlg.data.spritesheet
        }
        dlg:modify{
            id = "trimCells",
            visible = dlg.data.spritesheet
        }
        dlg:modify{
            id = "mergeDuplicates",
            visible = dlg.data.spritesheet
        }
        dlg:modify{
            id = "tagsplit",
            visible = dlg.data.spritesheet
        }
    end
}
dlg:check{
    id = "trim",
    label = "Trim:",
    selected = false
}
dlg:check{
    id = "trimSprite",
    label = "  Trim Sprite:",
    selected = false,
    visible = false,
    onclick = function()
        dlg:modify{
            id = "trimByGrid",
            visible = dlg.data.trimSprite or dlg.data.trimCells,
        }
    end
}
dlg:check{
    id = "trimCells",
    label = "  Trim Cells:",
    selected = false,
    visible = false,
    onclick = function()
        dlg:modify{
            id = "trimByGrid",
            visible = dlg.data.trimSprite or dlg.data.trimCells,
        }
    end
}
dlg:check{
    id = "trimByGrid",
    label = "  Trim Grid:",
    selected = false,
    visible = false
}
dlg:combobox{ -- Spritesheet export only option
    id = "tagsplit",
    label = "  Split Tags:",
    visible = false,
    option = 'No',
    options = {'No', 'To Rows', 'To Columns'}
}
dlg:check{ -- Spritesheet export only option
    id = "mergeDuplicates",
    label = "  Merge duplicates:",
    selected = false,
    visible = false
}
dlg:check{
    id = "exclude_prefix",
    label = "Exclude layers with prefix",
    selected = false,
    onclick = function()
        dlg:modify{
            id = "exclusion_prefix",
            visible = dlg.data.exclude_prefix
        }
    end
}
dlg:entry{
    id = "exclusion_prefix",
    label = "  Prefix:",
    text = "_",
    visible = false
}
dlg:check{id = "save", label = "Save sprite:", selected = false}
dlg:button{id = "ok", text = "Export"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

if not dlg.data.ok then return 0 end

-- Get path and filename
local output_path = Dirname(dlg.data.directory)
local filename = dlg.data.filename .. "." .. dlg.data.format

if output_path == nil then
    local dlg = MsgDialog("Error", "No output directory was specified.")
    dlg:show()
    return 1
end

local group_sep = dlg.data.group_sep
filename = filename:gsub("{spritename}",
                         RemoveExtension(Basename(Sprite.filename)))
filename = filename:gsub("{groupseparator}", group_sep)

-- Work on a flat copy so the original sprite is never mutated (no undo entry).
local function performExport()
    local copy = Sprite:duplicate()
    copy:resize(copy.width * dlg.data.scale, copy.height * dlg.data.scale)
    HideLayers(copy)
    exportLayers(copy, copy, output_path .. filename, group_sep, dlg.data)
    copy:close()
end

performExport()

-- Save the original file if specified
if dlg.data.save then Sprite:saveAs(dlg.data.directory) end

-- Success dialog.
local dlg = MsgDialog("Success!", "Exported " .. n_layers .. " layers.")
dlg:show()

return 0
