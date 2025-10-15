# October 15 2025

* Added venting rules
  * New option in options window for Heat Handling
  * When venting is selected, weapons will regenerate 1 heat each round they are not fired.
* Fixed the AoE damage when any of the targets have barrier bug

# October 14 2025

* Added new Defense tab
  * Allows PCs to add their own Barrier
  * Allows PCs to add their own Tech Armor
  * Allows PCs to regen or max out their shields
    * Based on values found in inventory
* Added "Tough Shields" effect
  * When set, character shields do not take double damage from lightning
* Added "Warp Ammo" effect
  * Bypasses barrier, removes 2 ticks.

# Jan 19 2025

* Added Sub Type as a filter for items
* Added language as a filter for NPCs.
* Fixed error with defenses after a 5E update.

# DEC 9 2024

- Fixed a bug with health dice
  - The global for the roll wasn't being set when a roll wasnt a damage roll.  Moved setting the variables higher and it now shows correctly.

# Nov 24 2024

* Fixed a bug with half on save. Changed defenses to plug into messageDamage instead of applyDamage.
* Fixed the issue with messaging about damage when no range was specified on the roll.

# NOV 10 2024

- Added currencies
  - credits
  - omni-gel
- Added creature types
  - This allows for you to set death markers based on faction
- Added unique skills
- Removed unneeded skills
- Changed power cast cycler to use Mass Effect classes instead of DnD classes
- Added Barrier, Tech Armor, and Shields to the combat tracker
- Added automatic defense functionality for the above. They are now handled on their own. All the player/GM has to do is 
add the number to the combat tracker when the defense is activated or regenerated.
  - Will show a status version if that option is selected.