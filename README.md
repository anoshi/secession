# secession

Secession is a real-time, single and multi-player combat simulation that operates as a modification to the game [Running With Rifles](http://www.runningwithrifles.com). Each player takes part in skirmishes occurring on various battlefields, and must choose to ally or engage in combat with other players in an effort to establish majority control of key locations in the game world.

### Story
Secession is intended to be adaptable to portray any time or level of technology. This variant has a modern-day or near-future setting in terms of weapon technology, but does not take place on Earth. Instead, a similarly inhabitable planet is used that can be likened more to a gladiatorial ring than to a populated world with its own economy and laws.

Five major corporations - vying for status and the right to provide security services to intergalactic governmental icons and celebrities - use this planet to showcase their staff's abilities and training. Unfortunately, the known universe exists in a time of greed, where one's allegiance is to the highest bidder. Mercenary teams that prove their worth to one corporation are prime candidates for assimilation within another.

There are subtle differences in the training regimes of each of the corporations, however, which may encourage some teams to remain loyal to their employer.

Subjects with existing skills in an associated field will often complete a corporation's training course in a matter of days in their spare time. A mercenary team that has worked for and trained under multiple corporations, while not often held in high regard by their past employers, can hold a decisive advantage over their peers on the battlefield.

### Game Setup
1. Each player chooses a corporation to ally with:
  * `ReflexArq` uses a system that improves the reflexes of its subjects;
  * `BlastCorp` are leaders in the explosives field;
  * `WyreTek` have created an advanced communications network;
  * `ScopeSystems` develops long-range targeting equipment;
  * `LifeCraft` specialises in survival skills and medical procedures.

2. The game server selects a starting map and location for the player based on the selected corporation. 

3. The player spawns as one of the following character types:
  * Medic;
  * Sniper;
  * Heavy Trooper;
  * Light Foot;
  * Communications Technician;
  * Grendier;
  * Demolition Trooper;

Each character type has its own Offense, Defence, and Command ratings, as well as Movement Speed and Special Ability.

3. As players gain skill and complete tasks they can customise their character's role abilities by spending `Resource Points` at an armoury or through death and respawning

## REFACTORING BELOW HERE
### Game Play
1) From the world map, each player selects a "tile" adjacent to his force's front to move his team to. Each tile of the world map has an associated Resource Rating, dependent upon its land type and fortifications. While more than one team may be present on a world tile, the combined Command Rating of units in allied teams may not exceed the Resource Rating of the tile. These, and other statistics of world tiles can be perused while viewing the world map.

2) The view zooms in to show the battlefield. Players may place their units within a designated starting zone and scan the battlefield (under a fog-of-war") by panning the screen around

3) Players queue movements for their units such as run, crawl, cover, hide, attack, or special, and choose a destination for that movement. Individual movements may take more than one tick to complete, but only one movement may be queued per unit.

4) At the conclusion of the tick, movements and any ensuing combat are animated.

5) Steps (3) and (4) are repeated until a battlefield victory condition is met e.g. flag captured, attrition completed, fortifications destroyed, enemy surrendered/retreated.

6) View returns to the world map.

### Selling Points
Secession offers:
* a persistent world in which both casual and hardcore players can coexist;
* a central point around which a community can form;
* multiple modes of play from force to unit level control;
* re-playability through random maps and subtly different skill sets;
* a modular framework for adaptability to current and future trends in graphics and internet gaming.