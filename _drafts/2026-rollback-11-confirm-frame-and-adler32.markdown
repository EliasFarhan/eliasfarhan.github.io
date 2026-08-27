---
layout: post
title:  "Rollback (11/13): The confirm frame and the Adler-32 checksum"
categories: [gamedev, cpp]
series: rollback
---

The confirm frame is the anchor everything rewinds to. It carries one extra number — a checksum of the whole game state — and that number is the only thing standing between you and a silently diverged simulation.

<!--more-->

## Starting the game in sync

Before any of this works, all clients have to agree on frame 0.

- **Ping measurement**: one packet at a time, store `t1`, compute the round trip when the answer comes back.
- **Countdown**: value between 7 and 0, encoded in 8 bits — 3 bits for the integer part, 5 bits of fractional precision.
- Clients start their tick loop at the same wall-clock moment, offset by their measured latency.

![Game synchronisation](/images/2026/rollback/game_sync.png)

## The master tick

- One client (or the server) is the master. It's the one that decides a frame is confirmed.
- Master waits until it holds every player's real inputs for frame N, simulates it, and publishes the confirm frame.
- Discuss the alternative (fully peer-to-peer confirmation) and why a master is simpler.

![Server / master tick](/images/2026/rollback/master_tick.png)

## The confirm frame

- Contents: frame index, the confirmed inputs of all players for that frame, and the checksum of the resulting state.
- It's simultaneously an ACK (post: the reliable data transfer draft — frame id is a sequence number, confirm frame is an ACK) and a synchronisation point.
- Every client receiving it: rolls back to it if needed, and drops all stored state older than it. That's what bounds the memory of the whole system.

![Confirm frame](/images/2026/rollback/confirm_frame.png)

## The checksum

- Purpose: prove that two machines that ran the same inputs got the same state.
- Computed over the whole rollbackable game state, at the confirm frame, on every client.
- If mine disagrees with the master's, the simulation has diverged and the game is over — see post (13).

![Checksum](/images/2026/rollback/checksum.png)

## Why Adler-32 and not a naive sum

- A naive additive checksum has terrible collision behaviour and concentrates information in the low bits — two states differing by a swap produce the same value.
- Adler-32 keeps two running sums (`a` = sum of bytes, `b` = sum of the running `a`), which makes it order-sensitive and spreads the information across all 32 bits.
- Cheap enough to run every confirm frame, which CRC-32 or a real hash arguably isn't at this frequency.
- Show the implementation.

```cpp
std::uint32_t Adler32(std::span<const std::byte> data)
{
    constexpr std::uint32_t modAdler = 65521;
    std::uint32_t a = 1, b = 0;
    for (auto byte : data)
    {
        a = (a + std::to_integer<std::uint32_t>(byte)) % modAdler;
        b = (b + a) % modAdler;
    }
    return (b << 16) | a;
}
```

![Adler-32](/images/2026/rollback/adler32.png)

- Caveat to state explicitly: a checksum tells you *that* you diverged, never *where*. Post (13) is about turning "that" into "where".

## References

- Overwatch Gameplay Architecture and Netcode, Timothy Ford, GDC 2017: <https://gdcvault.com/play/1024001/-Overwatch-Gameplay-Architecture-and>
