# Love2Jump

## Introduction

"Love2Jump" is a personal project focused on learning the fundamentals of game development. It provides an opportunity to deepen my understanding of game logic with building, deploying, and publishing a playable game. For this project, I'm focusing on implementing game logics and developing a clean and scalable Lua program

Through configuring [Neovim](https://neovim.io/) and [WezTerm](https://wezfurlong.org/wezterm/index.html), I developed an appreciation for Lua's simplicity and flexibility, which is why I chose it for this project. LÖVE, commonly known as Love2D, offers a lightweight yet powerful framework with a supportive community, making it a great choice for 2D game creation.

## Project Overview

**Project Name:** Love2Jump

**Engine:** [LÖVE - Free 2D Game Engine](https://love2d.org/)

**Genre:** 2D Platformer

**Target Platforms:** macOS

## Project Goals

1. Develop a playable 2D platformer game with at least 3 levels + a boss fight
2. Learn and implement game development concepts using Lua and LÖVE
3. UI/UX: Create an engaging playing experience with smooth gameplay and interesting mechanics
4. Performance optimization: Ensure the game run at 60 fps
5. Testing: Create unitests to ensure the game can be built and run successfully without crashing
6. Deployment: deploy the game on Steam/macOS/Web
7. Publication: publish it as a free game on Steam
8. Ship by 1/31

## Technologies and Tools

- **Programming Language:** Lua
- **Game Engine:** LÖVE (Love2D)
- **Level Editor:** LDTK (Level Designer Toolkit)
- **Libraries:**
  - [HamdyElzanqali/ldtk-love: LDtk loader for LÖVE.](https://github.com/HamdyElzanqali/ldtk-love)
  - [kikito/anim8: An animation library for LÖVE](https://github.com/kikito/anim8)
  - [kikito/bump.lua: A collision detection library for Lua](https://github.com/kikito/bump.lua)
  - [V3X3D/CameraMgr: A highly dynamic and robust camera library in around 200 lines of code.](https://gitlab.com/V3X3D/love-libs/-/tree/master/CameraMgr)
  - [thenerdie/Yonder: A ridiculously easy to use game state management library written in Lua, for the LOVE2D framework.](https://github.com/thenerdie/Yonder)

## MVP (Minimum Viable Product) Checklist

### Core Mechanics

- [x] Player movement and physics
- [x] Collision detection and resolution
- [x] Gravity and jumping
- [x] Camera system
- [x] Basic enemy interaction

### Level Design

- [x] LDTK integration
- [x] 3 unique levels
- [x] Boss Fight
- [x] Level transition system

### Gameplay State Management

- [x] Score tracking
- [x] Basic UI (health, score display)
- [x] Game states (menu, play, pause, game over, load, save)

### Audio

- [x] Basic sound effects
- [x] Background music

### Distribution

- [ ] Release a macOS Application

## Resources

- [LOVE](https://love2d.org/wiki/Main_Page)
- [Programming in Lua (first edition)](https://www.lua.org/pil/contents.html)
- [Learn Lua in Y Minutes](https://learnxinyminutes.com/docs/lua/)
- [Documentation – LDtk](https://ldtk.io/docs/)
