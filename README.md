# Fork from Gaspi's AsepriteScript

Please, take a look at the [repo wiki](https://github.com/PKGaspi/AsepriteScripts/wiki)
to learn more about the scripts.

---

## Additional Feature: Export by Layer and Tag

This fork contains a new script, `export_by_layer_and_tag.lua`, designed to automate the asset pipeline for modular and customizable characters.

### What It Solves

When creating characters with swappable parts (like different hairstyles, clothes, or weapons), many game engines require each part's animation set to be a distinct file. For example, a `Long Sword` layer might need `Attack.png`, `Idle.png`, and `Block.png` files. Manually exporting these combinations is tedious and error-prone. This script automates that entire process.

### How It Works

The "Export Layers by Tag" script iterates through every layer and every tag in your Aseprite file, exporting a unique spritesheet for each combination.

For a file with layers `Hair`, `Body` and tags `Idle`, `Run`, the script will generate:

```
Hair-Idle.png
Hair-Run.png
Body-Idle.png
Body-Run.png
```

This is perfect for workflows involving:

  * **Unity:** Preparing assets for the `SpriteResolver` in the 2D Animation package.
  * **Godot:** Creating separate `SpriteFrames` resources for `AnimatedSprite` nodes.

### Quick Usage Guide

1.  Run the main script (`main.lua`).
2.  In the dialog, click the **"Export Layers by Tag"** button.
3.  Ensure the **"Export each tag as a separate file"** checkbox is checked.
4.  Use the **File name format** field with `{layername}` and `{tag}` to define your naming convention.
5.  Click **Export**.
