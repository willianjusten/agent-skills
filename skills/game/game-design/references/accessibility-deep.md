# Accessibility: detail

Read after [accessibility.md](accessibility.md) when a rule doesn't settle the case. Sections follow the rule numbers.

## Contents
- 1 One saved settings screen
- 2 Pause works anywhere
- 3 Colour never carries meaning alone
- 4 Cap flashes
- 5 Shake and motion are adjustable
- 6 Text has a floor
- 7 Input is remappable and forgiving
- 8 Assists change during play
- Numbers
- Sources

## 1 One saved settings screen

The Game Accessibility Guidelines (GAG) list separate volume for effects, speech and music, and settings that are saved and remembered, as basic items [7][9]. Browsers block audio before a gesture, so the first input doubles as the audio unlock; show the mute control from the first screen [house].

- Good: three gain nodes (music, effects, master), sliders write to storage on change, applied before the first frame.
- Bad: volume resets on game over; settings live only in a pause menu that the title screen lacks.
- Mechanical check: set every option, reload, assert equality; run once with storage throwing and assert no crash.

## 2 Pause works anywhere

GAG asks that precise timing not be essential, with pause or skip as the alternative [8]. Xbox XAG 107 suggests a game speed option and caps long presses [14]. Pausing on lost focus is our addition [house].

- Good: Esc pauses on the title, in play, on death and mid-intro; audio ducks.
- Bad: Esc does nothing during a transition, and a hidden tab keeps the run going.
- Mechanical check: dispatch the pause key in every state and assert dt is zero; fire `visibilitychange` and assert paused.

## 3 Colour never carries meaning alone

GAG says no essential information by a fixed colour alone; a whole-palette filter is a blunt fix, and orange against blue works across the common types [3]. XAG 103 asks for a second channel (shape, pattern, icon, text) and says simulation does not replace real colour-blind testers [13]. Danger-specific rules: play-field.md rule 2.

- Good: damaging tiles get a hatch and a warning icon; rarity tiers carry a symbol.
- Bad: green go and red stop squares that differ only in hue.
- Mechanical check: apply deuteranopia, protanopia and tritanopia simulation to a screenshot; name each class by shape.

## 4 Cap flashes

WCAG defines a general flash as a pair of opposing changes of 10% or more of maximum luminance, with the darker state under 0.80 relative luminance; more than 3 per second fails, red counted separately. The area allowance is about a quarter of a 10-degree field, roughly 341 x 256 CSS px [10]. GAG states the screen version: over 3 flashes a second across 25% of the screen, or a sequence over 5 s, and lists stripe patterns (over 8 static or 5 moving) as triggers [2]. The stricter WCAG area is the safe reading. GAG says to name a toggle by what it does (screen flash effects), never "epilepsy safe" [2]. The luminance counter is our proposal, not a certified method [house].

- Good: one 120 ms hit pulse, then a 500 ms cooldown.
- Bad: muzzle flash that inverts the screen every frame; full-screen scanline filter.
- Mechanical check: log mean canvas luminance per frame in the worst effect, count opposing swings of 10% per rolling 1000 ms; fail above 3.

## 5 Shake and motion are adjustable

XAG 117 asks for options to reduce or remove camera shake, motion blur and full-screen effects, ideally as separate 0 to 100% sliders [15]. GAG warns about sudden unexpected movement [5]. WCAG 2.3.3 wants interaction-triggered motion switchable and names the media query as a technique [11]; its values are `no-preference` and `reduce` [16]. Defaulting shake to low under reduce, and the slider's role, are our placement [house]. No source gives a safe shake amplitude or frequency; keep any cap [house].

- Good: `shake(amount * settings.shake)` with the slider at 0 giving offset 0; hits still read through sound.
- Bad: hardcoded `camera.shake(20)` on every hit.
- Mechanical check: unit-test zero offset at 0; emulate reduce in devtools and confirm no parallax, shake or looping background runs.

## 6 Text has a floor

