# UI and UX: detail

Read after [ui-ux.md](ui-ux.md) when a rule doesn't settle the case. Sections follow the rule numbers.

## Contents
- 1 Play in two activations
- 2 One decision per screen
- 3 Back is everywhere, the same
- 4 Focus is always visible
- 5 Single presses reach everything
- 6 Prompts: few, contextual, fixed
- 7 HUD in two tiers
- 8 Pause, settings, game over
- Numbers
- Sources

## 1 Play in two activations

The Game Accessibility Guidelines list starting a game without multiple menu levels as a basic guideline [4]. Apple asks for defaults that let people start without changing settings, deferred setup, and a launch that restores the previous state [1][2][3]. The counts (2 and 4) are ours [house].

- Good: title opens with Play focused; the second run offers "Same setup" as the focused action.
- Bad: title, mode, character, weapon, difficulty, Start, every run.
- Mechanical check: script the shortest path from title to the first gameplay frame by focus moves and activations; fail above 2 repeat, 4 first run.

## 2 One decision per screen

Apple warns against teaching or asking too much at once [2], and multi-level setup is a named barrier [4]. The count is ours [house]. A name or cost on a tile is not repeated in the panel. Locked items add noise: hide them, or show one "?" tile for the next unlock.

- Good: a character grid, one detail panel, one Select button.
- Bad: character grid, weapon row, difficulty slider and Launch on one screen; a tile and its panel both print the cost.
- Mechanical check: count selection groups (radio groups, tab lists, sibling sets of the same kind); more than 1 outside a shop or between-rounds screen is a miss, 3 or more a hard miss.

## 3 Back is everywhere, the same

Xbox wants persistent links back on every submenu and prompts in the same relative position [5]. Apple maps B to cancel or return, and Menu to settings or pause [6].

- Good: bottom-left "Select / Back" on every screen, same order.
- Bad: Back top-right on one screen, bottom-centre on another, absent on the weapon screen.
- Mechanical check: from each reachable screen press the back input and assert one level up; compare the prompt's rect across screens.

## 4 Focus is always visible

Xbox asks for focus order matching the layout, predictable movement, and wrap in lists but not grids [5][7]. WCAG requires a meaningful focus order and that a focused component is not entirely hidden [8][9]. Interactive elements need a clear indication that they are interactive [10].

- Good: focused tile enlarged and outlined; the panel follows it.
- Bad: focus ring clipped by a card's overflow; Down from Settings jumps across the screen to Quit; a 4 by 4 grid that wraps to the opposite corner.
- Mechanical check: walk every screen by direction input and record the focused element's rect each step; fail on none, two, or a rect with zero visible area. From the last item press Down in each list and each grid and assert the landing item.

## 5 Single presses reach everything

Xbox 107 asks for UIs operable with single, non-simultaneous presses, activation on the up event, and holds avoided [11]. It calls holds of 3 seconds or more a barrier and suggests 15 mm phone targets [11]. The Game Accessibility Guidelines rank "menus use the same input as gameplay" as basic [12]. Apple lists 44 by 44 pt as the default iOS target and asks for each platform's default interaction [1][6]. The 24 px floor is ours [house].

- Good: a slider adjusts with Left and Right after one confirm.
- Bad: a keys-only game whose Settings needs a mouse; 20 px icon buttons side by side.
- Mechanical check: complete title to play, then open and close settings, with keyboard only and a scripted D-pad; read every interactive element's box and neighbour gap.

## 6 Prompts: few, contextual, fixed

Apple teaches through context-specific tips near the relevant area [2]. Players need a reminder of controls in play [13]. Xbox calls inconsistent prompt placement the failure [5]; Apple asks for the connected controller's symbols [6]. The 1 to 3 limit and the ban on a legend are ours [house].

- Good: bottom-left "Select  Back", plus a transient "Dash: Shift" on first use.
- Bad: a six-line WASD/Space/Esc legend permanent on the title.
- Mechanical check: count visible key hints per screen (kbd elements, glyph icons, "Press" strings); fail above 3 on a menu or any on play after 10 s.

## 7 HUD in two tiers

Apple shows and hides virtual controls to match the moment and cut clutter [6], and asks layouts to respect safe areas [1]. An option to hide non-interactive elements helps players [15]. Time-limited essential information belongs near the likely gaze, since many impairments narrow peripheral vision [14]. A games user researcher argues peripheral vision starts beyond about 2 degrees, crowding grows with distance and text strings should stay out of it (a practitioner article, not a study) [16]. A 2009 thesis on shooters finds overlay suits detail and coarse cues like edge tint carry a feel; small studies, so a rule of thumb [17]. The 5-group cap is ours [house].

