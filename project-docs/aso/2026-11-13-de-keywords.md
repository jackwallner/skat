# German keyword field, 2026-11-13

Scope: `fastlane/metadata/de-DE/keywords.txt` only. Not uploaded; it ships with the next version.

## Why

An ops alert on 2026-11-12 (0 new users in 2 days) led to a look at German search. Nothing in search
changed then (Astro ranks flat, impressions normal), but Astro's daily ranks show the field spends
bytes on terms that bring nothing:

| Term (Astro, de) | Popularity | Rank, Oct 25 to Nov 13 |
| --- | --- | --- |
| skat | 60 | not in top 1000 |
| doppelkopf | 55 | 92-127 (two days at 45) |
| skat kostenlos | 53 | 15-17 |
| skat lernen | 29 | 37-88 |
| skat offline | 24 | 84-127 |
| skat training | 5 | 5 |
| reizen skat | 5 | 6-9 |
| skat für anfänger | 5 | 8-43 |
| skat spiel, skat spielen | 5 | 37-134 |
| skat trainer, skat üben, skatblatt | 5 | 1 |

`skat kostenlos` is the biggest term the app already ranks for, and `kostenlos` was in no indexed
field. `skat offline` sits past 80 with `offline` absent from the German field. The practice rooms
work offline, and the en-US field already uses `offline`.

The Oct 21-31 Apple Ads test (Skat DE PoC) spent $11.86 for 6 installs ($1.98 each) against roughly
$0.25 of revenue per install, so it stays off.

## Field

- Before: `reizen,trumpf,grand,null,drücken,stich,doppelkopf,skatblatt,anfänger,skatregeln,training,quiz`
- After: `kostenlos,offline,reizen,skatblatt,anfänger,skatregeln,training,quiz,karten,spielen` (84 bytes)

Dropped `doppelkopf` (a different game, ranked past 90), and `trumpf`, `grand`, `null`, `drücken`,
`stich` (single game words with no tracked rank; `grand`, `null` and `trump` stay covered by the
en-GB field, which Germany also indexes). `karten` returns now that there is room; the Oct 28 pass
cut it only for length. `spielen` targets `skat spiel` and `skat spielen`.

`doppelkopf` went in on Oct 28 (58f73f4) as a winnable neighbour term; two weeks live it still
ranks past 90. `kartenspiel` stays out: that commit measured it beyond reach (difficulty 68).

## Check

Astro on jmbp2 tracks `skat kostenlos` and `skat offline` daily. Read them two weeks after the
version goes live; revert if `reizen skat` or `skat training` leave the top 10, or `skat für anfänger` stays past 20.
