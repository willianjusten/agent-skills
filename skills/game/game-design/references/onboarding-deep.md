# Onboarding: detail

Read after [onboarding.md](onboarding.md) when a rule doesn't settle the case. Sections follow the rule numbers.

## Contents
- 1 Teach by doing
- 2 The opening cannot lose the run
- 3 One new thing, used three times
- 4 Hints die on use
- 5 Straight to play, fast
- 6 Failure says what to change
- 7 One goal in view
- 8 Returning players skip what they know
- Numbers
- Sources

## 1 Teach by doing

Miyamoto, on New Super Mario Bros. Wii: teach the player in a natural way; Iwata reads the first Goomba as a lesson learned by stamping it by accident [1]. Hodent gives the cognitive version: learning by doing gives context and lasts, while text and voice alone get shallow processing [2].

- Good: an arena shooter opens in an empty room with one slow target.
- Bad: a modal listing every control before the first frame of play.
- Mechanical check: every verb in the brief has a scripted spot in the first 60 s where it is the only sensible move; a bot pressing only the hinted input reaches it.

## 2 The opening cannot lose the run

Hodent advises avoiding punishing states during onboarding, since players who struggle early are less likely to stay [2]. The first mushroom in the Iwata Asks account is safe even when the player is confused [1]. The 20 s and 30 s figures are ours [house].

- Good: wave one is two slow enemies and the player cannot die for 20 s.
- Bad: a fast chaser spawned point-blank on frame one.
- Mechanical check: simulate a player sending no input; assert no game over before 30 s and no damage source before the first scored success.

## 3 One new thing, used three times

Eguchi says elements are introduced one by one, not all at once; Konno recalls Miyamoto's "Use one element three times" [3]. Apple advises teaching one step at a time [4]. Meta's growth guide says most users need about three successful repetitions before an action sticks [7]. Hodent sets three items as the ceiling in learning mode, derived from working-memory limits [2]. Three is a developer and platform heuristic, not a measured optimum.

- Good: enemy A for three waves, then B alone, then both.
- Bad: wave one with three enemy types and a new pickup.
- Mechanical check: build a first-appearance table; fail if two mechanics share a first appearance in one encounter, or fewer than three uses fall between consecutive firsts.

## 4 Hints die on use

Roblox says a visual hint should last only as long as it communicates its intent, work after one showing, and not annoy experienced players. Its playtest example: most players press the button within 10 s, so a highlight at 11 s reaches only stragglers [6]. Hodent grounds this in attention: divided attention reduces learning, so a hint is a reminder at the moment of need [2]. Meta adds that contextual hints should follow brief inactivity at key interactions [7]. Roblox also warns that players skip text prompts [5].

- Good: "Press SPACE to dash" shows after about 10 s without a dash, fades on the first dash, never returns.
- Bad: a permanent controls panel for the whole session.
- Mechanical check: perform the action, assert the hint node is gone; reload with the same stored profile, assert it stays gone; clear storage, assert it returns. The idle delay is a playtest result; 10 s is Roblox's example, not a finding.

## 5 Straight to play, fast

CrazyGames requires that games land new users in gameplay immediately, with at most one click first [12]. Poki's guide says to skip splash screens, title screens and level selects for new players [11]. Apple advises against splash screens, menus and agreements at launch, and delaying rating and push prompts [4]. Roblox tells makers to hold back non-essential instruction [5]. On load time, Poki reports a game kept 50% of players who clicked its thumbnail at a 29.5 s median load and 72% after a rebuild with a 3.7 s median, one game, method not stated [10]. Google, from analytics of about 3,700 mobile sites in 2016, reports 53% of visits likely abandoned past 3 s of load [13]. Hodent's Warframe chart suggests about 80% still playing after one hour [2]. The 5 s and 60 s targets and the second allowed input are ours [house].

