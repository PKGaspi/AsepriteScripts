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

local active_sprite = M.active_sprite
local sep = M.sep
local dirname = M.dirname
local basename = M.basename
local remove_extension = M.remove_extension
local hide_layers = M.hide_layers
local replace_placeholder = M.replace_placeholder
local save_sprite_copy = M.save_sprite_copy
local msg_dialog = M.msg_dialog
local load_settings = M.load_settings
local save_settings = M.save_settings

-- Load saved preferences.
local prefs = load_settings("export_layers")

-- Variable to keep track of the number of layers exported.
local n_layers = 0


-- Function to calculate the bounding box of the non-transparent pixels in a
-- layer. Returns nil if the layer has no non-transparent pixels.
local function calculate_bounding_box(layer)
    local bounding_rect = nil
    for _, cel in ipairs(layer.cels) do
        local image = cel.image
        if not image:isEmpty() then
            -- Shrunken bounds are relative to the image, offset them to sprite
            -- coordinates.
            local bounds = image:shrinkBounds()
            bounds.x = bounds.x + cel.position.x
            bounds.y = bounds.y + cel.position.y
            if bounding_rect == nil then
                bounding_rect = bounds
            else
                bounding_rect = bounding_rect:union(bounds)
            end
        end
    end
    return bounding_rect
end

