Mass Effect 5e Conversion for Fantasy Grounds

# Introduction

This extension only aims to make using fantasy grounds easier for anyone following the Mass Effect conversion rules.  Feel free to submit issues if you notice something is wrong and I will work to fix it as soon as possible.

[Rules Link](https://n7.world)

# Installation

1. Go to the [latest release](https://github.com/stygiansabyss/mass-effect-5e-fantasy-grounds-ext/releases/latest).
2. Download the `Source code (zip)` file.
3. You can either rename it to `Mass_Effect_5e.ext` or just extract it as a folder named `Mass_Effect_5e`.
4. Put the `.ext` or the folder in `<DRIVE>:\Users\<USER>\AppData\Roaming\SmiteWorks\Fantasy Grounds\extensions`.
5. Start up Fantasy grounds and select/create any game using the DND 5e ruleset.
6. Before launching the campaign, select `Feature: Mass Effect 5e` from the extensions list on the right.

# What it does

## Defenses

Defenses have been added to the combat tracker (player and GM).  Currently only the GM can add values to these, but once 
the values are there, it works automatically.  It will go through left to right (Barrier > Tech Armor > Shields).  Barrier 
will automatically roll the d8 for you and subtract it from the damage.  Tech armor just subtracts.  Shields only work on 
ranged attacks and take double damage from lightning.

*GM View*<br />
![gm_combat_tracker](https://github.com/user-attachments/assets/09b4f3ad-d8e4-4954-9bdc-682bdde16ff4)

*Full Defenses*<br />
![full_defense](https://github.com/user-attachments/assets/6a135a24-c93a-4f34-843f-ca8f710069af)

*Handling Lightning*<br />
![shields_blocking_lightning](https://github.com/user-attachments/assets/2edb249e-9119-422a-8c35-e742f5ecded4)

On the player side, it uses the overall game options.  If NPCs are set to status, they will just see a yes or nothing.

*Player View*<br />
![player_combat_tracker](https://github.com/user-attachments/assets/84c89b4f-18ce-409f-937d-9e07b190aad6)

> In future updates I plan to add more around this.  Effects to bypass or otherwise change this behavior are being figured
> out.

## Currencies/Creature Types/Classes/Skills

The base DND 5E data has been modified to match ME5E.  Here are the changes.

* Currency
  * Removed default currencies and replaced them with Credits and Omni-Gel.
* Creature Types
  * Added the factions as creature types.  Until I change NPC data (allowing factions) this was the best I could find.
  * This has the benefit of adding these factions to the death markers screen.
* Changed Skills
  * Removed: Animal Handling, Arcana, Nature, Religion
  * Added: Electronics, Engineering, Science, Vehicle Handling
  * These still exist in the Mod for Fantasy Grounds.  But using this extension will remove the need to mess with them.
* Power Cast Fix
  * Added the Mass effect classes to the cycler when 8 + Ability is chosen

## Reputation

Part of this extension adds Paragon/Renegade sections to the character sheet notes tab.  It does nothing other than give
players a place to store that information currently.

![image](https://github.com/user-attachments/assets/cfa834a0-f5f8-4698-a56f-f95b31bd1d46)

# Being worked on

## Armor

I am working to have armor better match mass effect.  This is a big area as I have a few hopes for it.

- Shields/Shield Regen on body armor and chest pieces.
- Mod section per piece.
- Better inventory management of what pieces you can and can't have on.

## Weapons

- Low-hanging fruit, track heat and set that as max ammo automatically.

## Spell Effect

- Bypassing/changing defense behavior
  - Warp ammo will make this painful.

## Classes

- I want to add proper spell slots for each of the classes.
