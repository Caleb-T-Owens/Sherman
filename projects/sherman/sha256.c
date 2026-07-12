/* sha256.c — plain FIPS 180-4 SHA-256.  No dependencies; verified against
 * the standard "abc" test vector on first use (sha256_selfcheck), so a
 * mistyped constant can never silently mis-hash the state store.
 *
 * Reference code transcribed from the spec — dense by nature.  There is
 * nothing project-specific in here; treat it as a black box. */
#include "sherman.h"

static const uint32_t K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
};

#define ROR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))

static void compress(Sha256 *c, const uint8_t block[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++)
        w[i] = (uint32_t)block[4 * i] << 24 | (uint32_t)block[4 * i + 1] << 16 |
               (uint32_t)block[4 * i + 2] << 8 | block[4 * i + 3];
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = ROR(w[i - 15], 7) ^ ROR(w[i - 15], 18) ^ (w[i - 15] >> 3);
        uint32_t s1 = ROR(w[i - 2], 17) ^ ROR(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }

    uint32_t a = c->state[0], b = c->state[1], cc = c->state[2], d = c->state[3];
    uint32_t e = c->state[4], f = c->state[5], g = c->state[6], h = c->state[7];

    for (int i = 0; i < 64; i++) {
        uint32_t S1 = ROR(e, 6) ^ ROR(e, 11) ^ ROR(e, 25);
        uint32_t ch = (e & f) ^ (~e & g);
        uint32_t t1 = h + S1 + ch + K[i] + w[i];
        uint32_t S0 = ROR(a, 2) ^ ROR(a, 13) ^ ROR(a, 22);
        uint32_t maj = (a & b) ^ (a & cc) ^ (b & cc);
        uint32_t t2 = S0 + maj;
        h = g; g = f; f = e; e = d + t1;
        d = cc; cc = b; b = a; a = t1 + t2;
    }

    c->state[0] += a; c->state[1] += b; c->state[2] += cc; c->state[3] += d;
    c->state[4] += e; c->state[5] += f; c->state[6] += g; c->state[7] += h;
}

static void init_raw(Sha256 *c)
{
    static const uint32_t H0[8] = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    };
    memcpy(c->state, H0, sizeof H0);
    c->nbytes = 0;
    c->buflen = 0;
}

void sha256_update(Sha256 *c, const void *data, size_t len)
{
    const uint8_t *p = data;
    c->nbytes += len;
    if (c->buflen) {
        size_t take = 64 - c->buflen;
        if (take > len) take = len;
        memcpy(c->buf + c->buflen, p, take);
        c->buflen += take;
        p += take;
        len -= take;
        if (c->buflen == 64) { compress(c, c->buf); c->buflen = 0; }
    }
    while (len >= 64) { compress(c, p); p += 64; len -= 64; }
    if (len) { memcpy(c->buf, p, len); c->buflen = len; }
}

void sha256_hex(Sha256 *c, char out[65])
{
    uint64_t bits = c->nbytes * 8;
    uint8_t pad = 0x80;
    sha256_update(c, &pad, 1);
    static const uint8_t zero[64] = {0};
    while (c->buflen != 56)
        sha256_update(c, zero, c->buflen < 56 ? 56 - c->buflen : 64 - c->buflen);
    uint8_t lenbuf[8];
    for (int i = 0; i < 8; i++) lenbuf[i] = (uint8_t)(bits >> (56 - 8 * i));
    sha256_update(c, lenbuf, 8);

    for (int i = 0; i < 8; i++)
        snprintf(out + 8 * i, 9, "%08x", c->state[i]);
}

/* Dies if the implementation is broken (e.g. a mistyped constant), so a bad
 * build can never silently mis-hash the whole state store. */
static void sha256_selfcheck(void)
{
    Sha256 c;
    init_raw(&c);
    sha256_update(&c, "abc", 3);
    char hex[65];
    sha256_hex(&c, hex);
    if (strcmp(hex, "ba7816bf8f01cfea414140de5dae2223"
                    "b00361a396177a9cb410ff61f20015ad") != 0)
        die("sha256 self-check failed — refusing to run");
}

void sha256_init(Sha256 *c)
{
    static bool checked = false;
    if (!checked) { checked = true; sha256_selfcheck(); }
    init_raw(c);
}
