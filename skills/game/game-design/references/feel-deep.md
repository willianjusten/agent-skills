# Feel: detail

Read after [feel.md](feel.md) when a rule doesn't settle the case. Sections follow the rule numbers.

## Contents
- 1 Respond on the same frame
- 2 Scale feedback by importance, in layers
- 3 Hit-stop freezes both sides, capped
- 4 Shake is trauma, not an offset
- 5 Follow the player with a weighted camera
- 6 Ease it, deform only the look
- 7 Juice never hides play
- Numbers
- Sources

## 1 Respond on the same frame

Swink frames feel as a closed loop: the player's input and the game's reaction run so tightly that the result seems to happen as it is given, and feedback must return fast enough to correct [3][4]. Claypool and Claypool rank actions by precision and deadline; the more of both, the more latency hurts [5]. Their figures are network round trips in online games, about 100 ms for first-person avatars, 500 ms third-person, 1000 ms omnipresent, with shooter accuracy down about 35% at 100 ms added. Use them to order actions, not as targets for local input. The frame ceilings are ours [house].

- Good: the jump press starts the rise and its sound on the same frame.
- Bad: a 150 ms crouch plays before the body leaves the ground.
- Mechanical check: log the frame an input is read and the frame its reaction is drawn or its sound scheduled; assert a gap of 0 or 1, and 6 or fewer for loose actions. Count dropped presses in a mash test.

## 2 Scale feedback by importance, in layers

Sakurai: hitstop runs longer for stronger hits but is capped, however large the damage [2]. Eiserloh feeds one trauma value from damage and stress, so escalation is visible [1]. Swink counts animation, sound and effects as the polish that sells physicality, as much as the collision system [3][4]; his De Blob example changed a ball's feel with a deforming shader and no physics change [4]. Sakurai's hit effect is itself layered: a freeze plus vibration on both sides [2]. Sound content: sound.md.

- Good: a coin gets a tick and a tiny pop; a boss kill gets a long freeze, big shake and a swell.
- Bad: every hit, graze or kill, gets the same 6-tick freeze and full shake.
- Mechanical check: each event row carries a strength tier; assert the rarest events are not in the weakest tier and the most frequent not in the strongest. Mute audio, then hide visuals: the event must read in each alone.

## 3 Hit-stop freezes both sides, capped

Sakurai describes both sides freezing, the length scaled by damage and a per-attack modifier, with a cap [2]. The attacker shakes as well as the target; the shake starts large and shrinks over the freeze, with the total length known in advance. Hurtboxes stay put during it. He avoids long freezes in free-for-alls, since a third player could hit during a shared freeze, and notes that games with constant hits, such as Dynasty Warriors, largely omit the effect because it would slow play [2]. He gives no frame counts. 2 to 6 ticks for a heavy hit in a light action game is our start [house]; fighting games run longer, unsourced here.

- Good: a heavy hit freezes 6 ticks with damped vibration; a light hit freezes 1 to 2.
- Bad: every hit freezes 12 ticks and a mash stutters the game for a second.
- Mechanical check: assert a max-freeze constant exists and two freezes cannot sum past it; the freeze pauses the presentation clock without sleeping and leaves hit tests unchanged.

## 4 Shake is trauma, not an offset

Eiserloh keeps trauma in 0 to 1, raised by events (his examples add 0.2 or 0.5) and decaying linearly; shake is trauma squared or cubed, so trauma 0.3, 0.6 and 0.9 give 3%, 22% and 73% [1]. Smooth noise sampled by time feels better, works with pause and slow motion, has tunable frequency and replays identically. In 2D, rotation plus translation is best; in 3D, translation can push the camera into a wall, so rotate only, and take care in VR. Maximum angle and offset are tuned by eye, and the decay time is ours [house]. Shake added on top of the base camera never disturbs it [1].

- Good: trauma 0.3 is a faint tremor, 0.9 violent, and it fades smoothly.
- Bad: a fixed 8 px random offset per hit with no decay.
- Mechanical check: trauma clamps to [0, 1], decays to 0 untouched, shake is 0 at trauma 0; a setting that zeroes trauma exists (accessibility.md).

## 5 Follow the player with a weighted camera

