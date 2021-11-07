# Gaspi's Aseprite Scripts

Welcome to my collection of Aseprite Scripts. They all aim to save you time
doing specific and repetitive tasks. If you find yourself in this situation, you
can ask me for a commission! Contact below.

## Installation

1. Download or clone this repository.
1. In Aseprite, go to File -> Scripts -> Open Scripts Folder.
1. Copy the content of this repository's script folder into the opened script
   folder.
1. In Aseprite, go to File -> Scripts -> Re-scan Scripts Folder.

## Scripts

Even if some options may look complicated, they are all set in a default value
so that they work straight away. If you're looking for more advanced and
specific ways of export, take a look at them.  

***Note***.- Some of the scripts
may mark the sprite as unsaved after executing. **NO** changes are made to the
sprite if it's not indicated by the script description. However, some of the
trickery involved causes the sprite to appear as modified.

### Export Layers

An easy and fast way of exporting every layer of a sprite into individual sprites.

**Usage:**  

Have your sprite with multiple layers you want to be exported individually.
Execute the script and your layers will export in separate files. Hidden
layers are also exported.

**Options:**  

- *Output directory*: The folder where to export. Note that you will specify a
  file, not a folder. This is because Aseprite's API doesn't support folder
  selection.
- *File name*: The name of every exported file. The possible formatters are:
-- `{spritename}`: The name of the sprite to export.
-- `{layername}`: The name of the layer.
-- `{layergroups}`: The groups the layer is into.
- *Group separator*: The character used to separate the group names in file name.
- *Export format*: File format of exported files.
- *Export scale*: The scale at which to export. The resolution of the file will
  be multiplied by this number. Useful for media sharing.
- *Save sprite*: If checked, the full sprite will be saved in the output
  directory.

**Examples:**
With default options:

- A layer with name `layer1` will be exported as `layer1.png`.
- A layer with name `layer2` inside a group with name `group1` will be exported
  as `group1/layer2.png`.
- A layer with name `layer3` inside a group with name `group2`, which is inside
`group1`, will be exported as `group1/group2/layer3.png`.

### Export Slices

Export a sprite sheet into individual files, each one named and grouped
accordingly. Commissioned by *Imvested* for his Minecraft resource pack.

**Usage:**  

You have to set up your slices in your sprite first. Use the slice tool (alt. to
the move tool) to create slices. Double-click a slice to edit its Name and User
Data values. These values are used for the exported filename. You can use `/`
(Linux/macOS) or `\` (Windows) to nest folders.

**Options:**  

- *Output directory*: The folder where to export. Note that you will specify a
  file, not a folder. This is because Aseprite's API doesn't support folder
  selection.
- *File name*: The name of every exported file. The possible formatters are:
-- `{spritename}`: The name of the sprite to export.
-- `{slicedata}`: The user data of the slice.
-- `{slicename}`: The name of the slice.
- *Export format*: File format of exported files.
- *Export scale*: The scale at which to export. The resolution of the file will
  be multiplied by this number. Useful for media sharing.
- *Save sprite*: If checked, the full sprite will be saved in the output
  directory.

**Examples:**  

- A slice with name `slice1` will be exported as `slice1.png`.
- A slice with name `slice2` and User Data `group1` will be exported as
  `group1/slice2.png`.
- A slice with name `slice3` and User Data `group1/subgroup1` will be exported
  as `group1/subgroup1/slice3.png`.

***Note***.- Examples made for Linux/macOS systems. Replace `/` with `\` for
Windows.  

### Export Combinations

Generate and export every combination of layers inside groups. Only one layer
inside each group will be exported at a time. Commissioned by *AnomuraGame*.

**Usage:**

Keep your layers organized in groups. For every group there is, only one layer
at a time will show in every exported file, and one layer of every other group.
All possible combinations will be exported.

Layers outside groups will be ignored. Nested groups are undefined behaviour.

***Note***.- Large numbers of combinations require a long exporting time. Be
patient!

**Options:**

- *Output directory*: The folder where to export. Note that you will specify a
  file, not a folder. This is because Aseprite's API doesn't support folder
  selection.
- *File name*: The name of every exported file. The possible formatters are:
-- `{spritename}`: The name of the sprite to export.
-- `{combination}`: The combination number.
- *Export format*: File format of exported files.
- *Export scale*: The scale at which to export. The resolution of the file will
  be multiplied by this number. Useful for media sharing.
- *Save sprite*: If checked, the full sprite will be saved in the output
  directory.

**Example:**

- In a sprite with 3 layer groups, and 4 layers inside each group, the script
  will create and export a total of 4x4x4 = 64 combinations.

---

## About me

- Web: [gaspi.games](http://gaspi.games/)
- Twitter: [@_Gaspi](https://twitter.com/@_Gaspi)
- Aseprite Community: [Gaspi](https://community.aseprite.org/u/Gaspi/summary)
