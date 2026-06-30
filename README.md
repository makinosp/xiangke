# Xiangke: Three Kingdoms Turn-Based Combat Game

A turn-based combat game inspired by the Romance of the Three Kingdoms, built
with Godot Engine.

![Godot Engine](https://img.shields.io/badge/Godot%20Engine-v4.7-%23478CBF?logo=godot-engine)
![License](https://img.shields.io/badge/License-GPLv3-blue.svg)

## 📖 Overview

Xiangke (相剋) is a turn-based combat game set in the era of the Three Kingdoms.
Players command legendary generals, each with unique abilities based on Yin-Yang
and the Five Elements (陰陽五行) principles. Engage in combat where elemental
affinities and tactical decisions determine victory!

## 📁 Project Structure

```
xiangke/
├── resources/          # Game resources (characters, moves, etc.)
│   ├── characters/     # Character data (.tres files)
│   └── moves/          # Move data (.tres files)
├── scripts/            # Game logic and data handling
│   ├── character_data.gd  # Character data resource
│   ├── move_data.gd       # Move data resource
│   ├── status_effect_data.gd # Status effect definitions
│   ├── type_chart.gd      # Elemental type effectiveness chart
│   └── type_enums.gd      # Shared type definitions and enums
├── systems/            # Core game systems
│   └── data/           # Data loading and validation systems
│       ├── data_loader.gd
│       ├── data_validation_utils.gd
│       └── data_validator.gd
├── autoloads/          # Autoloaded scripts (singletons)
│   └── data_registry.gd   # Central registry for game data
├── project.godot       # Godot project configuration
└── README.md           # This file
```

## 🚀 Getting Started

### Prerequisites

- [Godot Engine 4.3](https://godotengine.org/download) (or later)

### Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/makinosp/xiangke.git
   ```

2. Open the project in Godot Engine:
   - Launch Godot
   - Click "Import"
   - Select the `project.godot` file in the cloned directory

### Running the Game

- Press `F5` in the Godot editor to run the current scene
- Or click the "Play" button in the top-right corner

## 🎯 How to Play

1. Select your general from the roster
2. Choose your moves strategically based on enemy elemental weaknesses
3. Manage your resources (HP, Spirit, etc.) to unleash powerful techniques
4. Defeat all enemy forces to claim victory!

## 🧠 Game Mechanics

### Elemental System (五行 + 陰陽)

- **Wood** (木) 🌳 → **Earth** (土) 🌍 → **Water** (水) 💧 → **Fire** (火) 🔥 →
  **Metal** (金) ⚙️ → **Wood** (木) 🌳 (cycle)
- **Yin** (陰) and **Yang** (陽) are special elements that interact uniquely
- Each element has strengths and weaknesses against others

## 🛠️ Development

### Project Structure

- **Resources**: All game data stored as `.tres` resources in `resources/`
- **Scripts**: Game logic in GDScript under `scripts/` and `systems/`
- **Autoloads**: Global systems like `data_registry.gd` for easy data access

### Adding New Content

1. Create new character/move resources in the appropriate `resources/` folder
2. Update the data registry if needed (`autoloads/data_registry.gd`)
3. Implement any new mechanics in the relevant script files

## 📜 License

This project is licensed under the GNU General Public License v3.0 - see the
[LICENSE](LICENSE) file for details.
