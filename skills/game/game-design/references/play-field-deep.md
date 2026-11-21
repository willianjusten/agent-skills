# Play field: detail

Read after [play-field.md](play-field.md) when a rule doesn't settle the case. Sections follow the rule numbers.

## Contents
- 1 Nothing covers the player
- 2 Danger reads at a glance
- 3 Readable against the worst background
- 4 Telegraph long enough, and honestly
- 5 Banners have fixed spots
- 6 Noise drops as danger rises
- 7 The next threat is in view
- Numbers
- Sources

## 1 Nothing covers the player

Housemarque's Returnal UX puts critical information at the player's focus point and everything else at the edges, and aims to remove every distraction from second-to-second play [6]. Riot keeps a fixed layer order: background, characters, effects, UI [1]. "Never covered" is the strict form of that.

- Good: explosion bloom and particles render behind the avatar layer; the avatar keeps a hard rim.
- Bad: a centred "WAVE 3" banner sits over the spawn point for two seconds (the orbit-arena miss).
- Mechanical check: project the avatar's screen rect plus 20 px. Fail any frame where a HUD or banner element intersects it, or an effect above 0.3 alpha overlaps it and draws above it. Re-run on a frame with the strongest effect forced on (debug key).

## 2 Danger reads at a glance

Xbox guidance: never rely on colour alone, and pair it with shape, pattern, icon or text; red/green pairs fail for many players [4][5]. Riot puts silhouette first for recognition and says a champion's key feature stays constant [1]. Ikaruga cuts everything to two classes so bullets and ship sort instantly [7].

- Good: hazards spiky and pulsing at about 2 Hz, pickups round and steady; still distinct in greyscale.
- Bad: red hazards and green pickups of the same size and motion; decorative sparks shaped like bullets.
- Mechanical check: greyscale screenshot plus the browser's deuteranopia emulation; keep a table mapping each entity to a style key and test that no non-hazard uses a hazard key.

## 3 Readable against the worst background

Xbox XAG 102: 4.5:1 for standard text and important elements, 3:1 for large, 7:1 for a high-contrast mode. Measure against the lowest-contrast area of a moving background, because play is "in constant visual flux". A white-plus-black double outline survives both light and dark backgrounds [4].

- Good: score in a dark panel at 0.6 alpha over a bloom area, ratio checked against the brightest pixel in the panel.
- Bad: thin white text straight over an additive glow.
- Mechanical check: sample the pixels behind each HUD element across a recorded run, take the worst case, compute the WCAG ratio.

## 4 Telegraph long enough, and honestly

Woods et al. measured simple visual reaction at 231 ms raw, 213 ms after removing display and mouse delay; under 110 ms counts as a false alarm [3]. Real play adds choosing a direction, moving and browser input lag. A practitioner analysis of Dark Souls 3 gives at least 340 ms for a known attack [9]. The 500 and 350 ms defaults are ours [house]: a margin for browser latency on top of those figures. Riot: hitboxes match their effects, and the attention an ability grabs matches its importance; a mismatch is a top source of frustration [1]. Xbox XAG 103: critical cues get a second sense [5].

- Good: a ground circle fills in 600 ms and damages exactly inside it, exactly when full, with a rising whine.
- Bad: a beam that appears and damages on the same frame; a warning ring 30% larger than the hit.
- Mechanical check: log `time_from_first_cue_to_damage` per hazard type and assert the floor (at 60 fps, 500 ms is 30 frames); assert telegraph radius equals damage radius within 2 px; each hazard definition lists two cue channels.

## 5 Banners have fixed spots

Synthesis of Housemarque (peripheral info, no layered pop-ups) [6] and Riot (UI is the top layer, not mixed into the action) [1]. Fixed regions are our rule [house].

- Good: "WAVE 4" slides in at top-centre, about 40 px tall, 1.5 s, on a semi-opaque panel.
- Bad: giant centred text scaling up over the arena while enemies spawn.
- Mechanical check: a test triggers every banner and asserts its rect is inside its declared region and clear of the avatar zone.

## 6 Noise drops as danger rises

Riot: keep noise minimal; flashiness costs clarity in fights, and only big gameplay effects earn loudness [1]. Rocksteady describes many abilities turning the screen into "total chaos" [2]. No source gives a numeric budget, so set one per game and log it [house].

- Good: ambient sparkle drops to a minimum while 40 bullets are active; bullets keep the brightest value.
- Bad: death particles the same colour and size as enemy bullets, mid-wave.
- Mechanical check: log per-frame `cosmetic_particles` and `active_hazards`; fail if the 95th-percentile cosmetic count rises with hazard count in the busiest 5 s.

## 7 The next threat is in view

Follows from rule 4 and the reaction figures [3]: a hazard that enters view 300 ms before contact can't be telegraphed fairly. Off-screen cues: Halo draws an arc from each off-screen object [8]; Xbox shows an outlined directional arrow [4] paired with audio [5].

- Good: a flying game with 1.5 s of forward view at top speed; the camera eases its lead.
- Bad: obstacles spawn at the screen edge 0.3 s from impact.
- Mechanical check: for each hazard, time from entering the viewport to reaching the avatar at max speed is at least the telegraph floor plus 250 ms; an off-screen hazard gets an edge indicator within 100 ms.

## Numbers

| Value | What | Source |
| --- | --- | --- |
| 213-231 ms | simple visual reaction, one expected stimulus | [3] |
| 110 ms | faster than this is a guess | [3] |
| 340 ms | known attack, cue plus hit (practitioner) | [9] |
| 500 / 350 ms | telegraph default for new / learned hazards | house |
| 4.5:1 / 3:1 / 7:1 | contrast: standard / large / high-contrast mode | [4] |
| 150 ms | longest an avatar-owned effect may hide it | house |

## Sources

1. Riot Games, "Clarity in League", dev post. https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/
2. Hinkelbein (Rocksteady), "Attention Overload! Creating Readable VFX for Suicide Squad", GDC 2024, abstract. https://gdcvault.com/play/1034360/Attention-Overload-Creating-Readable-VFX
3. Woods et al., "Factors influencing the latency of simple reaction time", Frontiers in Human Neuroscience, 2015. https://pmc.ncbi.nlm.nih.gov/articles/PMC4374455
4. Microsoft, Xbox Accessibility Guideline 102: Contrast. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102
5. Microsoft, Xbox Accessibility Guideline 103: Additional channels for visual and audio cues. https://learn.microsoft.com/en-gb/gaming/accessibility/xbox-accessibility-guidelines/103
6. PlayStation Blog, "Unpacking Returnal's UX design" (Housemarque). https://blog.playstation.com/?p=348960
7. Koncewicz, "The 1 pixel collision box", Game Developer, 2010. https://gamedeveloper.com/design/the-1-pixel-collision-box
8. Baudisch and Rosenholtz, "Halo: a technique for visualizing off-screen objects", CHI 2003. DOI 10.1145/642611.642695
9. Zhang, "Anatomy of an Enemy Attack in Dark Souls 3", Game Developer blog, 2022 (practitioner). https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3
