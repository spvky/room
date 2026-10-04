8/15/2026 11:31:36 PM
- Collisions (AABB for now, but make the collision api work for multiple solvers)
- Camera move to the current room

8/16/2026 11:20:32 PM
- Went with SAT on the collision, test working, solving is next
- Camera follow right after
- Basic movement
- Rune parsing
- Rune Effects (Start with water)
- Entities (Crates, Chained Boxes)
- At some point room designer will need to be extended to handle decorations and stuff but the logic will be the same

9/26/2026 1:51:52 PM

starting at 3, work list:

- Map Screens
- Teleporters, To specific rooms, have to be of same orientation to work and passing over the thresh hold, could be a reason to moving blocks to store their other locations as a instructions instead of moving to a target, like move in this dir for x seconds and then move back, so that they can seemlessley go through teleporters)
- Metal, New wall type that works as a condiut to power objects, would be a cool reason to add wires/ropes
- Maybe some rune work but maybe not, Fluid sim could be as involved as wires/ ropes

10/4/2026 12:17:09 AM
Next is snapshotting the world when entering a room when getting first stable ground:
- When we touch stable ground we create a new snapshot by creating a copy of the entity manager in memory and storing the player
- if we die, reset to last stable ground and load snapshotted entity manager
- Need to make sure this is fast as it will happen on each room we enter
