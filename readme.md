
# Bob in the Candyland — Navigation demo

This repository contains the source code for a videogame where **Bob the triceratops** must **escape a procedurally generated maze**. Through it, multiple Bat enemies pursue him using an advanced navigation pipeline.

## Gameplay overview

- **Objective:** find a viable path through the maze and escape.
- **Threat:** **bats** actively pursue Bob, applying continuous pressure and forcing movement and rerouting. Thanks to the navigation pipeline, they find a path efficiently while adapting to environment changes.
- **Replayability:** the maze generation changes the navigation constraints every run.

## Navigation pipeline

Enemy pursuit is driven by a 2D navigation pipeline designed to cope with a changing maze. It uses a sampling-based global planner with local reactive navigation, which allow the enemies to traverse the environment dynamically without any hand-crafted mesh nor automatic baking. A detailed development of the pipeline can be found in the Report folder.

Main features:

- **Navigation without nav-meshes** 
- **Dynamic replanning**
- **Real-time performance with dozens of concurrent agents** 
- **Custom RTT\***
- **Discretized nearness-diagram**
