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

-- Import main to ensure helper functions are available,
-- allowing this script to be run standalone or as a module.
local err = dofile("main.lua")
if err ~= 0 then return err end

-- Variable to keep track of the number of files exported
local n_files_exported = 0

-- Helper function to recursively get a flat list of all non-group layers
local function getAllLayers(root, group_path, display_path, layers_list)
    group_path = group_path or ""
    display_path = display_path or ""
    layers_list = layers_list or {}

    for i = #root.layers, 1, -1 do
        local layer = root.layers[i]
        if layer.isGroup then
            local next_group_path = layer.name .. "{groupseparator}" .. group_path
            local next_display_path = layer.name .. " > " .. display_path
            getAllLayers(layer, next_group_path, next_display_path, layers_list)
        else
            table.insert(layers_list, {
                layer = layer,
                displayName = display_path .. layer.name,
                groupPath = group_path
            })
        end
    end
    return layers_list
end

-- Centralized function to perform the export command for a single, visible layer
local function performExportForLayer(sprite, layer, final_filename_template, data)
    if data.splitByTagFile and #sprite.tags > 0 then
        for _, tag in ipairs(sprite.tags) do
            local final_filename = final_filename_template:gsub("{tag}", tag.name)
            os.execute("mkdir \"" .. Dirname(final_filename) .. "\"")

            app.command.ExportSpriteSheet{
                ui = false, askOverwrite = false, type = SpriteSheetType.HORIZONTAL,
                textureFilename = final_filename, dataFilename = "",
                borderPadding = 0, shapePadding = 0, innerPadding = 0,
                trimSprite = data.trimSprite, trim = data.trimCells, trimByGrid = data.trimByGrid,
                layer = layer.name, tag = tag.name,
                splitLayers = false, splitTags = false
            }
            n_files_exported = n_files_exported + 1
        end
    else
        local final_filename = final_filename_template:gsub("{tag}", "")
        os.execute("mkdir \"" .. Dirname(final_filename) .. "\"")
        app.command.ExportSpriteSheet{
            ui=false, askOverwrite=false, type=SpriteSheetType.ROWS,
            textureFilename = final_filename, dataFilename = RemoveExtension(final_filename) .. ".json",
            dataFormat = "json-hash", borderPadding = 0, shapePadding = 0, innerPadding = 0,
            trimSprite = data.trimSprite, trim = data.trimCells, trimByGrid = data.trimByGrid,
            layer = layer.name, splitLayers = false,
            splitTags = (data.tagsplit ~= "No")
        }
        n_files_exported = n_files_exported + 1
    end
end

-- Processes and exports layers based on the user's selection
local function processAndExportLayers(sprite, filename_template, group_sep, data, flat_layers)
    for i, item in ipairs(flat_layers) do
        local should_export = (data.exportMode == "All Layers") or data["export_layer_" .. i]
        
        if should_export then
            local layer = item.layer
            layer.isVisible = true
            
            local current_filename_template = filename_template
            current_filename_template = current_filename_template:gsub("{layergroups}", item.groupPath)
            current_filename_template = current_filename_template:gsub("{groupseparator}", group_sep)
            current_filename_template = current_filename_template:gsub("{layername}", layer.name)
            
            performExportForLayer(sprite, layer, current_filename_template, data)
            
            layer.isVisible = false
        end
    end
end


-- ############
-- ## DIALOG ##
-- ############

-- First, get a flat list of all layers to build the UI
local flat_layers = getAllLayers(Sprite)
local dlg = Dialog("Pepeups - Export by Layer and Tag")

dlg:combobox{
    id = "exportMode",
    label = "Export:",
    options = {"All Layers", "Selected Layers"},
    selected = "All Layers",
    onchange = function()
        -- Modify visibility of all checkboxes, the label and separator line
        local is_selection_mode = (dlg.data.exportMode == "Selected Layers")
        dlg:modify{id="layerSelectionSeparator", visible = is_selection_mode}
        dlg:modify{id="layerSelectionLabel", visible = is_selection_mode}
        for i=1, #flat_layers do
            dlg:modify{id="export_layer_" .. i, visible = is_selection_mode}
        end
    end
}
dlg:separator()

dlg:file{ id = "directory", label = "Output directory:", filename = Sprite.filename, open = false }
dlg:entry{ id = "filename", label = "File name format:", text = "{layergroups}{layername}-{tag}" }
dlg:combobox{ id = 'format', label = 'Export Format:', option = 'png', options = {'png', 'gif', 'jpg'} }
dlg:combobox{ id = 'group_sep', label = 'Group separator:', option = Sep, options = {Sep, '-', '_'} }
dlg:slider{id = 'scale', label = 'Export Scale:', min = 1, max = 10, value = 1}
dlg:separator()

dlg:check{
    id = "splitByTagFile",
    label = "Export each tag as a separate file",
    selected = true,
    onclick = function()
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
dlg:check{ id = "trimSprite", label = "Trim Sprite:", selected = false }
dlg:check{ id = "trimCells", label = "Trim Cells:", selected = false }
dlg:check{ id = "trimByGrid", label = "Trim By Grid:", selected = false }

dlg:combobox{
    id = "tagsplit",
    label = "Split Tags (Layout):",
    visible = false,
    option = 'No',
    options = {'No', 'To Rows', 'To Columns'}
}

-- Use a label instead of a section
dlg:separator{id="layerSelectionSeparator", visible=false}
dlg:label{id = "layerSelectionLabel", text = "Select Layers to Export:", visible = false}

for i, item in ipairs(flat_layers) do
    dlg:check{
        id = "export_layer_" .. i,
        text = item.displayName,
        selected = true,
        visible = false -- Start hidden, will be shown by the combobox onchange event
    }
    if i % 3 == 0 then -- New row every 3 layers
        dlg:newrow()
    end
end

dlg:separator()
dlg:check{id = "save", label = "Save sprite:", selected = false}
dlg:button{id = "ok", text = "Export"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

if not dlg.data.ok then return 0 end

-- ####################
-- ## EXECUTION LOGIC ##
-- ####################

local output_path = Dirname(dlg.data.directory)
if output_path == nil then
    local err_dlg = MsgDialog("Error", "No output directory was specified.")
    err_dlg:show()
    return 1
end

local filename_template = dlg.data.filename .. "." .. dlg.data.format
local group_sep = dlg.data.group_sep
filename_template = filename_template:gsub("{spritename}", RemoveExtension(Basename(Sprite.filename)))

-- Perform everything!
Sprite:resize(Sprite.width * dlg.data.scale, Sprite.height * dlg.data.scale)
local layers_visibility_data = HideLayers(Sprite)

processAndExportLayers(Sprite, output_path .. filename_template, group_sep, dlg.data, flat_layers)

RestoreLayersVisibility(Sprite, layers_visibility_data)
Sprite:resize(Sprite.width / dlg.data.scale, Sprite.height / dlg.data.scale)

-- Save Sprite
if dlg.data.save then Sprite:saveAs(dlg.data.directory) end

-- Success Dialogue
local success_dlg = MsgDialog("Success!", "Exported " .. n_files_exported .. " files.")
success_dlg:show()

return 0
