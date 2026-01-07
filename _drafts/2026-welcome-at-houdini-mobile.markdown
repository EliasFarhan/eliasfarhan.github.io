---
layout: post
title:  "Welcome at Houdini's - Mobile version"
#date:   2024-12-23 20:19:00 +0200
categories: jekyll update
---

![]()

<!--more-->

## Introduction

A few years ago (2017), [Alexis](https://www.artstation.com/alexis_simonetta) and I made a small game jam game named [Welcome at Houdini's](https://teamkwakwa.itch.io/welcome-to-houdinis) for Level Up Game Jam in Fribourg (I made a small blogpost [here](/2017/02/22/level-up-game-jam-2017.html)). So with the upcoming release of Beach Slap, especially on mobile, I wanted to go through the publishing experience of releasing a game on Android and iOS. Welcome at Houdini's was a perfect match, simple codebase to modernize, simple game that could get rework without too much work. So I contacted Alexis and we agreed to rework on a mobile version of Welcome at Houdini's. Here is the technical article about what was added.

## Pitch

Welcome at Houdini's is a mixing elements game where the player is a alchemist shop keeper and need to generate the items that the customers need. It features a good balance of humor, combinations and quests. The game was planned for PC with a 16:9 screen to be played with the mouse.

## Representing the workshop

![The game screen](https://img.itch.zone/aW1hZ2UvMTIwNzEwLzU1NjM3Mi5wbmc=/original/jOvEB2.png)

## Platform specficis
- Achievements
- Save file
- Login

## Tools

The mixing of elements used to look like this:
```Csharp
public static readonly Dictionary<ElementMix, ElementMixResult> MixMap = new Dictionary<ElementMix, ElementMixResult>()
{
    {
        new ElementMix(ElementType.WATER, ElementType.AIR),
        new ElementMixResult(ElementMixResult.MixResultType.MIX,
            ElementType.RAIN)
    },
    {
        new ElementMix(ElementType.WATER, ElementType.EARTH),
        new ElementMixResult(ElementMixResult.MixResultType.MIX,
            ElementType.CLAY)
    },
    ...
```
While it was fine for a game jam where I could quickly write down the possibilities, it was going to work with Alexis who could interact with Unity with tools, but modify a script (except to add an enum entry in a specific file). Also this Dictionary only lists the combaintions, and it is more intuitive to see the list of combinations that creates a specific element. Using Odin Inspector, I added a tool specifically for this.

![Element tool]()

Same for the quests that used to look like this:
```csharp
 public static readonly List<CharaQuest> Quests = new List<CharaQuest>()
{
    new CharaQuest(
        new ElementType[] {ElementType.CLAY },
        new string[]
        {
            "Hi! I am a standard NPC\nlooking to start a new\nbusiness in pottery",
            "Oh! Nice! Thanks!",
            "I just want clay..."
        },
        0
    ),
    new CharaQuest(
        new ElementType[] {ElementType.STEAM },
        new string[]
        {
            "I feel bad... I need\nto go to the sauna",
            "Awesome!",
            "Sauna... You know...\nIt needs steam..."
        },
        2
    )
```

I translated all that into a specific tool to generate character quest:

![Chara quest tool]()

Of course, tools also needs to store the newly generated data, so I serialized all those data into specific scriptable object, specifically every object that have an image at the end (character, elements) or contains text, all this contained into a GameDataContainer scriptable object.



## Game analytics
Playfab, privacy policy

## Business model
DLC - support the dev

## Narration

If any...


Optimize data

