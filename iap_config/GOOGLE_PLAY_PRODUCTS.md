# Google Play IAP — Nest Story

Package: `com.NestStoryMNG.NestStory`

Remote config: `https://api2.blwsmartware.net/N322.json`  
If JSON field `disable` is `1`, hide Google Play purchase popups. Shop stays open for coin unlocks.

## Consumable coin packs (buy many times)

| Product ID | Coins |
| --- | --- |
| `ns_pack_1` | 50 |
| `ns_pack_2` | 100 |
| `ns_pack_3` | 200 |
| `ns_pack_4` | 350 |
| `ns_pack_5` | 500 |
| `ns_pack_6` | 750 |
| `ns_pack_7` | 1000 |
| `ns_pack_8` | 1500 |
| `ns_pack_9` | 2200 |
| `ns_pack_10` | 3000 |

## One-time

| Product ID | Unlock |
| --- | --- |
| `ns_remove_ads` | Hide the banner |
| `ns_pro` | More than 8 items |

Create these IDs in Play Console → Monetize → In-app products. Coin packs must be **consumable**. Remove ads and Pro must be **non-consumable**.
