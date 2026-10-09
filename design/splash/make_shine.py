"""Synthesises Masar's splash "shine": a bright bell (the glow lighting up)
over a quick rising sparkle, with a short echo tail. Pure stdlib, no numpy.
   python3 make_shine.py  ->  shine.wav (44.1 kHz, mono, 16-bit, ~1.8 s)"""
import math, random, struct, wave

SR = 44100
DUR = 1.8
N = int(SR * DUR)
out = [0.0] * N
random.seed(7)

def add_tone(start, freq, amp, decay, attack=0.004):
    s0 = int(start * SR)
    for i in range(s0, N):
        t = (i - s0) / SR
        env = min(1.0, t / attack) * math.exp(-t / decay)
        if env < 1e-4 and t > attack:
            break
        out[i] += amp * env * math.sin(2 * math.pi * freq * t)

# 1. sparkle: short glassy blips rising in pitch, just before the bell
for k in range(9):
    t = 0.02 + k * 0.035 + random.uniform(-0.006, 0.006)
    f = 2600 * (2 ** (k / 9)) * random.uniform(0.98, 1.02)
    add_tone(t, f, 0.10, 0.045)
    add_tone(t, f * 2.01, 0.04, 0.03)

# 2. the bell: E6 + B6 with bell-like inharmonic partials, long decay
bell_t = 0.33
for base, amp in ((1318.5, 0.34), (1975.5, 0.22)):
    for ratio, a, d in ((1, 1.0, 0.9), (2.0, 0.45, 0.5), (2.76, 0.25, 0.35), (5.4, 0.12, 0.18)):
        add_tone(bell_t, base * ratio, amp * a, d)
# a soft low "body" so it doesn't sound thin on a phone speaker
add_tone(bell_t, 659.25, 0.10, 0.6, attack=0.01)

# 3. echo tail: two quieter copies
dry = out[:]
for delay, gain in ((0.11, 0.28), (0.23, 0.14)):
    d = int(delay * SR)
    for i in range(d, N):
        out[i] += gain * dry[i - d]

# normalise to -3 dBFS, fade the last 120 ms
peak = max(abs(x) for x in out) or 1.0
g = 0.707 / peak
fade = int(0.12 * SR)
with wave.open('shine.wav', 'w') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    frames = bytearray()
    for i, x in enumerate(out):
        if i > N - fade:
            x *= (N - i) / fade
        frames += struct.pack('<h', int(max(-1, min(1, x * g)) * 32767))
    w.writeframes(bytes(frames))
print('shine.wav', round(DUR, 2), 's')
