# Play field

The brief's look direction wins over every rule here except readability of the player and of danger. Fix readability with contrast, placement or timing, never by toning the style down.

Rules are defaults: break one when its "Break when" applies and say so in the log. A check reports a miss; only **blocks** rules stop a run. Numbers, examples, sources: [play-field-deep.md](play-field-deep.md).

1. **Nothing covers the player.** **blocks** The avatar draws above every effect, banner, pickup and HUD element, and stays findable at peak bloom, flash or shake. Why: it is the player's only feedback on their input. Break when: an effect on the avatar itself (hit, death) under 150 ms. Check: find the avatar on the busiest frame in under a second. [1][4][6]

2. **Danger reads at a glance.** **blocks** One visual language means "this hurts" and nothing else uses it. Hazards differ from pickups in two of shape, value and motion; colour is never the only cue. Why: shape and contrast read before hue, and many players can't tell red from green. Break when: colour is the mechanic; add a second channel anyway. Check: name every entity by shape in a greyscale screenshot. [1][5][7]

3. **Readable against the worst background.** Text and key elements hold 4.5:1 contrast (3:1 large) against the brightest pixel behind them; give HUD text a backing or outline. Break when: decoration nobody acts on. Check: read every HUD item on a peak-effect screenshot. [4]

4. **Telegraph long enough, and honestly.** Every hazard cues before it hurts: at least 500 ms for a new move, 350 ms for a learned one. The cue covers exactly the damage area, grows louder with damage, and uses two channels (shape plus sound). Why: bare reaction is about 230 ms, before choosing and moving. Break when: an opt-in hard mode, or a hazard visible long before it arrives. Check: frame-step from first cue to hit. [1][3][5][house]

5. **Banners have fixed spots.** Each kind of message owns one region, away from the centre and the avatar's spawn and path. Banners are short and fade, never block. Why: the player learns where to look. Break when: play is paused or over. Check: trigger every banner; each lands in its region, clear of the avatar. [1][6][house]

6. **Noise drops as danger rises.** Cap cosmetic effects and shrink them as hazards fill the screen; the strongest treatment goes to what hurts or can be collected. Break when: nothing can hurt (victory, boss death). Check: on the busiest frame, say what can hurt you in under two seconds. [1][2][house]

7. **The next threat is in view.** Forward view covers speed times (telegraph plus reaction). Off-screen attackers get an edge indicator with a shape cue. The camera never pushes the avatar to an edge. Break when: limited sight is the tension; cue by sound instead. Check: at top speed, time from entering view to contact. [3][4][8][house]
