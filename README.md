# Gaspi's Aseprite Scripts

Welcome to my collection of Aseprite Scripts. They all aim to save you time doing specific and repetitive tasks. If you find yourself in this situation, you can ask me for a commission! Contact below.

## Installation

1. Download or clone this repository.
1. In Aseprite, go to File -> Scripts -> Open Scripts Folder.
1. Copy the content of this repository's script folder into the opened script folder.
1. In Aseprite, go to File -> Scripts -> Re-scan Scripts Folder.

## Scripts

### Export Layers

An easy and fast way of exporting every layer of a sprite into individual sprites.

**Usage:**  

Separate your sprite in layers. Please, save your sprite in a `.ase` or
`.aseprite` file before running the script. The name of the layer will be the
name of the exported file of that layer. The exported `.png` files will be
exported in a directory where the original sprite is, with the same name as this
one. If the sprite has multiple frames, these are exported all as `.png` files
with a `_#` suffix, being `#` the frame number.

**Examples:**

- A layer with name `layer1` will be exported to `sprite_name/layer1.png`.
- A layer with name `layer2` inside a group with name `group1` will be exported to `sprite_name/group1_layer2.png`.

### Export Slices

Export a sprite sheet into individual files, each one named and grouped
accordingly. Commissioned by *Imvested* for his Minecraft resource pack.

**Usage:**  

You have to set up your slices in your sprite first. Use the slice tool (alt. to
the move tool) to create slices. Double-click a slice to edit its Name and User
Data values. The Name of the slice will be the name of the file, and the User
Data will be the folder the file will be saved to. You can use `/` (Linux/macOS)
or `\` (Windows) to nest groups inside groups.

**Options:**  

- *Output directory*: The folder where to export. Note that you will specify a
  file, not a folder. This is because Aseprite's API doesn't support folder
  selection.
- *Save sprite*: If checked, the full sprite will be saved in the output
  directory.

**Examples:**  

- A slice with name `slice1` will be exported to `slice1.png`.
- A slice with name `slice2` and User Data `group1` will be exported to `group1/slice2.png`.
- A slice with name `slice3` and User Data `group1/subgroup1` will be exported to `group1/subgroup1/slice3.png`.

***Note***.- Examples made for Linux/macOS systems. Replace `/` with `\` for Windows.  

### Export Combinations

Generate and export every combination of layers inside groups. Only one layer
inside each group will be exported at a time. Commissioned by *AnomuraGame*.

**Usage:**

Keep your layers organized in groups. For every group there is, only one layer
at a time will be exported, with one layer of every other group. All possible
combinations will be exported.

Layers outside groups will be ignored. Nested groups are undefined behaviour.

***Note***.- Large numbers of combinations require a long exporting time. Be patient!

**Options:**

- *Output directory*: The folder where to export. Note that you will specify a
  file, not a folder. This is because Aseprite's API doesn't support folder
  selection.
- *Export format*: File format of exported files. `.gif` exports supports
  animated exports.
- *Export scale*: The scale at which to export. The resolution of the file will
  be multiplied by this number. Useful for media sharing.
- *Save sprite*: If checked, the full sprite will be saved in the output
  directory.

**Example:**

- In a sprite with 3 layer groups, and 4 layers inside each group, the script will
create and export a total of 4x4x4 = 64 combinations.

---

## About me

- Web: [gaspi.games](http://gaspi.games/)
- Twitter: [@_Gaspi](https://twitter.com/@_Gaspi)
- Aseprite Community: [Gaspi](https://community.aseprite.org/u/Gaspi/summary)
