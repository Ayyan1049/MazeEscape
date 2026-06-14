# Assignment Requirements — MovingStar (8088 Assembly)

## Overview

Implement a game called **"MovingStar"** in 8088 Assembly Language.

---

## [Initial Screen – 5+10+5+5 Marks]

You have to do the following to initialize the screen:

- **Clear the screen.**
- **Place the obstacles** using the `place_obstacles` subroutine. It will initialize all the Green (`0x2220`) obstacles on the screen as shown in the picture. The full right boundary is also a green obstacle.
- **Place the goal** at the top-left corner of the screen. The goal is a space with a red background (`0x4420`).
- **Place the player**, a blue color asterisk character (`* = 0x2A`) at the center of the last row.

---

## [Game Mechanics – 10+10+5+5 Marks]

- After every **2 timer interrupts**, the player moves one step in the direction of the last pressed arrow key. Initial direction will be **Rightward**.
- Use the **keyboard arrow keys** to move the player in a specific direction.
- If the player **collides with an obstacle or the right-most column**, the game ends with a **"Game Lost"** message.
- If the player **reaches the goal** without touching any obstacle, the game ends with a **"Game Win"** message.

---

## [Safe Termination – 10 Marks]

After the end of the game, other programs should run smoothly on DOSBox.

- Old interrupt vectors (INT 8h and INT 9h) must be saved before hooking and restored before program exit.
- The program must terminate cleanly using `INT 21h / AX=4C00h`.
