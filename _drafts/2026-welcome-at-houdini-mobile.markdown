---
layout: post
title:  "Welcome at Houdini's - Mobile version"
#date:   2024-12-23 20:19:00 +0200
categories: jekyll update
---

![Welcome At Houdini's redesigned]()

<!--more-->

## Introduction

A few years ago (2017), [Alexis](https://www.artstation.com/alexis_simonetta) and I made a small game jam game named [Welcome at Houdini's](https://teamkwakwa.itch.io/welcome-to-houdinis) for Level Up Game Jam in Fribourg (I made a small blogpost [here](/2017/02/22/level-up-game-jam-2017.html)). So with the upcoming release of Beach Slap, especially on mobile, I wanted to go through the publishing experience of releasing a game on Android and iOS. Welcome at Houdini's was a perfect match, simple codebase to modernize, simple game that could get rework without too much work. So I contacted Alexis and we agreed to rework on a mobile version of Welcome at Houdini's. 

I took the opportunity to go to Spelkollektivet for the Winter Holidays end of 2025 to be able to work without worrying about daily life (it is a really nice place). This was my lovely cozy setup during that time:

![Spel]()

## The old version

Welcome at Houdini's is a mixing elements game where the player is a alchemist shop keeper and need to generate the items that the customers need. It features a good balance of humor, combinations and quests. The game was planned for PC with a 16:9 screen to be played with the mouse. 

There were three characters sprites, alternating to ask the player some specific elements. The "quest" were one-shot, no link between, no character arcs. 


## Representing the workshop

![The game screen](https://img.itch.zone/aW1hZ2UvMTIwNzEwLzU1NjM3Mi5wbmc=/original/jOvEB2.png)

The new board now takes most of the screen (horizontally and vertically).

![Version at Spelkollekivet](/images/2026/spel/wah_new_interface.jpg)

Positions of the elements on screen staying where they are even when rotating.

## Online Services



### Login



### Achievements

When finding all elements from a certain category

When finishing the game

### Save file

Saving the current positions of the elements (not a problem as it is rotation agnostic) and the progression.

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

Playfab, privacy policy.

## Business model

DLC - support the dev. 

## Narration

The first version of the game did not feature a story per se. Each character was bringing a one shot quest to solve by combining elements, but no quest was linked narratively with each other. 


## Redesigning the gameplay for mobile

### Game Board 

Unsafe zone

Physical elements.

### Game feel

When hovering over elements with an element on-hand, if there is a possible combination, the element will shake a little and a little sparkle effect will appear. 

When two elements combines, they rotate around the center between them and the new element will appear behind a puff effect. 

When the player discover a new combination, a copy of the new element will go to the scroll icon (which is a button that allow to open the receipt list, listing all the combinations discovered).

## Porting to Google Play

Google Cloud + OAUTH
Increasing build number (a dumb script).

Here is the list of tested devices:
- Samsung Galaxy S24 Ultra
- Samsung Galaxy Tab s5e (on Lineage OS)
- Xiaomi Mi 8 (on Lineage OS)
- Xiaomi Redmi Note 12 4G (on Lineage OS)

## Porting to iOS

By far easier than Android

I really love TestFlight, I simply archive the current build and it is delivered automatically to my testing devices.

Here is the list of tested devices:
- iPad Mini 4
- iPad Air 2
- iPhone SE (2nd gen)

## Continuous Delivery

Windows building the .apk (in debug and release) and Android .aab file for the store. Two .bat scripts:
- One updating the git repositories (main, mobile, android and ios)
- One building the version with Unity CLI arguments.

Mac Mini m4 with Xcode.


## Optimize data

Sprite atlases

## MVC architecture

While not a purist, I tended recently to organize my game in a MVC fashion. This allows clear separation of game data and game view. I even went to the point of creating specific `Model` and `View` game objects.

### Controller

Orientation and Touch are managed in the `Controller` part. 

### Model

Elements, Quests, Receipts game data are managed in the `Model` part. They link to the `Controller` actions 

### View

Everything visual goes in the `View`part. It connects to the `Model` actions to allow clear separations without inheritance.

## Conclusion

