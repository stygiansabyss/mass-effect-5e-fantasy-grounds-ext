Mass Effect 5e Conversion for Fantasy Grounds

# Introduction

This mod only aims to make using fantasy grounds easier for anyone following the Mass Effect conversion rules.  Feel free to submit issues if you notice something is wrong and I will work to fix it as soon as possible.

[Rules Link](https://n7.world)

# Installation

1. Go to the [latest release](https://github.com/stygiansabyss/mass-effect-5e-fantasy-grounds-mod/releases/latest).
2. Download the `mass_effect_5e.mod` file.
3. Do not extract or modify the mod file.  This is the format Fantasy Grounds wants the zip in.  You can look through the contents yourself by just renaming the extension to `.zip`.
4. Put the `.mod` file in `<DRIVE>:\Users\<USER>\AppData\Roaming\SmiteWorks\Fantasy Grounds\modules`.
5. Start up Fantasy grounds and you should see the mod for any DND 5e rules game.
6. Click on Library > Modules > Activation.
7. Find Mass Effect 5e and load it.

# Other things you can do

1. Once in your game, go to options.  Click the currencies button.
    1. Remove all but GP.
    2. Rename GP to Credits.
2. Until I get the extension to do it, the module does not automatically load the new skills onto the character sheet.
	1. For each character sheet, open the Character > Skills window (in the right side menu) and drag the following skills on to the character sheet.
		1. Electronics
		2. Engineering
		3. Science
		4. Vehicle Handling
3. Grab the extension
	1. I am working on an extension to add more of the rules directly into Fantasy Grounds.  You can find it [here on github](https://github.com/stygiansabyss/mass-effect-5e-fantasy-grounds-ext).

# Unique Choices Made

## Shields

Until the extension piece of this handles it better, I have currently elected to use Temp HP for shields.  Its a bit annoying, especially when dealing with shields AND tech armor, but it's the best I have found so far.

## Spells

Spells are added as 3 spells per.  One for the base spell and one for each advancement.  I tried to change the text correctly for the advancements.

For ease of filtering and organizing, I did the following for each spell.

- The `School` is what will use Tech, Biotic, or Combat.
- The `Source` will show what classes can use it.
- The `Components` will be used for Prime and Detonates keywords.

## Conditions

If you look in the spell list, you will notice a source called `Generic`.  This has "spells" I made to make applying certain conditions easier.

- Lifted
	- This contains effects when put on a character sheet that will apply "Primed: Force" and "Restrained" to a target.
- Primers
	- This will contain all available prime options that can be easily applied to a target.
- Shields
	- Currently, this allows you to set a Temporary HP heal to add shields.

## Naming Convetions

In the rules for the Mass Effect conversion, they have done a great job of switching spell to power in their text.  The problem with this is that Fantasy Grounds uses key sentence hunting to do it magic behind the scenes.  So while "Ranged power attack" is correct for the setting, "Ranged spell attack" is used in the power descriptions.

The same is true for GP.  I have not tested to see if setting something to Credits works, so for now all prices are listed in GP.  They are using the credits value though, so you do not need to divide by 100.