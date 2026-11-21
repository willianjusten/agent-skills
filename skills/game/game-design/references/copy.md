# Copy

The brief's look direction wins over every rule here except readability of the player and of danger. Fix readability with contrast, placement or timing, never by toning the style down.

Rules are defaults: break one when its "Break when" applies and say so in the log. A check reports a miss; only **blocks** rules stop a run. Numbers, examples, sources: [copy-deep.md](copy-deep.md).

1. **Buttons name the outcome.** Label each button with the verb and object for what happens next ("Retry wave", "Erase 3 runs"), never OK, Yes, No or Continue when a dialog has two choices. Confirm only costly actions, state what is lost, never pre-focus the destructive button. Break when: a restart that costs seconds (skip the dialog). Check: grep button strings for the generic labels. [1][2]

2. **Numbers over adjectives.** Where the code holds a quantity, print it: "4 left, next at wave 5" beats "Almost there!"; "Wave 4 of 10" beats "Getting harder". Break when: the number is false precision (use "about 3 min"), a secret by design, or already shown by a bar. Check: grep for almost, nearly, many, few, soon next to a variable. [3][4]

3. **Short and front-loaded.** Key word first. In-play prompts: one line, 3 to 6 words, flagged over 8. Menus: two short sentences, about 40 words a screen. Break when: the text is the content (codex, interactive fiction). Check: word count per string and per screen. [5][6][house]

4. **No reading during action; player-paced text.** While the player dodges or aims, show only a glance (prompt, counter). Longer text goes to a pause point. Essential text waits for a keypress or can be reopened. Break when: the player is stationary, or the line is flavour. Check: screenshot mid-play shows at most one short line; no timeout hides instructions. [7][8][9]

5. **End states: state, numbers, one verb.** Game over, win and pause show the state word, at least one run number, and one primary verb button plus a way to the menu. Break when: an instant-restart arcade ("Press any key to retry" under the score). Check: string table has these entries, each with an interpolated value. [1][3][9][house]

6. **Errors: cause, fix, one voice.** Failure copy says what happened and the next step, never "invalid" or codes. Game voice for play, plain words where progress is at risk. Break when: the failure is in-fiction and costs nothing. Check: no "invalid" or hex in strings. [1][10]

7. **Captions: 2 lines, 40 characters, timed by length.** At most 2 lines of about 40 characters, speaker named on change, meaningful sounds marked. Timed text shows at least characters / 20 seconds, floor 1.5 s. Break when: the player can pause or replay. Check: compute duration against length per string. [11][12][13][house]

8. **Strings survive translation.** Whole phrases with named placeholders ("{count} left"), no concatenation, no text in images, one string table. Size short labels for 3x their English length. Why: short strings grow most. Check: render at 3x length, look for clipping. [14][15]
