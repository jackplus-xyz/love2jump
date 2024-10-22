# Love Arcade

## Introduction

"Love Arcade" is a personal project focused on learning the fundamentals of game development. It provides an opportunity to deepen my understanding of game logic with building, deploying, and publishing a playable game. For this project, I'm focusing on implementing game logics and developing a clean and scalable Lua program

Through configuring [Neovim](https://neovim.io/) and [WezTerm](https://wezfurlong.org/wezterm/index.html), I developed an appreciation for Lua's simplicity and flexibility, which is why I chose it for this project. LÖVE, commonly known as Love2D, offers a lightweight yet powerful framework with a supportive community, making it a great choice for 2D game creation.

## Project Overview

**Project Name:** Love Arcade

**Engine:** [LÖVE - Free 2D Game Engine](https://love2d.org/)

**Genre:** 2D Platformer

**Target Platforms:** macOS, Web

## Project Goals

1. Develop a playable 2D platformer game with at least 3 levels + a boss fight
2. Learn and implement game development concepts using Lua and LÖVE
3. UI/UX: Create an engaging playing experience with smooth gameplay and interesting mechanics
4. Performance optimization: Ensure the game run at 60 fps
5. Testing: Create unitests to ensure the game can be built and run successfully without crashing
6. Deployment: deploy the game on Steam/macOS/Web
7. Publication: publish it as a free game on Steam

## Technologies and Tools

- **Programming Language:** Lua
- **Game Engine:** LÖVE (Love2D)
- **Level Editor:** LDTK (Level Designer Toolkit)
- **Libraries:**
  - [HamdyElzanqali/ldtk-love: LDtk loader for LÖVE.](https://github.com/HamdyElzanqali/ldtk-love)
  - [kikito/anim8: An animation library for LÖVE](https://github.com/kikito/anim8)
  - [kikito/bump.lua: A collision detection library for Lua](https://github.com/kikito/bump.lua)
  - [V3X3D/CameraMgr: A highly dynamic and robust camera library in around 200 lines of code.](https://gitlab.com/V3X3D/love-libs/-/tree/master/CameraMgr)
    [thenerdie/Yonder: A ridiculously easy to use game state management library written in Lua, for the LOVE2D framework.](https://github.com/thenerdie/Yonder)

## MVP (Minimum Viable Product) Checklist

### Core Mechanics

- [x] Player movement and physics

  #### Player States

  ```mermaid
  stateDiagram-v2
  [*] --> Grounded
  Grounded --> Airborne : Jump
  Airborne --> Grounded : Land

      state Grounded {
          [*] --> Idle
          Idle --> Moving : Move
          Moving --> Idle : Stop
          Idle --> Attacking : Attack
          Moving --> Attacking : Attack
          Attacking --> Idle : Attack End
      }

      state Airborne {
          [*] --> Jumping
          Jumping --> Falling : Peak
          Jumping --> AirAttacking : Attack
          Falling --> AirAttacking : Attack
      }
  ```

- [x] Collision detection and resolution
- [x] Gravity and jumping
- [x] Camera system
- [x] Basic enemy interaction

### Level Design

- [x] LDTK integration
- [ ] 3 unique levels
- [ ] Boss Fight
- [x] Level transition system

### Gameplay Systems

- [x] Score tracking
- [x] Basic UI (health, score display)
- [ ] Game states (menu, play, pause, game over, load, save)

### Audio

- [x] Basic sound effects
- [x] Background music

## Checkpoints

### 09/20/2024

#### Added

- [x] Camera
- [x] Gravity implementation
- [x] Collision
  - [x] Use rectangle to show collision blocks
  - [x] Add debug info of collision/gravity
- [x] Level switching
- [x] Enemy

#### Fixed

- [x] Player movement

### 10/04/2024

#### Added

- [x] Research strategy for player enemy interaction
- [x] Enemy patrol logic
- [x] Interactive entity: door, chest
- [x] Basic UI elements: health bar
- [x] BGM
- [x] Attacking SFX
- [x] Score system(Coins)

#### Changed

- [x] Offset health animations

#### Fixed

- [x] Fix enemy animation

### 10/11/2024

#### Added

- [x] Game screens (title, landing, playing)
- [x] Level transition animation
- [x] Hitbox
- [x] Interaction between player and enemy(attack)
- [x] Interaction between player and coin
- [x] Interaction between player and door

#### Changed

- [x] Update debugging collision correctly
- [x] Improve UI module structure
- [x] Improve gravity logic

#### Fixed

- [x] Level transitioning
- [x] Animated is overwritten after `love.graphics.setColor()` is called
- [x] Tile on the corner is not drawn correctly
- [x] Improve enemy patrol logic to handle falling
- [x] Enemy image `offset_x` is too high
- [x] Enemy movement animation doesn't flip correctly

### 10/18/2024

#### Added

- [x] Interaction between player and enemy(damage)
- [x] Enemy will be knock back
- [x] Enemy will attack

### 10/25/2024

#### Added

- [ ] Game states(save/load)
  - [ ] Player status
  - [ ] Entities spawning (Coin/Enemy)
- [ ] Enemy drop items
  - [ ] Power-up/EXP
- [ ] Settings menu
- [ ] Quit button
- [ ] Boss Fight

#### Changed

- [ ] Make Enemy class extendable
- [ ] Improve enemy patrol logic to handle unreachable points
- [ ] Improve tileset rules

#### Fixed

- [ ] Door Collision
- [ ] Enemy Collision

## Resources

- [LOVE](https://love2d.org/wiki/Main_Page)
- [Programming in Lua (first edition)](https://www.lua.org/pil/contents.html)
- [Learn Lua in Y Minutes](https://learnxinyminutes.com/docs/lua/)
- [Documentation – LDtk](https://ldtk.io/docs/)
