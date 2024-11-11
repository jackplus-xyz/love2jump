# Changelog

This document tracks significant changes, features, and fixes for each update.

## States Design

### Game States

```mermaid
graph TD
  A[Game Start] --> B[Title Screen]

  B -- No Save File --> C[New Game or Quit]
  B -- Save File Exists --> D[New Game or Load Game or Quit]

  C --> E[New Game]
  C --> F[Quit]
  D --> E[New Game]
  D --> G[Load Game]
  D --> F[Quit]

  E --> H[Landing]
  H --> I[Gameplay]
  G --> I[Gameplay]

  I --> J{Is New Game?}
  J -- New Game --> E
  J -- Load Game --> G
  J -- Save --> F
```

### Player States

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

### Enemy States

```mermaid
stateDiagram-v2
    [*] --> Grounded

    %% Main state transitions
    Grounded --> Hit: hit()
    Grounded --> Chasing : isPlayerInSight()
    Grounded --> Airborne: y_velocity != 0
    Grounded --> Dead: Health <= 0
    Hit --> Grounded: Health > 0
    Hit --> Dead: Health <= 0
    Chasing --> Attack: Distance < AttackRange
    Airborne --> Dead: Health <= 0
    Airborne --> Grounded: Landed
    Attack --> Chasing : Distance > AttackRange
    Attack --> Hit: Received Damage

    %% Grounded compound state
    state Grounded {
        [*] --> Idle
        Idle --> ToTarget: is_patrol
        ToTarget --> AtTarget: Reached Target Point
        AtTarget --> ToStart: Wait Timer Expired
        ToStart --> AtStart: Reached Start Point
        AtStart --> ToTarget: Wait Timer Expired
    }

    %% Chasing compound state
    state Chasing {
        [*] --> ToPlayer
        ToPlayer --> AtPlayer: In Range
        AtPlayer --> ToPlayer: Player Moved

        note right of ToPlayer
            Constantly updates position
            to track player movement
        end note
    }

    %% Attack compound state
    state Attack {
        [*] --> Grounded
    }

    %% Airborne compound state
    state Airborne {
        [*] --> Jumping
        Jumping --> y_velocity > 0
        Falling --> y_velocity < 0
        Landing --> [*]: y_velocity == 0
    }

    %% Dead state (terminal)
    state Dead {
        [*] --> [*]: Entity Removed
    }
```

### Boss(King-Pig) States

```mermaid
stateDiagram-v2
    [*] --> Grounded.Idle
    Grounded.Idle --> Shocked: Player enters level
    Shocked --> Stage1

    state "Stage 1 (Health: 100-75%)" as Stage1 {
        [*] --> Stage1.AtStart
        Stage1.AtStart --> Stage1.SummonMinions: Summon 3 pigs
        Stage1.SummonMinions --> Airborne.ToTarget: All pigs defeated
        Airborne.ToTarget --> Stage1.AtTarget: Jump down to attack player
        Stage1.AtTarget --> Stage1.Attack: Chase and attack for 10 secs
        Stage1.Attack --> Airborne.ToStart: Jump back to platform
        Airborne.ToStart --> Stage1.AtStart
    }

    Stage1 --> Stage2: Health drops to 75%

    state "Stage 2 (Health: 75-25%)" as Stage2 {
        [*] --> Stage2.AtStart
        Stage2.AtStart --> Stage2.SummonMinions: Summon 3 pigs with bombs
        Stage2.SummonMinions --> Airborne.ToTarget: All pigs defeated
        Airborne.ToTarget --> Stage2.AtTarget: Jump down to attack player
        Stage2.AtTarget --> Stage2.Attack: Chase and attack for 10 secs
        Stage2.Attack --> Airborne.ToStart: Jump back to platform
        Airborne.ToStart --> Stage2.AtStart
    }

    Stage2 --> Stage3: Health drops to 25%

    state "Stage 3 (Health: 25-0%)" as Stage3 {
        [*] --> Stage3.Rest
        Stage3.Rest --> Stage3.SummonMinions: Summon 2 pigs with bombs
        Stage3.SummonMinions --> Stage3.ToTarget: All pigs defeated
        Stage3.ToTarget --> Stage3.AtTarget: Jump down to attack player
        Stage3.AtTarget --> Stage3.Attack: Chase and attack
        Stage3.Attack --> Stage3.Rest: Rest for 3 secs
    }

    Stage3 --> [*]: Health reaches 0%
```

## Checkpoints

### 09/20/2024

#### Added

- Implemented camera control for dynamic views
- Created gravity simulation
- Established collision detection:
  - Rectangle visualization for collision zones
  - Debug information for collision and gravity
- Enabled level switching functionality
- Added basic enemy entities

#### Fixed

- Resolved player movement inconsistencies

### 10/04/2024

#### Added

- Defined strategy for player-enemy interaction
- Introduced enemy patrol behaviors
- Created interactive entities: door and chest
- Added basic UI elements, including a health bar
- Integrated background music (BGM)
- Added sound effects (SFX) for attacks
- Developed a scoring system with collectible coins

#### Changed

- Offset animations for health bar updates

#### Fixed

- Corrected enemy animation errors

### 10/11/2024

#### Added

- Designed main game screens: title, landing, and gameplay
- Developed level transition animations
- Defined hitbox logic
- Implemented interactions between player and enemies (attack logic)
- Added interactions for coins and doors

#### Changed

- Updated debugging information for collision handling
- Restructured UI module
- Enhanced gravity calculations

#### Fixed

- Addressed level transition issues
- Resolved `love.graphics.setColor()` interference with animation layers
- Fixed corner tiles rendering bug
- Improved enemy patrol to prevent falling
- Adjusted enemy image `offset_x`
- Corrected enemy animation flipping issues

### 10/18/2024

#### Added

- Added player-enemy interaction (damage logic)
- Implemented knockback effect on enemies

### 10/25/2024

#### Added

- Enabled game state saving and loading
- Preserved entity status across level transitions
- Saved player status across sessions
- Added quit button to main menu

#### Changed

- Made `Enemy` class extendable for future enemy types

### 11/01/2024

#### Added

- Item drops from defeated enemies
- Enemy chases player behaviors
- Enemy attack behaviors
- Enemy shows dialogue before actions
- Player dead state
- Gameover Screen
- Dynamic patrol route adjustments for enemies

#### Changed

- Improved enemy patrol to account for unreachable destinations

#### Fixed

- Resolve door collision issues
- Adjust hitbox logic for consistent enemy collision handling

### 11/08/2024

#### Added

- Invisible door for better level flow control
- Boss fight encounter
- Boss moves: summon minions
- Bomb

#### Changed

- Enemy can jump when it needs to

### 11/15/2024

#### Added

Invisible door for better level flow control
Boss fight encounter
Boss moves: summon minions

- [ ] Power-ups and experience points (EXP)
- [ ] Settings menu for in-game options

#### Changed

- [ ] Enhanced tileset rules

#### Fixed
