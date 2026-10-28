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
local M = dofile(app.fs.joinPath(script_dir, "main.lua"))
if type(M) ~= "table" then return M end

local active_sprite = M.ActiveSprite
local Sep = M.Sep
local Dirname = M.Dirname
local Basename = M.Basename
local RemoveExtension = M.RemoveExtension
local HideLayers = M.HideLayers
local MsgDialog = M.MsgDialog
local LoadSettings = M.LoadSettings
local SaveSettings = M.SaveSettings

-- Load saved preferences.
local prefs = LoadSettings("export_layers")

-- Variable to keep track of the number of layers exported.
local n_layers = 0


-- Function to calculate the bounding box of the non-transparent pixels in a
-- layer. Returns nil if the layer has no non-transparent pixels.
local function calculateBoundingBox(layer)
    local boundingRect = nil
    for _, cel in ipairs(layer.cels) do
        local image = cel.image
        if not image:isEmpty() then
            -- Shrunken bounds are relative to the image, offset them to sprite
            -- coordinates.
            local bounds = image:shrinkBounds()
            bounds.x = bounds.x + cel.position.x
            bounds.y = bounds.y + cel.position.y
            if boundingRect == nil then
                boundingRect = bounds
            else
                boundingRect = boundingRect:union(bounds)
            end
        end
    end
    return boundingRect
end

-- Exports every layer individually.
-- visibility is the data returned by HideLayers for root_layer, used to know
-- which layers were originally visible.
local function exportLayers(sprite, root_layer, filename, group_sep, data, visibility)
    for i, layer in ipairs(root_layer.layers) do
        local prefix = data.exclusion_prefix or "_"
        -- Skip layer with specified prefix and prefix is not empty
        if data.exclude_prefix and prefix ~= "" and string.sub(layer.name, 1, #prefix) == prefix then
            goto continue
        end
        -- Skip layers that were not originally visible when "only visible" is
        -- set. HideLayers doesn't change groups' visibility.
        if data.only_visible then
            local was_visible
            if layer.isGroup then was_visible = layer.isVisible else was_visible = visibility[i] end
            if not was_visible then goto continue end
        end
        local filename = filename
        if layer.isGroup then
            -- Recursive for groups.
            local previousVisibility = layer.isVisible
            layer.isVisible = true
            filename = filename:gsub("{layergroups}",
                                     layer.name .. group_sep .. "{layergroups}")
            exportLayers(sprite, layer, filename, group_sep, data, visibility[i])
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
                if not boundingRect then
                    -- All-transparent layer, skip.
                    layer.isVisible = false
                    goto continue
                end
                -- make a selection on the active layer
                app.layer = layer;
                sprite.selection = Selection(boundingRect);

                -- create a new sprite from that selection
                app.command.NewSpriteFromSelection()

                -- save it as png
                app.command.SaveFile {
                    ui=false,
                    filename=filename
                }
                app.command.CloseFile()

                app.sprite = layer.sprite  -- Set the active sprite to the current layer's sprite
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
    filename = prefs.directory or Dirname(active_sprite.filename),
    open = false
}
dlg:entry{
    id = "filename",
    label = "File name format:",
    text = prefs.filename or "{layergroups}{layername}"
}
dlg:combobox{
    id = 'format',
    label = 'Export Format:',
    option = prefs.format or 'png',
    options = {'png', 'gif', 'jpg'}
}
dlg:combobox{
    id = 'group_sep',
    label = 'Group separator:',
    option = prefs.group_sep or Sep,
    options = {Sep, '-', '_'}
}
dlg:slider{id = 'scale', label = 'Export Scale:', min = 1, max = 10, value = prefs.scale or 1}
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
dlg:check{id = "only_visible", label = "Only visible layers:", selected = false}
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
                         RemoveExtension(Basename(active_sprite.filename)))
filename = filename:gsub("{groupseparator}", group_sep)

-- Work on a copy so the original sprite is never mutated (no undo entry).
local function performExport()
    local copy = Sprite(active_sprite)
    app.sprite = copy
    copy:resize(copy.width * dlg.data.scale, copy.height * dlg.data.scale)
    local visibility = HideLayers(copy)
    exportLayers(copy, copy, output_path .. filename, group_sep, dlg.data, visibility)
    copy:close()
    app.sprite = active_sprite
end

performExport()

-- Save the original file if specified
if dlg.data.save then active_sprite:saveAs(active_sprite.filename) end

-- Persist settings for next run.
SaveSettings("export_layers", {
    directory = dlg.data.directory,
    filename = dlg.data.filename,
    format = dlg.data.format,
    group_sep = dlg.data.group_sep,
    scale = dlg.data.scale,
})

-- Success dialog.
local dlg = MsgDialog("Success!", "Exported " .. n_layers .. " layers.")
dlg:show()

return 0
