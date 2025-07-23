--[[
Description:
A script to save all different layers in different files, with an option
to further split each layer's export into separate files for each tag.

Based on the original script by Gaspi.
Extended to support per-tag file splitting.

Made by Pedro Vilas Bôas.
   - Itch.io: https://pedrovilasboas.itch.io/
   - Twitter: @pepeups

   Further Contributors:
    - Gaspi ("_Gaspi")
    - Levy E ("StoneLabs")
    - David Höchtl ("DavidHoechtl")
    - Demonkiller8973
--]]

-- Import main.
local err = dofile("main.lua")
if err ~= 0 then return err end

-- Variable to keep track of the number of files exported.
local n_files_exported = 0

-- Exports every layer individually, with an option to split by tag.
local function exportByLayerAndTag(sprite, root_layer, filename_template, group_sep, data)
    for _, layer in ipairs(root_layer.layers) do
        local current_filename_template = filename_template
        if layer.isGroup then
            -- Recursive for groups.
            local previousVisibility = layer.isVisible
            layer.isVisible = true
            current_filename_template = current_filename_template:gsub("{layergroups}",
                                           layer.name .. group_sep .. "{layergroups}")
            exportByLayerAndTag(sprite, layer, current_filename_template, group_sep, data)
            layer.isVisible = previousVisibility
        else
            -- Individual layer. Export it.
            layer.isVisible = true
            current_filename_template = current_filename_template:gsub("{layergroups}", "")
            current_filename_template = current_filename_template:gsub("{layername}", layer.name)

            if data.splitByTagFile and #sprite.tags > 0 then
                -- [ Tags Logic ] Iterate through each tag and export a file for it.
                for _, tag in ipairs(sprite.tags) do
                    local final_filename = current_filename_template:gsub("{tag}", tag.name)
                    os.execute("mkdir \"" .. Dirname(final_filename) .. "\"")

                    app.command.ExportSpriteSheet{
                        ui = false,
                        askOverwrite = false,
                        type = SpriteSheetType.HORIZONTAL, -- Or ROWS, COLUMNS as per your preference
                        textureFilename = final_filename,
                        dataFilename = "", -- No JSON data for this simple export
                        borderPadding = 0,
                        shapePadding = 0,
                        innerPadding = 0,
                        trimSprite = data.trimSprite,
                        trim = data.trimCells,
                        trimByGrid = data.trimByGrid,
                        layer = layer.name, -- Export only the current layer
                        tag = tag.name,     -- Export only the current tag
                        splitLayers = false, -- Handling layers manually
                        splitTags = false    -- Handling tags manually
                    }
                    n_files_exported = n_files_exported + 1
                end
            else
                -- ## Export the whole layer as one file.
                local final_filename = current_filename_template:gsub("{tag}", "") -- Remove tag placeholder if not used
                os.execute("mkdir \"" .. Dirname(final_filename) .. "\"")
                app.command.ExportSpriteSheet{
                    ui=false,
                    askOverwrite=false,
                    type=SpriteSheetType.ROWS, -- Default to rows for non-tag-split
                    textureFilename = final_filename,
                    dataFilename = RemoveExtension(final_filename) .. ".json", -- Also export JSON data
                    dataFormat = "json-hash",
                    borderPadding = 0,
                    shapePadding = 0,
                    innerPadding = 0,
                    trimSprite = data.trimSprite,
                    trim = data.trimCells,
                    trimByGrid = data.trimByGrid,
                    layer = layer.name, -- Export only the current layer
                    splitLayers = false,
                    splitTags = (data.tagsplit ~= "No") -- Use original tag splitting logic here if needed
                }
                n_files_exported = n_files_exported + 1
            end

            layer.isVisible = false
        end
    end
end


-- ############
-- ## DIALOG ##
-- ############

local dlg = Dialog("Pepeups - Export by Layer and Tag")
dlg:file{
    id = "directory",
    label = "Output directory:",
    filename = Sprite.filename,
    open = false
}
dlg:entry{
    id = "filename",
    label = "File name format:",
    text = "{layergroups}{layername}-{tag}" -- Added {tag}
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
dlg:separator()

-- ## TAGS OPTION ##
dlg:check{
    id = "splitByTagFile",
    label = "Export each tag as a separate file",
    selected = true,
    onclick = function()
        -- Toggle visibility of conflicting options
        dlg:modify{ id = "tagsplit", visible = not dlg.data.splitByTagFile }
        local new_filename_text = dlg.data.filename
        if dlg.data.splitByTagFile then
            if not new_filename_text:find("{tag}") then
                new_filename_text = new_filename_text .. "-{tag}"
            end
        else
            new_filename_text = new_filename_text:gsub("-{tag}", ""):gsub("{tag}", "")
        end
        dlg:modify{id = "filename", text = new_filename_text}
    end
}

dlg:separator()
-- Options for spritesheet trimming
dlg:check{ id = "trimSprite", label = "Trim Sprite:", selected = false }
dlg:check{ id = "trimCells", label = "Trim Cells:", selected = false }
dlg:check{ id = "trimByGrid", label = "Trim By Grid:", selected = false }

-- This option is for layout, conflicts with splitting by file
dlg:combobox{
    id = "tagsplit",
    label = "Split Tags (Layout):",
    visible = false, -- Hide by default since "splitByTagFile" is true
    option = 'No',
    options = {'No', 'To Rows', 'To Columns'}
}

dlg:check{id = "save", label = "Save sprite:", selected = false}
dlg:button{id = "ok", text = "Export"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

if not dlg.data.ok then return 0 end

-- ####################
-- ## EXECUTION LOGIC ##
-- ####################

-- Get path and filename
local output_path = Dirname(dlg.data.directory)
local filename_template = dlg.data.filename .. "." .. dlg.data.format

if output_path == nil then
    local err_dlg = MsgDialog("Error", "No output directory was specified.")
    err_dlg:show()
    return 1
end

local group_sep = dlg.data.group_sep
filename_template = filename_template:gsub("{spritename}", RemoveExtension(Basename(Sprite.filename)))
filename_template = filename_template:gsub("{groupseparator}", group_sep)

-- Perform everything.
Sprite:resize(Sprite.width * dlg.data.scale, Sprite.height * dlg.data.scale)
local layers_visibility_data = HideLayers(Sprite)

exportByLayerAndTag(Sprite, Sprite, output_path .. filename_template, group_sep, dlg.data)

RestoreLayersVisibility(Sprite, layers_visibility_data)
Sprite:resize(Sprite.width / dlg.data.scale, Sprite.height / dlg.data.scale)

-- Save the original file if specified
if dlg.data.save then Sprite:saveAs(dlg.data.directory) end

-- Success dialog.
local success_dlg = MsgDialog("Success!", "Exported " .. n_files_exported .. " files.")
success_dlg:show()

return 0