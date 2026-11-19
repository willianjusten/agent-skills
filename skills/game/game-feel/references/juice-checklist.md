# Juice checklist

Work down the list per event. Pick the lightest option that reads; stop when the event feels clear.

## Motion

- **Easing.** Never move or scale linearly. Ease out for arrivals and reactions, ease in for departures. A punch is an instant jump to a peak that eases back to rest (about 0.2 to 0.3 s).
- **Squash and stretch.** Scale a body on impact or jump, preserving rough volume.
- **Anticipation and follow-through.** A short wind-up before a big action, a settle after it.

## Time and camera

- **Hit-stop.** Freeze the action for 2 to 6 ticks on a heavy hit. Implement it in the renderer's time or as a simulation event; never by sleeping.
- **Screen shake.** Small offset that decays fast (about 0.15 s), driven by a trauma value that grows with event strength. Off or reduced under `prefers-reduced-motion`.
- **Camera nudge.** A small push toward the event; cheaper and calmer than shake.

## Visual

- **Flash.** One or two frames of white or the event colour on the hit object.
- **Particles.** A short burst at the event position, small count, gone in under half a second.
- **Trails and afterimages** for fast movers.

## Interface

- **Score and counters.** Pop or count up instead of swapping the number.
- **Messages.** Short text near the event, fading out.

## Audio

- One sound per event, short, distinct in pitch from its neighbours: rising for gain, falling for loss, noisy for impact.
- Vary pitch slightly on frequent events so repeats do not grate.
- Duck or cap overlapping copies of the same sound.
- ZzFX generates effects from a parameter array; start from its generator presets and adjust by ear. Keep parameters in a plain-data module.
- Every music and recorded sound file is in the manifest with its license.
