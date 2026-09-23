# civ_sym_dump

A DFHack Lua script for *Dwarf Fortress* (v50.01 and newer) that instantly harvests and dumps all Entity/Civilization symbols of your world into a clean text file, saving you hours of hunting around in Adventure Mode.

## Features
- Automatically extracts all civilization, entity, and religious symbols across your entire world.
- Exports structured data directly into a readable text file.
- Fast and automated compared to the tedious vanilla method of hunting for engraved armor and items in Adventure Mode.

## Requirements
- *Dwarf Fortress* (v50.01 or later)
- [DFHack](https://github.com/DFHack/dfhack) installed

## Installation
1. Download the script from this repository.
2. Place the script file inside your `\dfhack-config\scripts\` folder.

## Usage
1. Embark in your world (preferably with exposed rock).
2. Smooth a wall or floor tile.
3. Pause the game.
4. Engrave the smoothed tile.
5. Click on the engraved tile, navigate to **Specify Image** -> **Existing Image**, and click on **DFHack**.
   *(Note: This step is necessary because the game doesn't load the symbols into memory until you open the Existing Image window.)*
6. Run the script in the DFHack console:
   ```text
   civ_sym_dump

## Visual Guide
![Guide GIF](https://raw.githubusercontent.com/Favozza/civ_sym_dump/refs/heads/main/Assets/guide.gif)