-- Exports every layer individually.
-- visibility is the data returned by hide_layers for root_layer, used to know
-- which layers were originally visible.
local function export_layers(sprite, root_layer, filename, group_sep, data, visibility)
    for i, layer in ipairs(root_layer.layers) do
        local prefix = data.exclusion_prefix or "_"
        -- Skip layer with specified prefix and prefix is not empty
        if data.exclude_prefix and prefix ~= "" and string.sub(layer.name, 1, #prefix) == prefix then
            goto continue
        end
        -- Skip layers that were not originally visible when "only visible" is
        -- set. hide_layers doesn't change groups' visibility.
        if data.only_visible then
            local was_visible
            if layer.isGroup then was_visible = layer.isVisible else was_visible = visibility[i] end
            if not was_visible then goto continue end
        end
        local filename = filename
        if layer.isGroup then
            -- Recursive for groups.
            local previous_visibility = layer.isVisible
            layer.isVisible = true
            filename = replace_placeholder(filename, "{layergroups}",
                                           layer.name .. group_sep .. "{layergroups}")
            export_layers(sprite, layer, filename, group_sep, data, visibility[i])
            layer.isVisible = previous_visibility
        else
            -- Ignore reference layers.
            if layer.isReference then
                goto continue
            end

            -- Individual layer. Export it.
            layer.isVisible = true
            filename = replace_placeholder(filename, "{layergroups}", "")
            filename = replace_placeholder(filename, "{layername}", layer.name)
            app.fs.makeAllDirectories(dirname(filename))
            if data.spritesheet then
                local sheet_type=SpriteSheetType.HORIZONTAL
                if (data.tag_split == "To Rows") then
                    sheet_type=SpriteSheetType.ROWS
                elseif (data.tag_split == "To Columns") then
                    sheet_type=SpriteSheetType.COLUMNS
                end
                app.command.ExportSpriteSheet{
                    ui=false,
                    askOverwrite=false,
                    type=sheet_type,
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
                    trimSprite=data.trim_sprite,
                    trim=data.trim_cells,
                    trimByGrid=data.trim_by_grid,
                    mergeDuplicates=data.merge_duplicates,
                    extrude=false,
                    openGenerated=false,
                    layer="",
                    tag="",
                    splitLayers=false,
                    splitTags=(data.tag_split ~= "No"),
                    listLayers=layer,
                    listTags=true,
                    listSlices=true,
                }
            elseif data.trim then -- Trim the layer
                local bounding_rect = calculate_bounding_box(layer)
                if not bounding_rect then
                    -- All-transparent layer, skip.
                    layer.isVisible = false
                    goto continue
                end
                -- make a selection on the active layer
                app.layer = layer
                sprite.selection = Selection(bounding_rect)

                -- create a new sprite from that selection
                app.command.NewSpriteFromSelection()

                -- save it as png
                app.command.SaveFile {
                    ui=false,
                    filename=filename
                }
                app.command.CloseFile()

                app.sprite = layer.sprite  -- Set the active sprite to the current layer's sprite
                sprite.selection = Selection()
            else
                save_sprite_copy(sprite, filename)
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
    filename = prefs.directory or dirname(active_sprite.filename),
    open = false
}
dlg:entry{
    id = "filename",
    label = "File name format:",
    text = prefs.filename or "{layergroups}{layername}"
}
dlg:combobox{
    id = "format",
    label = "Export Format:",
    option = prefs.format or "png",
    options = {"png", "gif", "jpg"}
}
dlg:combobox{
    id = "group_sep",
    label = "Group separator:",
    option = prefs.group_sep or sep,
    options = {sep, "-", "_"}
}
dlg:slider{id = "scale", label = "Export Scale:", min = 1, max = 10, value = prefs.scale or 1}
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
            id = "trim_sprite",
            visible = dlg.data.spritesheet
        }
        dlg:modify{
            id = "trim_cells",
            visible = dlg.data.spritesheet
        }
        dlg:modify{
            id = "merge_duplicates",
            visible = dlg.data.spritesheet
        }
        dlg:modify{
            id = "tag_split",
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
    id = "trim_sprite",
    label = "  Trim Sprite:",
    selected = false,
    visible = false,
    onclick = function()
        dlg:modify{
            id = "trim_by_grid",
            visible = dlg.data.trim_sprite or dlg.data.trim_cells,
        }
    end
}
dlg:check{
    id = "trim_cells",
    label = "  Trim Cells:",
    selected = false,
    visible = false,
    onclick = function()
        dlg:modify{
            id = "trim_by_grid",
            visible = dlg.data.trim_sprite or dlg.data.trim_cells,
        }
    end
}
dlg:check{
    id = "trim_by_grid",
    label = "  Trim Grid:",
    selected = false,
    visible = false
}
dlg:combobox{ -- Spritesheet export only option
    id = "tag_split",
    label = "  Split Tags:",
    visible = false,
    option = "No",
    options = {"No", "To Rows", "To Columns"}
}
dlg:check{ -- Spritesheet export only option
    id = "merge_duplicates",
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
local output_path = dirname(dlg.data.directory)
local filename = dlg.data.filename .. "." .. dlg.data.format

if output_path == nil then
    local msg_dlg = msg_dialog("Error", "No output directory was specified.")
    msg_dlg:show()
    return 1
end

local group_sep = dlg.data.group_sep
filename = replace_placeholder(filename, "{spritename}",
                               remove_extension(basename(active_sprite.filename)))
filename = replace_placeholder(filename, "{groupseparator}", group_sep)

-- Work on a copy so the original sprite is never mutated (no undo entry).
local function perform_export()
    local copy = Sprite(active_sprite)
    app.sprite = copy
    copy:resize(copy.width * dlg.data.scale, copy.height * dlg.data.scale)
    local visibility = hide_layers(copy)
    export_layers(copy, copy, output_path .. filename, group_sep, dlg.data, visibility)
    copy:close()
    app.sprite = active_sprite
end

perform_export()

-- Save the original file if specified
if dlg.data.save then active_sprite:saveAs(active_sprite.filename) end

-- Persist settings for next run.
save_settings("export_layers", {
    directory = dlg.data.directory,
    filename = dlg.data.filename,
    format = dlg.data.format,
    group_sep = dlg.data.group_sep,
    scale = dlg.data.scale,
})

-- Success dialog.
local msg_dlg = msg_dialog("Success!", "Exported " .. n_layers .. " layers.")
msg_dlg:show()

return 0
