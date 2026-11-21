# Copy: detail

Read after [copy.md](copy.md) when a rule doesn't settle the case. Sections follow the rule numbers. Much of the evidence is web or platform UX, not game research; it supports the rules rather than proving them for games.

## Contents
- 1 Buttons name the outcome
- 2 Numbers over adjectives
- 3 Short and front-loaded
- 4 No reading during action; player-paced text
- 5 End states: state, numbers, one verb
- 6 Errors: cause, fix, one voice
- 7 Captions: 2 lines, 40 characters, timed by length
- 8 Strings survive translation
- Numbers
- Sources

## 1 Buttons name the outcome

NN/g says labels should tell users what happens after they act [1]. For confirmations it recommends outcome labels such as "Delete file" and "Keep file" over Yes and No, and warns that overused confirmations get clicked through; specifics like a name or count help catch mistakes [2]. Xbox's own save-delete example names the object and the consequence [15].

- Good: "Erase 3 saved runs? This cannot be undone." with `Erase runs` and `Keep runs`.
- Bad: "Are you sure?" with `Yes` and `No`.
- Mechanical check: flag any button string in {OK, Yes, No, Submit, Continue} in a dialog with two or more buttons; count confirmations in a session and flag any on a routine action.

## 2 Numbers over adjectives

NN/g finds specific progress information (counts, percent) better than vague feedback, and step counts like "3 of 50" let users judge what remains [3]. Its 1997 web study found concrete, objective writing beat promotional text [4]. Both are web evidence; no game source was found for HUD copy, so the rule is an inference. The orbit-arena miss: "Almost there!" told the player nothing; "4 left, next at wave 5" gives distance and goal [house].

- Good: "Wave 4 of 10. 6 enemies left."
- Bad: "Keep going, you're nearly there!"
- Mechanical check: scan strings for degree words (almost, nearly, many, few, soon) near a value the code holds; each is a candidate for the variable.

## 3 Short and front-loaded

NN/g: about four in five web users scan, about one in six read word by word [5]. Game Accessibility Guidelines (GAG) call for simple clear language and note that large text blocks put off low-literacy readers [6]. The word limits are ours: 3 to 6, 8 and 40 are defaults to tune [house].

- Good: "Click below to save your character" [6].
- Bad: "If you click below your chosen character preferences will be saved" [6].
- Mechanical check: word count per string and per non-title screen; flag prompts over 8 words, screens over about 40.

## 4 No reading during action; player-paced text

Hodent: reading uses one language channel, so tutorial text competes with dialogue, and players should not be expected to read tutorial text while navigating or fighting [7]. GAG: reading speed varies widely, one player reports needing about three times longer; the fix is no timer, or replay on demand [8], and "allow all narrative and instructions to be replayed" is listed as an advanced item [9]. No figure exists for reading speed while playing; playtest.

- Good: a "Press Space to jump" prompt when the gap appears, plus a Help entry in pause.
- Bad: a three-sentence controls paragraph over the first wave; a hint that fades after 3 s and never returns.
- Mechanical check: any string shown in the playing state has at most about 8 words [house]; every instruction string waits for input or is reachable again; search for visibility timeouts.

## 5 End states: state, numbers, one verb

Synthesis of labels that say what happens next [1], specific counts [3] and GAG's intermediate item on reminding controls in play [9]. The layout order is ours [house].

- Good: "Game over. Wave 7. Best 9." with `Retry` and `Menu`.
- Bad: "Oh no! You tried your best!" with one `Continue`.
- Mechanical check: the string table has gameover, win and pause entries; each interpolates at least one value; each screen has one primary verb button.

## 6 Errors: cause, fix, one voice

NN/g error guidelines: plain language, be specific, suggest a fix, avoid blame, keep the user's input, and expect humor to wear thin when repeated [10]. NN/g's UX writing guide adds setting a tone of voice and keeping it consistent [1]. Xbox says error and pop-up text must follow the same text-size settings as the rest [15].

- Good: "Could not save. Storage is full. Free some space, then press Save."
- Bad: "Error 0x80070057 invalid operation."; "Oopsie! The cloud is grumpy."
- Mechanical check: no player-facing string contains "invalid", "error code" or a hex code; each failure string has a cause and an action.

## 7 Captions: 2 lines, 40 characters, timed by length

