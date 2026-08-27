---
layout: post
title:  "Rollback (10/13): Input compression"
categories: [gamedev, cpp]
series: rollback
---

Once the simulation is deterministic, inputs are the only thing you send — and you send them every single tick, for every frame in the window, to every player. So they're worth 24 bytes of thought.

<!--more-->

## Why it matters more than it looks

- You don't send *one* frame of input per packet. You send a window of recent frames, redundantly, so a lost packet doesn't stall the confirm frame (see post 11).
- So the cost is `input size × window size × players × tick rate`. Shaving bytes here is multiplied several times over.

## Splash Online: 24 bytes → 5 bytes

- **Naive version**: 4 floats for the two sticks + 8 bools for the buttons = 24 bytes.
- **Compressed version**: 4 `fixed8` for the sticks + 1 byte of button bitfield = 5 bytes.
- The two wins: fixed-point (post 9) gives you a byte-sized axis for free, and 8 booleans is a `std::uint8_t`, not eight of them.

```cpp
struct PlayerInput
{
    Fixed8 moveX, moveY;
    Fixed8 aimX, aimY;
    std::uint8_t buttons;   // bitfield
};
static_assert(sizeof(PlayerInput) == 5);
```

![Splash Online input compression](/images/2026/rollback/input_compression_splash.png)

## Receiving inputs

- Packet carries a frame index plus a run of inputs, so a client can fill any hole in its history.
- What you do when an input arrives for a frame you already simulated: mark `dirty`, roll back (post 5).
- What you do when it arrives for a frame older than your window: nothing, it's already confirmed.

![Receiving player inputs](/images/2026/rollback/receiving_inputs.png)

## Beach Slap: going below the byte

This is the interesting one — Beach Slap packs harder than Splash Online.

- Start from the actual control scheme and count what's genuinely needed.
- **Buttons vs states**: N independent buttons need N bits, but if the buttons are mutually exclusive, what you're really encoding is a *state*, and M states only need `ceil(log2(M))` bits. Enumerating the reachable states instead of the pressable buttons is where the savings come from.
- Work through the actual numbers from the slide — how many buttons, how many states, how many bits saved.

![Beach Slap input compression](/images/2026/rollback/input_compression_beachslap.png)
![Number of buttons vs number of states](/images/2026/rollback/buttons_vs_states.png)

## Run-length encoding the leftovers

- The 3 bits saved by the state encoding get reused for RLE: how many consecutive frames repeat this same input.
- This works *because* of the same property that makes input prediction work (post 3) — humans hold inputs for many frames at a time. A player holding right for half a second is one input plus a count, not 30 inputs.
- Bounds: max run length that fits in 3 bits, and what happens when the run is longer.

![Run-length encoding](/images/2026/rollback/rle.png)

## Measuring

Show the before/after bandwidth per player per second, and be clear about which of these optimisations actually mattered in practice versus which were fun.
