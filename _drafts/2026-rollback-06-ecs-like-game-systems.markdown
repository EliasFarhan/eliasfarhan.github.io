---
layout: post
title:  "Rollback (6/13): ECS-like game systems, or how to make your state copyable"
categories: [gamedev, cpp]
series: rollback
---

Every game system needs one method: "go back to this previous state". If your architecture is right, that method is a memcpy. If it isn't, that method is impossible.

<!--more-->

## The requirement

```cpp
class GameSystem
{
public:
    void Tick();
    void Rollback(const GameSystem& previousState);
};
```

- `Rollback` takes the previous state as an argument and restores it.
- It should be a trivial copy of data. If it can't be, that's your architecture telling you something.

## The naive OOP version, and why it fails

- Hard to copy — deep object graphs.
- Hard to serialise.
- Pointers and references to other classes everywhere. A copy gives you aliasing into the old state.
- Player character as a gameplay + physics + graphics + audio object (again — see post 4).
- Avoid polymorphism inside the game systems: a virtual call means a vtable pointer means your "state" isn't plain data anymore.

![Naive OOP architecture](/images/2026/rollback/naive_oop.png)

## The ECS-like version

- **Component**: a C-struct. Data only, maybe a couple of operators and helpers. No behaviour.
- **Entity**: an index identifying components in the component arrays.
- **System**: the process that runs code over a range of components.
- The slogan from the talk: *you want a manager of PlayerCharacter, not a PlayerCharacter script.*
- Contiguous arrays of PODs are the thing that makes `Rollback` a memcpy — and incidentally makes `Tick` fast, which matters because you run it `deltaFrame` times on a rollback.

![ECS-like architecture](/images/2026/rollback/ecs.png)

## Splash Online's game systems

- Screenshot/list of the actual systems from the repo: <https://github.com/EliasFarhan/SplashOnline>
- Show one concrete component + its system, with the `Rollback` implementation.

![Splash Online game systems](/images/2026/rollback/splash_systems.png)

## Beach Slap's game systems

- Second iteration, same principles.
- Note worth keeping from the talk: the `Body` struct is reused by composition across several components — no inheritance.

![Beach Slap game systems](/images/2026/rollback/beachslap_systems.png)

## Practical notes

- What *isn't* in the rollbackable state (View data, caches you can rebuild) and why keeping that list explicit saves you later.
- Every new system added to the game is a new thing that can be forgotten in `Rollback` — this is the #1 source of desyncs in post (13).

## References

- Game Programming Patterns, Robert Nystrom: <https://gameprogrammingpatterns.com/>
