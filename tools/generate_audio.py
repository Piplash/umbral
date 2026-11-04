"""Original deterministic synthesized effects. Standard library only; no runtime dependency."""
import math
import random
import struct
import wave
from pathlib import Path

OUTPUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
OUTPUT.mkdir(parents=True, exist_ok=True)
RATE = 22050
CUES = {
    'attack': (.12, 360, 85, .28), 'impact': (.11, 130, 42, .65),
    'damage': (.14, 210, 65, .35), 'heal': (.28, 520, 1040, .015),
    'jam': (.26, 760, 170, .20), 'unit_defeat': (.25, 280, 45, .25),
    'victory': (.75, 392, 784, .0), 'defeat': (.70, 220, 73, .02),
    'navigate': (.035, 640, 700, .0), 'select': (.075, 420, 840, .0),
    'confirm': (.075, 660, 990, .0), 'cancel': (.065, 440, 220, .0),
    'invalid': (.10, 115, 95, .06), 'turn': (.17, 300, 600, .0),
    'pause': (.095, 350, 525, .0),
}

for name, (duration, start, end, noise) in CUES.items():
    rng = random.Random(name)
    samples = []
    phase = 0.0
    for index in range(int(duration * RATE)):
        t = index / RATE
        progress = t / duration
        frequency = start + (end - start) * progress
        if name == 'victory':
            frequency = [392, 494, 587, 784][min(3, int(progress * 4))]
        elif name == 'defeat':
            frequency = [220, 196, 147, 110][min(3, int(progress * 4))]
        phase += math.tau * frequency / RATE
        envelope = min(1.0, t / .004) * (1 - progress) ** 1.7
        tone = math.sin(phase) * .65 + math.sin(phase * 2) * .17
        if name == 'jam':
            tone *= math.sin(math.tau * 32 * t)
        sample = (tone * (1 - noise) + rng.uniform(-1, 1) * noise) * envelope * .38
        samples.append(struct.pack('<h', int(max(-1, min(1, sample)) * 32767)))
    with wave.open(str(OUTPUT / (name + '.wav')), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(b''.join(samples))
print(f'Generated {len(CUES)} original mono PCM effects in {OUTPUT}')
