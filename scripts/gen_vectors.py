import random
import zlib

random.seed(1)           # fixed seed so results are reproducible
NUM_MSG = 200
MAX_LEN = 16

with open("vectors.hex", "w") as f:
    for _ in range(NUM_MSG):
        n = random.randint(0, MAX_LEN)
        data = bytes(random.randrange(256) for _ in range(n))
        # Each message takes 18 words: length, expected CRC, 16 bytes (padded)
        words = [n, zlib.crc32(data)] + list(data) + [0] * (MAX_LEN - n)
        for w in words:
            f.write(f"{w:08x}\n")