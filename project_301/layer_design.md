# THE MASTER COLLISION MATRIX
+---------------------------+-------------------------+----------------------+------------------------+-----------------------------------------------+
| Node                      | Suggested Type          | Layer (What it is)   | Mask (What it scans)   | Practical Behavior                            |
+---------------------------+-------------------------+----------------------+------------------------+-----------------------------------------------+
| Walls                     | StaticBody2D / TileMap  | 1 (World)            | None                   | Solid structures. Immobile.                   |
+---------------------------+-------------------------+----------------------+------------------------+-----------------------------------------------+
| Small World Things        | StaticBody2D            | 2 (Props)            | None                   | Small obstacles on the floor. Bodies crash    |
|                           |                         |                      |                        | into them, but bullets fly right over them.   |
+---------------------------+-------------------------+----------------------+------------------------+-----------------------------------------------+
| Player Body               | CharacterBody2D         | 3 (Player)           | 1, 2, 4                | Slides against walls (1), hits small props    |
|                           |                         |                      |                        | (2), and bumps into enemy bodies (4).         |
+---------------------------+-------------------------+----------------------+------------------------+-----------------------------------------------+
| Enemy Body                | CharacterBody2D         | 4 (Enemy)            | 1, 2, 3                | Navigates around walls (1), props (2), and    |
|                           |                         |                      |                        | cannot pass through the player (3).           |
+---------------------------+-------------------------+----------------------+------------------------+-----------------------------------------------+
| Player Hurtbox            | Area2D (on Player)      | 5 (Player Hurt)      | 8                      | Active listening zone. Only looks for         |
|                           |                         |                      |                        | incoming Enemy Hitboxes (8) to take damage.   |
+---------------------------+-------------------------+----------------------+------------------------+-----------------------------------------------+
| Enemy Hurtbox             | Area2D (on Enemy)       | 6 (Enemy Hurt)       | None                   | Sitting duck zone. Doesn't scan anything;     |
|                           |                         |                      |                        | just waits to be hit by player weapons.       |
+---------------------------+-------------------------+----------------------+------------------------+-----------------------------------------------+
| Player Bullets / Weapons  | Area2D / RigidBody2D    | 7 (Player Weapon)    | 1, 6                   | Hits walls (1) to pop/disappear, and scans    |
|                           |                         |                      |                        | Enemy Hurtboxes (6) to deal damage.           |
+---------------------------+-------------------------+----------------------+------------------------+-----------------------------------------------+
| Enemy Hitbox              | Area2D (on Enemy)       | 8 (Enemy Attack)     | None                   | The damaging part of an enemy attack. Doesn't |
|                           |                         |                      |                        | scan; just waits for Player Hurtbox to find   |
|                           |                         |                      |                        | it.                                           |
+---------------------------+-------------------------+----------------------+------------------------+-----------------------------------------------+
# KEY STRUCTURAL RULES FOR THIS SETUP
 1. Why separating Hitbox and Hurtbox matters: By putting Player Hurtbox on
   Layer 5 and Enemy Hitbox on Layer 8, your player script doesn't need
   complex "if area.is_in_group('enemy')" filters. If a collision happens
   on that mask, you KNOW it is an enemy attack.
 2. Handling the "Small World Things" (Layer 2): Notice that Player Bullets
   (Layer 7) scan Layer 1 (Walls) but NOT Layer 2 (Props). This perfectly
   achieves the mechanic where projectiles fly safely over low debris,
   bushes, or small rocks while characters still have to walk around them.
 3. Performance Optimization: Projectiles and Hitboxes (Area2D nodes that act
   as pure damage dealers) should have their own Masks completely empty if
   an opposing Hurtbox is already doing the scanning. Only one side needs
   to actively monitor the collision for a signal to fire.
	