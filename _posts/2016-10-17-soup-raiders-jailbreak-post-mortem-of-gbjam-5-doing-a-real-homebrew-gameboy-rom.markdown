---
title: "Soup Raiders: Jailbreak - Post-Mortem of #GBJam 5 doing a real homebrew gameboy rom"
date: 2016-10-17
---

![SoupRaiders.jpg](/images/2016/10/SoupRaiders.jpg)
<!--more-->
Alexis and I participated last week at the GBJam 5. The goal was to create a gameboy-like game, with several rules (taken from <a href="https://itch.io/jam/gbjam-5">https://itch.io/jam/gbjam-5</a>):
<ol>
 	<li>The aim of GBJam is to create a GameBoy themed game</li>
 	<li>All assets must be created during the duration of the Jam</li>
 	<li>Keep in the original GameBoy screen resolution of 160px x 144px</li>
 	<li>Use only 4 colors in your game</li>
</ol>
After one week of hard work, we finally created <a href="https://teamkwakwa.itch.io/soup-raiders-jailbreak">Soup Raiders: Jailbreak</a>, a simple platformer where you play as Black Whiskers, a pirate cat, who has to escape and save White Fur, who is waiting impatiently. Alexis did a nice cover:

![BoxArt.png](/images/2016/10/BoxArt.png)

We had the <a href="https://itch.io/jam/gbjam-5/rate/89426">best score for the gameboy feel</a> category, which is kind of logical, because nothing feels more like a gameboy game than a gameboy game.

I hesitated a long time before taking the decision to create a real gameboy rom. Why so? IT IS EXTREMELY harder than to create a custom PC game with the top limitations. You have way less tools at disposal.

Hopefully, several tools exist to ease up the process, compared to our elders who were programming directly in Assembly. <a href="http://gbdk.sourceforge.net/">GBDK</a> allows modern developers to code in C ( a very limited C, but still C). Unfortunately, it also means that the code will be less optimised than by hand in Assembly. For the sprites, we used <a href="http://www.devrs.com/gb/hmgd/gbtd.html">GBTD</a>, that automatically convert sprites to the correct format for GBDK. For the music, I used a tool called <a href="https://github.com/AntonioND/gbt-player">mod2gbt and gbt-player</a>, the GBDK legacy folder, that seemed to work fine. The only problem for our musician was that he had to use a tracker like OpenMPT, but could not manage to make it run on his Mac. Hopefully, we could manage to make a small soundtrack. For the sounds FX, I had to change the numbers in the register to control them which was a bit trial-and-error process. For big images, like the logo and the title screen, we used <a href="http://www.yvan256.net/projects/gameboy/#gbtk">GBTK</a> that convert BMP and PNG file to asm data that you could use directly in the source code.

Also, on the GameBoy hardware, you don't have the multiplication, the division, and floating-point numbers. So, if you want to implement "physics", you have to think with integers on one byte with values between 0 and 256. Try to implement a jump with that:

![SoupRaiders.jpg](https://img.itch.zone/aW1hZ2UvODk0MjYvNDMxMDY3LmdpZg==/original/YlZzTN.gif)

Actually, it was an easy problem compare to a lot of other issues. I had a timer, each 3rd frame I decreased the y-velocity and then every frame I moved the player character with the velocity. Magic!

One of the most painful implementation was the box collision (that still have some bugs). On a bottom-right angle, you can go through. I let this bug as a speedrun mechanic, as you can directly catch the final key. My implementation was a bit hacky, like most of my code, but I manage to polish around the edges.

At the same time, I had to implement the climbing mechanic on each platform and correct bugs around it. The harder part was to actually make it work when you were climbing and then arrive on a new platform. Here is the climbing result:

![SoupRaiders.jpg](https://img.itch.zone/aW1hZ2UvODk0MjYvNDMxMDY1LmdpZg==/original/zrOxoK.gif)

A main feature of GBDK is to allow to use several ROM banks. You can put images, sounds, functions in other ROM banks, but just before using them, you have to call SWITCH_ROM_MBC1(bank_nmb), so you cannot use at the same time two different non-fixed bank (the main bank is fixed and is always at disposal, though it is quickly full, especially with C code).

For the sprites, in term of hardware, you are allowed distinct 128 sprite tiles and 128 background tiles. from 128 to 256, the tiles Video RAM is shared. Hopefully, you can always change the sprites in memory. In Soup Raiders: Jailbreak, I did not need to clean the tile memory, because we did not have that much assets. But for a bigger project, you have to think about it. You can not change the background in real-time (not in C) and so what I did was as soon as you switch from one part of the level to the other, I turn off the screen, put the new background tilemap and then turn on the display again. Lameboy, the gameboy emulator for Nintendo DS does emulate this feature, so there is always a little bug when you switch screen on it :D For the sprites (the moving part of the game), you have to move each 8x8 tile by hand, so my set_sprite function is quite big, as I needed to move Black Whiskers (16x16), the locked door (2 to 4 bar of 8x8 and 16x16 lock), the key (16x16), the seagull enemies (16x16), White Fur in the first part of the level (16x32). The funniest lag I had was on the first screen of the game. Having a seagull enemy plus White Fur plus the Locked door plus Black Whiskers walking on the ground made it lag BAAAD. The bug is reproduced when Black Whiskers arrives with the final key and walk on the ground.

Each frame, you have to set the sprite tile index of each tile. Depending which object is on the screen, I adapted my code to be dynamic with the sprite index. For example, you can grab a key and then go to an other part of the level where there was no key, so dynamically, the sprite index manager adapts to this new object. Here is an example of moving with a key:

![SoupRaiders.jpg](https://img.itch.zone/aW1hZ2UvODk0MjYvNDMxMDY2LmdpZg==/original/8tv2Qc.gif)

I want to finish this blog post with some negative opinions I have about the GBJam. First, I want to congratulate retroshark for his work to organize this event. It is so pleasant to be able to play after one week su many good games reminding us of where we come from. But, maybe it is my Swiss side, it is very frustrating to have the gamejam announced one week before. It is one reason why I don't want to support the kickstarter. I really don't like this amateurish way of handling the event (especially compared to other online game jams like the Ludum Dare, that is announced months in advance). Second, the rating system is not perfect. The Ludum Dare system with coolness is a good example to be inspired from. I don't know the back-end of itch.io, but it would be nice to have a "fair" system. I rated several more games than I got ratings, so I have this frustrated experience of the voting phase of the GBJam...

To conclude, the GBJam is an awesome creative event that really needs more attention. Creating a game for gameboy is one pain in the ass, but a very rewarding experience. We are very proud to earn the gameboy feel award and we hope to develop the Soup Raiders universe a bit more (more news soon).
