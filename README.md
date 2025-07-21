# RandomMaze
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
![Top language](https://img.shields.io/github/languages/top/gbegreg/FunMaze)
[![](https://tokei.rs/b1/github/gbegreg/MapReduce?category=code)](https://github.com//gbegreg/FunMaze)
[![](https://tokei.rs/b1/github/gbegreg/MapReduce?category=files)](https://github.com//gbegreg/FunMaze)
![GitHub last commit](https://img.shields.io/github/last-commit/gbegreg/FunMaze)

This project is related to the article that will be included in the September/October 2025 issue of Programmez! magazine (french).
It's a short game in which the player must reach the maze exit before the computer. The player will use the arrow keys to move their piece.
Each time the human player wins, the CPU-controlled piece will move a little faster.
From a coding perspective, we'll see how to:
- generate a random maze (in 2D or 3D) but always with at least one possible solution;
- implement the A* pathfinding algorithm that will allow the CPU to find the path to the exit.

The human player's piece (purple) will be repositioned at the bottom right of the maze each time, and the CPU's piece (green) will be repositioned at the bottom left. The maze and the exit position will be random.

[![FunMaze](https://youtu.be/1MBjJuxV3wM?si=7mU11MSj5OhxCAoQ/0.png)](https://youtu.be/1MBjJuxV3wM?si=7mU11MSj5OhxCAoQ)

(click the image to see the Youtube video)
