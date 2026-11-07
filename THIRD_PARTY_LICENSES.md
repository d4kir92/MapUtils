# Third-Party Licenses

## OpenMap

Combat pin handling (`CombatPins` in `mapframe.lua`) is adapted from OpenMap's `OpenMap/Map/Combat.lua`.

Source: https://github.com/openmap-world/openmap

```
MIT License

Copyright (c) 2026 OpenMap contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## QuestieDB / Questie

The quest giver and quest turn-in data (`data/<flavor>/questgivers.lua`) is derived from QuestieDB, which imported its initial data from Questie. The data was converted into a MapUtils layout. This includes the quest objective texts, reputation rewards, follow-up quests and the base quest experience from QuestieDB's QuestXP support tables; the experience scaling follows Questie's `QuestieXP.lua`.

Sources:

- QuestieDB: https://github.com/Questie/QuestieDB
- Questie: https://github.com/Questie/Questie

QuestieDB and Questie content is licensed under the GNU General Public License v3 by the contributors who agreed to it (Muehe, Logon, TheCrux/BreakBB, Drejjmit, Cheeq, TechoHunter, Yttrium and others), see QuestieDB's `LICENSE.md` and https://github.com/Questie/Questie/blob/master/LICENSE.md. Content not covered by that consent is "all rights reserved" by its historic contributors. The Questie name and logo are not covered by any license.

The full text of the GNU General Public License v3 is in `LICENSE`.