- Good: "Press any key to start" that also unlocks audio; difficulty is asked after the first run.
- Bad: splash, logo, settings, character picker and a 30 s story crawl before play.
- Mechanical check: headless test records inputs and ms from load to first accepted input and to first scored event; fail above 2 inputs, 5 s or 60 s. Also record median load on a throttled connection against the 3 s mark.

## 6 Failure says what to change

Meta's recall guidance asks for immediate retry, clear feedback on missed inputs and unlimited practice [7]. In the CHI PLAY study of over 200 reviews plus interviews, players expect to die while learning and complain about imprecise controls and slow loading between deaths, not dying itself [9]. Miyamoto's team tuned level 1-1 from watching play [1]. The 3 s bound is ours [house].

- Good: instant retry with the killer highlighted.
- Bad: a 10 s results screen after the first death.
- Mechanical check: log ms and inputs from death to control in the first session; fail above 3 s or one input. Eyeball that the death frame shows what hit the player.

## 7 One goal in view

Hodent: teach the why, not just the how, because players who grasp the purpose attend more to the method [2]. Roblox and Meta both ask for goals visible in the world or interface [6][8]. The CHI PLAY study finds that without explicit direction players wander, die and feel stupid [9].

- Good: a gate icon at the arena edge.
- Bad: four objective lines and a timer, all new.
- Check: capture screenshots at 10, 30 and 60 s; each shows one objective or landmark.

## 8 Returning players skip what they know

Apple: offer a way to skip tutorials and replay them [4]. Meta: let players skip mastered steps and replay from a menu [8]. Hodent separates memory failures; a recall deficit is fixed by a reminder, and her Fortnite example has a player forgetting a crafting screen within about 20 minutes [2]. One CHI PLAY player quit because they did not know cutscenes were skippable [9]. Roblox: surface a feature untouched in the first two sessions [6]. No source gives a gap length for re-teaching; any threshold is ours [house].

- Good: second visit starts in play at the last difficulty; a "How to play" link in the pause menu.
- Bad: the intro cutscene replays every load.
- Mechanical check: set stored flags, reload, assert hints absent and first input accepted at once; clear storage, assert hints return; set a verb's last-used time past the threshold and assert a one-line reminder shows once.

## Numbers

| Value | What | Source |
| --- | --- | --- |
| 3 | uses per new mechanic; max new items at once | [3][7][2] |
| 10 s | example idle delay before a timed hint | [6] |
| 1 click | most before gameplay | [12] |
| 29.5 s to 3.7 s | median load; 50% to 72% kept | [10] |
| 53% past 3 s | mobile visits likely abandoned | [13] |
| 5 s | load to first input | house |
| 60 s | to first success | house |
| 30 s | no game over in opening | house |
| 3 s | death to control | house |
| 2 | most inputs from load to play | house |

## Sources

1. Iwata Asks: New Super Mario Bros. Wii, Vol. 1 (Miyamoto, Iwata), nintendo.com.
2. Celia Hodent, "The Gamer's Brain, Part 2: UX of Onboarding and Player Engagement", GDC 2016 transcript, celiahodent.com.
3. Iwata Asks: Super Mario Bros. 25th Anniversary, Vol. 3 (Eguchi, Konno), nintendo.com.
4. Apple Developer, "Onboarding for Games".
5. Roblox Creator Docs, "Onboarding".
6. Roblox Creator Docs, "Onboarding techniques".
7. Meta Horizon, "Growth Insights Series: More Best Practices for New User Onboarding".
8. Meta Horizon, "Growth Insights Series: Building Competency in New User Onboarding".
9. Cheung, Zimmermann, Nagappan, "The First Hour Experience", CHI PLAY 2014, Microsoft Research.
10. Poki, "What makes a high-quality browser game".
11. Poki for Developers, "Easy access".
12. CrazyGames Docs, "Gameplay requirements".
13. Google Ad Manager blog, "The need for mobile speed", 2016.
