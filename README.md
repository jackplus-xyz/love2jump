# Love Arcade

## Project Overview

**Project Name:** Love Arcade

**Engine:** [LÖVE - Free 2D Game Engine](https://love2d.org/)

**Genre:** 2D Platformer

**Target Platforms:** macOS, Web

## Project Goals

1. Develop a playable 2D platformer game with at least 3 levels
2. Learn and implement game development concepts using Lua and LÖVE
3. Create an engaging player experience with smooth gameplay and interesting mechanics
4. Successfully deploy the game on [specify platforms]

## Technologies and Tools

- **Programming Language:** Lua
- **Game Engine:** LÖVE (Love2D)
- **Level Editor:** LDTK (Level Designer Toolkit)
- **Libraries:**
  - [HamdyElzanqali/ldtk-love: LDtk loader for LÖVE.](https://github.com/HamdyElzanqali/ldtk-love)
  - [kikito/anim8: An animation library for LÖVE](https://github.com/kikito/anim8)
  - [kikito/bump.lua: A collision detection library for Lua](https://github.com/kikito/bump.lua)
  - [V3X3D/CameraMgr: A highly dynamic and robust camera library in around 200 lines of code.](https://gitlab.com/V3X3D/love-libs/-/tree/master/CameraMgr)

## Development Progress

### Completed Tasks

1. **Learning:**

   - [x] Lua programming language
   - [x] LÖVE game engine
   - [x] LDTK level editor

2. **Core Systems:**

   - [x] Main game loop with LÖVE
   - [x] Map rendering using `love-ldtk`
   - [x] Player animation system using `anim8`
   - [x] Player state management
   - [x] Debug information display
   - [x] Collision detection and resolution with `bump`
   - [x] Gravity implementation
   - [x] Player movement refinement
   - [x] Camera system

3. **Gameplay Elements:**
   - [x] Basic enemy implementation

### In Progress

- [ ] Level transition system (FIXME)

### Upcoming Tasks

1. **Gameplay Features:**

   - [ ] Power-up system
   - [ ] Interactable entities (doors, chests)
   - [ ] Game state management (load/save/pause)
   - [ ] Score system
   - [ ] Additional enemy types and behaviors

2. **Audio:**

   - [ ] Background music (BGM)
   - [ ] Sound effects (SFX)

3. **Polish and Optimization:**
   - [ ] Performance optimization
   - [ ] UI/UX improvements
   - [ ] Bug fixing and playtesting

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
- [ ] Basic enemy interaction

### Level Design

- [x] LDTK integration
- [ ] 3 unique levels
- [ ] Level transition system

### Gameplay Systems

- [ ] Score tracking
- [ ] Basic UI (health, score display)
- [ ] Game states (menu, play, pause, game over)

### Audio

- [ ] Basic sound effects
- [ ] Background music

## Development Timeline

1. **Week 1-2 09/06: Core Mechanics and Prototyping**

   - [x] Set up development environment
   - [x] Implement basic player movement and physics
   - [x] Create prototype level

2. **Week 3-4 09/20: Level Design and Enemy Implementation**

   - [x] Integrate LDTK for level design
   - [x] Implement basic enemy AI

3. **Week 5-6 10/04: Gameplay Systems and Polish**

   - [x] Implement score system
   - [x] Create basic UI
   - [x] Implement sound effects and background music
   - [ ] Design and create 3 levels
   - [ ] Add game states (menu, pause, game over)

4. **Week 7-8 10/18: Testing and Deployment**
   - [ ] Thorough playtesting and bug fixing
   - [ ] Performance optimization
   - [ ] Prepare for deployment on target platforms

## Checkpoints

### 09/20/2024

- [x] Fix collision
  - [x] Use rectangle to show collision blocks
  - [x] Add debug info of collision/gravity
- [x] Add gravity
- [x] Fix movement
- [x] Implement camera system
- [x] Level changing (FIXME)
- [x] Add one enemy type
- [-] Game states (load/save/pause)
- [-] Score system

### 10/04/2024

- [x] Replace game assets with place holder
- [-] Add interaction between player and enemy(attack, damage)
  - [x] Research strategy for player enemy interaction
  - [-] Implement hitbox
  - [x] Fix enemy animation
    - The enemy entities was in `level_elements` and wasn't updated
  - [x] Add enemy patrol
  - [ ] Add enemy attack
- [x] Add interactive entity(i.e. door, chest)
- [x] Implement basic UI elements
  - [x] Add health bar
  - [x] Offset health animations
- [x] Add SFX to attack
- [x] Add BGM
- [-] Fix level transition system
- [x] Implement power-up system(Coins)
- [x] Score system
- [-] Game states (load/save/pause)

### 10/11/2024

#### Added

- [ ] Game states (landing, playing, paused)
- [ ] Level transition animation
- [ ] Hitbox
- [ ] Interaction between player and enemy(attack, damage)
- [ ] Enemy drop items
- [ ] Settings menu
- [ ] Quit button
- [x] Title menu
- [x] Interaction between player and coin
- [x] Interaction between player and door
- [x] Score system(coins)

#### Changed

- [ ] Improve UI module structure
- [x] Improve gravity logic

#### Fixed

- [x] Level transitioning is working now
- [x] Tile on the corner is not drawn correctly
- [x] Improve enemy patrol logic to handle falling
- [x] Enemy image `offset_x` is too high
- [x] Enemy movement animation doesn't flip correctly

### 10/18/2024

#### Added

- Game states(save/load)

#### Changed

- [ ] Improve enemy patrol logic to handle unreachable points
- [ ] Improve tileset rules

#### Fixed

## Notes and Ideas

- Consider adding a double-jump or wall-jump mechanic for more interesting platforming
- Explore the possibility of adding a simple crafting or upgrade system
- Think about a cohesive art style and theme for the game world

## Resources

- [LOVE](https://love2d.org/wiki/Main_Page)
- [Programming in Lua (first edition)](https://www.lua.org/pil/contents.html)
- [Learn Lua in Y Minutes](https://learnxinyminutes.com/docs/lua/)
- [Documentation – LDtk](https://ldtk.io/docs/)