GAG gives 28 px at 1080p as a minimum for living-room screens, not a target [4]. XAG 101 gives at least 18 px at 1080p on PC (36 px at 4K), scaling to 200%, and measuring from highest ascender to lowest descender [12]. Scale canvas fonts by `devicePixelRatio` and a settings multiplier [house].

- Good: 20 px HUD default with a 100 to 200% setting.
- Bad: 11 px grey HUD text, or a tutorial baked into a texture.
- Mechanical check: read rendered text height in CSS px at 1920 x 1080 and compare to the floor.

## 7 Input is remappable and forgiving

GAG lists remapping as basic and alternatives to held buttons as intermediate [1][6]. XAG 107: no essential path gestures, multi-touch or simultaneous presses, activation on release for pointer buttons, long presses under 3 s, touch targets of 15 mm, sensitivity adjustable by at least 50% [14]. A one-handed preset is a binding table, cheap if built first [house].

- Good: an action table; hints read labels from it; a hold-to-run setting turns it into a toggle.
- Bad: key codes hardcoded in handlers; a 3 s hold to open each door.
- Mechanical check: a Playwright run completes menu, play and game over by keyboard alone; remap one key, assert the old key is unbound and hints update; one press under toggle persists until the second.

## 8 Assists change during play

GAG: a range of difficulty levels, changeable in play, is the target; precise timing needs an alternative [1][8]. Which assists fit is per game; speed and extra health are cheapest [house].

- Good: pause menu offers 80% speed and extra lives; the change shows next frame.
- Bad: difficulty chosen once at the title and locked.
- Check: toggle mid-run and confirm the effect without a restart.

## Numbers

| Value | What | Source |
| --- | --- | --- |
| 3 per second | flash ceiling, general and red separately | [10] |
| 10% / 0.80 | flash luminance swing / darker-state ceiling | [10] |
| 341 x 256 px | flash area allowance at 1024 x 768 | [10] |
| 8 static / 5 moving | stripe trigger counts | [2] |
| 18 px / 28 px | text floor at 1080p, PC / living room | [12][4] |
| 200% | text scaling | [12] |
| 15 mm | touch target | [14] |
| 3 s | longest hold | [14] |
| 8 to 10% | males with red or green difficulty | [3] |
| 120 / 500 ms | hit pulse / cooldown | house |

## Sources

1. Game Accessibility Guidelines, full list. https://gameaccessibilityguidelines.com/full-list/
2. GAG, avoid flickering images and repetitive patterns. https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/
3. GAG, no essential information by colour alone. https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-fixed-colour-alone/
4. GAG, readable default font size. https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/
5. GAG, avoid sudden unexpected movement. https://gameaccessibilityguidelines.com/avoid-any-sudden-unexpected-movement-or-events/
6. GAG, alternatives to held buttons. https://gameaccessibilityguidelines.com/avoid-provide-alternatives-to-requiring-buttons-to-be-held-down/
7. GAG, separate volume controls. https://gameaccessibilityguidelines.com/provide-separate-volume-controls-or-mutes-for-effects-speech-and-background-music/
8. GAG, precise timing not essential. https://gameaccessibilityguidelines.com/do-not-make-precise-timing-essential-to-gameplay-offer-alternatives-actions-that-can-be-carried-out-while-paused-or-a-skip-mechanism/
9. GAG, settings saved. https://gameaccessibilityguidelines.com/ensure-that-all-settings-are-saved-remembered/
10. W3C, WCAG 2.2 Understanding 2.3.1, three flashes or below threshold. https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html
11. W3C, WCAG 2.2 Understanding 2.3.3, animation from interactions. https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html
12. Microsoft, Xbox Accessibility Guideline 101, text display. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101
13. Microsoft, XAG 103, additional channels for visual and audio cues. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103
14. Microsoft, XAG 107, input. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107
15. Microsoft, XAG 117, moving content, camera and motion. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117
16. W3C, Media Queries Level 5, prefers-reduced-motion (value list only). https://www.w3.org/TR/mediaqueries-5/#prefers-reduced-motion