Player movement is erratic, so Eiserloh moves the camera a fraction of the remaining distance each frame: at 60 fps, 0.01 is slow, 0.1 reasonably fast, 0.5 very fast. He scales the weight by time scale so pause and slow motion stay consistent, allows separate horizontal, vertical and up-down weights, and insists the player never leaves the screen [1]. A nudge toward an event is a calmer alternative to shake, with no source [house].

- Good: weight 0.1 horizontally, slower vertically so jumps don't yank the view.
- Bad: a follow tied to frame rate, twice as loose at 30 fps.
- Mechanical check: weight is multiplied by time scale; at scale 0 the camera does not move; at top speed the avatar stays inside the viewport.

## 6 Ease it, deform only the look

Swink attributes the feel of motion to simulation plus polish [3][4]; the De Blob squash changed feel while physics stayed as it was [4]. Anticipation, follow-through and ease curves are standard animation practice, unsourced here [house]. An anticipation that delays a response breaks rule 1, so shorten it to a couple of frames or show a same-frame flinch. A punch easing back over 0.2 to 0.3 s is a start value [house].

- Good: a panel scales in with ease-out over 150 ms; a landing squashes the drawing 2 to 3 frames, hitbox unchanged.
- Bad: a 300 ms wind-up before a dodge already pressed; a squash that shrinks the hitbox.
- Mechanical check: input-to-first-change stays within rule 1 with the anticipation present; the collider is read from simulation, never from the drawn scale.

## 7 Juice never hides play

Eiserloh calls shake "like salt": dull with none, "make it stop" with too much [1]. Sakurai limits hitstop where freezes would hurt play [2]. Lovato warns that excess juice annoys and trails can weaken impact [7]. WCAG 2.2 bans content flashing more than three times in a second [6]; the full flash and motion policy lives in accessibility.md. Where a cue is the information, shrink it and add a non-motion cue. Particle lifetime under 0.5 s and a small count are ours [house].

- Good: a short spark at the contact point, gone in a few frames, with a cap on live particles.
- Bad: a lingering smoke cloud over the next enemy; a shake on a static menu.
- Mechanical check: cap live particles and set a lifetime per effect; in the busiest 5 s of a recording, locate the avatar and nearest threat in under a second.

## Numbers

| Value | What | Source |
| --- | --- | --- |
| 0 or 1 frame | input to first reaction | house |
| 6 frames | loose actions, upper bound | house |
| 100 / 500 / 1000 ms | network sensitivity: first-person / third-person / omnipresent | [5] |
| 35% | shooter accuracy lost at 100 ms added | [5] |
| 1-2 / 2-6 ticks | hit-stop light / heavy | house |
| 0 to 1 | trauma range | [1] |
| 0.2 to 0.5 | trauma added per event | [1] |
| 3% / 22% / 73% | shake at trauma 0.3 / 0.6 / 0.9 | [1] |
| 0.01 / 0.1 / 0.5 | camera weight at 60 fps: slow / fast / very fast | [1] |
| 3 per second | flash ceiling | [6] |
| 0.2-0.3 s | punch ease-back | house |
| 0.5 s | particle lifetime ceiling | house |

## Sources

1. Eiserloh, "Math for Game Programmers: Juicing Your Cameras With Math", GDC 2016, slides. https://media.gdcvault.com/gdc2016/Presentations/Eiserloh_Squirrel_JuicingYourCameras.pdf
2. Sakurai, Famitsu column on hitstop, vol. 490-491, fan translation. https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/
3. Swink, "Game Feel: The Secret Ingredient", Gamasutra. https://www.gamedeveloper.com/design/game-feel-the-secret-ingredient
4. Swink, "Game Feel", Morgan Kaufmann, 2008, chapter 1.
5. Claypool and Claypool, "On Latency and Player Actions in Online Games", WPI report 06-13, 2006. https://ftp.cs.wpi.edu/pub/techreports/pdf/06-13.pdf
6. W3C, Web Content Accessibility Guidelines 2.2, success criteria 2.3.1 and 2.3.3. https://www.w3.org/TR/WCAG22/
7. Lovato, juicing essay, GameAnalytics blog, 2015 (secondary). https://www.gamedeveloper.com/design/squeezing-more-juice-out-of-your-game-design-
