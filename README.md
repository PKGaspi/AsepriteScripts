# Gaspi's Aseprite Scripts

Welcome to my collection of Aseprite Scripts. They all aim to save you time
doing specific and repetitive tasks. If you find yourself in this situation, you
can ask me for a commission\! Contact below.

Please, take a look at the [repo wiki](https://github.com/PKGaspi/AsepriteScripts/wiki)
to learn more about the scripts.

## Disclaimer

These scripts were last tested on Aseprite version v1.3.8. It happened before that
an Aseprite update broke the functionality of these scripts. Please, backup your work
before use. If a script doesn't work, please report openning an issue.

## Installation

1.  Download or clone this repository.
2.  In Aseprite, go to File -\> Scripts -\> Open Scripts Folder.
3.  Copy the content of this repository's script folder into the opened script
    folder.
4.  In Aseprite, go to File -\> Scripts -\> Re-scan Scripts Folder.

## Scripts

Here is a list with all the current scripts and how to use them:

  - [Export Layers](https://github.com/PKGaspi/AsepriteScripts/wiki/Export-Layers)
  - [Export Slices](https://github.com/PKGaspi/AsepriteScripts/wiki/Export-Slices)
  - [Export Combinations](https://github.com/PKGaspi/AsepriteScripts/wiki/Export-Combinations)
  - Export Layers by Tag *(New in this fork, see below)*

Even if some options may look complicated, they are all set in a default value
so that they work straight away. If you're looking for more advanced and
specific ways of export, take a look at them.

***Note***.- Some of the scripts
may mark the sprite as unsaved after executing. **NO** changes are made to the
sprite if it's not indicated by the script description. However, some of the
trickery involved causes the sprite to appear as modified.

## Features Added in this Fork

### Export Layers by Tag

This fork contains a new script, `export_by_layer_and_tag.lua`, designed to automate the asset pipeline for modular and customizable characters.

#### What It Solves

When creating characters with swappable parts (like different hairstyles or clothes), many game engines require each part's animation set to be a distinct file. For example, a `Long Sword` layer might need `Attack.png`, `Idle.png`, and `Block.png` files. Manually exporting these combinations is tedious and error-prone. This script automates that entire process.

#### How It Works

The **"Export Layers by Tag"** script iterates through every layer and every tag in your Aseprite file, exporting a unique spritesheet for each combination.

For a file with layers `Hair`, `Body` and tags `Idle`, `Run`, the script will generate:

```
Hair-Idle.png
Hair-Run.png
Body-Idle.png
Body-Run.png
```

This is perfect for workflows involving:

  * **Unity:** Preparing assets for the `SpriteResolver` component in the 2D Animation package.
  * **Godot:** Creating separate `SpriteFrames` resources for `AnimatedSprite` nodes.

#### Quick Usage Guide

1.  Run the `main.lua` script (e.g., via `File > Scripts > main`).
2.  In the dialog, click the **"Export Layers by Tag"** button.
3.  Ensure the **"Export each tag as a separate file"** checkbox is checked.
4.  Use the **File name format** field with `{layername}` and `{tag}` to define your naming convention.
5.  Click **Export**.

## About Me
I'm an Indie Game Developer making cool games!

  - Web: [Pedro's Website](http://pedrovilasboas.dev)
  - Twitter: [@pepeups](https://x.com/@pepeups)
  - LinkedIn: [Pedro Vilas Bôas](https://www.linkedin.com/in/pedro-vilas-bôas/)
  
## About Gaspi

Hey, I'm a Computer Science graduate fascinated by the videogame industry.
Here are some of my links:

  - Web: [gaspi.games](http://gaspi.games/)
  - Twitter: [@\_Gaspi](https://twitter.com/@_Gaspi)
  - Aseprite Community: [Gaspi](https://community.aseprite.org/u/Gaspi/summary)