- Good: health, wave, currency, one cooldown always on; ammo as a bar, the count shown at low ammo; a 3D arrow for the objective, an overlay number for ammo.
- Bad: nine always-on panels including a score history; "Boss incoming in 5" as a twelve-word line in a far corner.
- Mechanical check: on a quiet frame (10 s, no events) count top-level HUD groups; fail above 5. Assert every persistent rect sits inside the safe-area inset and every transient warning's centre is within 35% of viewport height from screen centre [house].

## 8 Pause, settings, game over

Apple maps Menu to open settings or pause [6]; Xbox warns against holds and rapid presses [11]. Settings must be saved [18]. Text that advances on the player's action, not a timer, is a basic guideline [19]; with launch-state restore [3], that shapes game over. Entry counts and the activation limit are ours [house].

- Good: four plain entries, Resume focused; "Run over", score, best, Retry focused, Menu beside it.
- Bad: nine pause entries with a stats table; an Apply button, value lost on reload; an unlock list to click through before Retry appears.
- Mechanical check: press pause in play; assert game time stops, focus is on Resume, the same input resumes. Change a value, reload, assert persistence. From game over count activations to the next gameplay frame. Assert game over has no timer.

## Numbers

| Value | What | Source |
| --- | --- | --- |
| 2 / 4 | activations title to play, repeat / first run | house |
| 1 | selection group per menu screen (3 or more fails) | house |
| 5 | persistent HUD groups at most | house |
| 35% | viewport height, max centre distance of an urgent item | house |
| 2 degrees | where peripheral vision begins | [16] |
| 44 by 44 pt | default touch target on iOS | [1][6] |
| 15 mm | phone touch target | [11] |
| 24 by 24 CSS px | web target floor | house |
| 3 s | a hold at or past this is a barrier | [11] |

## Sources

1. Apple, Human Interface Guidelines, "Designing for games". https://developer.apple.com/design/human-interface-guidelines/designing-for-games
2. Apple, Human Interface Guidelines, "Onboarding". https://developer.apple.com/design/human-interface-guidelines/onboarding
3. Apple, Human Interface Guidelines, "Launching". https://developer.apple.com/design/human-interface-guidelines/launching
4. Game Accessibility Guidelines, "Allow the game to be started without multiple levels of menus". https://gameaccessibilityguidelines.com/allow-the-game-to-be-started-without-the-need-to-navigate-through-multiple-levels-of-menus/
5. Microsoft, Xbox Accessibility Guideline 112: UI navigation. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112
6. Apple, Human Interface Guidelines, "Game controls". https://developer.apple.com/design/human-interface-guidelines/game-controls
7. Microsoft, Xbox Accessibility Guideline 106: Screen narration. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/106
8. W3C, WCAG 2.2, 2.4.3 Focus Order. https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html
9. W3C, WCAG 2.2, 2.4.11 Focus Not Obscured (Minimum). https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html
10. Game Accessibility Guidelines, "Give a clear indication that interactive elements are interactive". https://gameaccessibilityguidelines.com/give-a-clear-indication-that-interactive-elements-are-interactive/
11. Microsoft, Xbox Accessibility Guideline 107: Input. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107
12. Game Accessibility Guidelines, "Ensure that all areas of the user interface can be accessed using the same input method as the gameplay". https://gameaccessibilityguidelines.com/ensure-that-all-areas-of-the-user-interface-can-be-accessed-using-the-same-input-method-as-the-gameplay/
13. Game Accessibility Guidelines, "Indicate or allow reminder of controls during gameplay". https://gameaccessibilityguidelines.com/indicate-allow-reminder-of-controls-during-gameplay/
14. Game Accessibility Guidelines, "Avoid placing essential temporary information outside the player's eye-line". https://gameaccessibilityguidelines.com/avoid-placing-essential-temporary-information-outside-the-players-eye-line/
15. Game Accessibility Guidelines, "Provide an option to turn off or hide all non-interactive elements". https://gameaccessibilityguidelines.com/provide-an-option-to-turn-off-hide-all-non-interactive-elements/
16. Tilford, "Perceiving without looking: designing HUDs for peripheral vision", Game Developer, 2016 (practitioner). https://gamedeveloper.com/design/perceiving-without-looking-designing-huds-for-peripheral-vision
17. Fagerholt and Lorentzon, "Beyond the HUD: user interfaces for increased player immersion in FPS games", Chalmers, 2009. https://publications.lib.chalmers.se/records/fulltext/111921.pdf
18. Game Accessibility Guidelines, "Ensure that all settings are saved/remembered". https://gameaccessibilityguidelines.com/ensure-that-all-settings-are-saved-remembered/
19. Game Accessibility Guidelines, "Allow players to progress through text prompts at their own pace". https://gameaccessibilityguidelines.com/allow-players-to-progress-through-text-prompts-at-their-own-pace/