Xbox guideline 104: avoid lines over 40 characters when dialogue is fast, 2 lines (3 exceptionally), manual breaks, mixed case, name the speaker, and caption important sounds with direction when unclear [11]. Netflix: 42 characters per line, 2 lines, up to 20 characters per second for adults and 17 for children [12]. GAG: speech outpaces comfortable reading, so condense by compacting phrases, not dropping information [13]. A meta-analysis puts adult silent reading of non-fiction near 238 words per minute under ideal attention (abstract read) [16]; play is slower. The 1.5 s floor and display margin are ours [house].

- Good: `Baird (on radio): Launch the prototype.` shown at least 2 s.
- Bad: a 60-character warning visible for 1 s.
- Mechanical check: per caption, line length, line count, speaker prefix when voices change, and `duration_seconds >= max(1.5, characters / 20)`.

## 8 Strings survive translation

W3C, citing IBM, gives average growth from English into European languages [14]. Xbox guideline 101 requires fonts with every supported character set and halves line width for CJK [15].

- Good: `"{count} left"` in a string table; a button sized for 3x.
- Bad: `"You have " + n + " lives"` in a fixed-width button.
- Mechanical check: grep for concatenation or plural ternaries near UI text; render each short label at 3x length and check for clipping.

## Numbers

| Value | What | Source |
| --- | --- | --- |
| 40 characters, 2 lines (3 exceptional) | fast captions | [11] |
| 42 characters, 2 lines | subtitles | [12] |
| 20 / 17 characters per second | adult / child reading ceiling | [12] |
| 1.5 s | display floor for timed text | house |
| 238 words per minute | adult silent reading, ideal | [16] |
| 200-300% / 160-180% / 130% | growth: up to 10 / 21-30 / over 70 characters | [14] |
| 3 to 6 / 8 words | in-play prompt target / flag | house |
| about 40 words | per non-title screen | house |
| about 4 in 5 | web users who scan | [5] |

## Sources

1. Nielsen Norman Group, UX Writing study guide. https://www.nngroup.com/articles/ux-writing-study-guide/
2. Nielsen Norman Group, Confirmation dialogs. https://www.nngroup.com/articles/confirmation-dialog/
3. Nielsen Norman Group, Progress indicators make a slow system less insufferable. https://www.nngroup.com/articles/progress-indicators/
4. Nielsen Norman Group, Concise, scannable, and objective: how to write for the web, 1997 study. https://www.nngroup.com/articles/concise-scannable-and-objective-how-to-write-for-the-web/
5. Nielsen Norman Group, How users read on the web. https://www.nngroup.com/articles/how-users-read-on-the-web/
6. Game Accessibility Guidelines, Use simple clear language. https://gameaccessibilityguidelines.com/use-simple-clear-language/
7. Hodent, Design for working memory, Interaction Design Foundation. https://ixdf.org/literature/article/design-for-working-memory-players-will-remember-what-matters
8. Game Accessibility Guidelines, Allow players to progress through text prompts at their own pace. https://gameaccessibilityguidelines.com/allow-players-to-progress-through-text-prompts-at-their-own-pace/
9. Game Accessibility Guidelines, full list. https://gameaccessibilityguidelines.com/full-list/
10. Nielsen Norman Group, Error message guidelines. https://www.nngroup.com/articles/error-message-guidelines/
11. Microsoft, Xbox Accessibility Guideline 104: Audio and captions. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/104
12. Netflix, English Timed Text Style Guide. https://partnerhelp.netflixstudios.com/hc/en-us/articles/217350977-English-Timed-Text-Style-Guide
13. Game Accessibility Guidelines, Ensure subtitles/captions are cut down to and presented at an appropriate words-per-minute. https://gameaccessibilityguidelines.com/ensure-that-subtitles-captions-are-cut-down-to-and-presented-at-an-appropriate-words-per-minute-for-the-target-age-group/
14. W3C Internationalization, Text size in translation. https://www.w3.org/International/articles/article-text-size
15. Microsoft, Xbox Accessibility Guideline 101: Text display. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101
16. Brysbaert, How many words do we read per minute?, Journal of Memory and Language, 2019 (abstract only). https://www.gwern.net/doc/psychology/linguistics/2019-brysbaert.pdf
