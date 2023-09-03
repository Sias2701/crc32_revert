from pwn import *
from zlib import crc32
from random import randbytes
from Crypto.Util.number import *


def crc32_poly(msg):
    m = []
    PR.<x> = PolynomialRing(GF(2))
    g=x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 +x^7 + x^5 + x^4 + x^2 + x + 1
    for bt in msg:
        b = int(bt)
        m += [int(i) for i in bin(b)[2:].zfill(8)[::-1]]
    
    m += [0] * g.degree()
    for i in range(32):
        m[i] += 1
        m[i] %= 2
    mf = PR(m[::-1])
    mf %= g
    coeff = mf.coefficients(sparse=False)
    return int("".join([str(i) for i in coeff]), 2) ^^ 0xFFFFFFFF

def crc32_revert(checksum : int):
    PR.<x> = PolynomialRing(GF(2))
    g = x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 +x^7 + x^5 + x^4 + x^2 + x + 1
    p = x^32
    r = PR([int(i) for i in bin(checksum ^^ 0xFFFFFFFF)[2:]])
    k = -r * inverse_mod(g, p) + PR.random_element(degree = 512) * p
    fp = r + k * g
    f = fp // p
    coeff = f.coefficients(sparse=False)
    if len(coeff) * 8 != 0:
        coeff = coeff + [0]*(8 - (len(coeff) % 8))
    for i in range(1, 32+1):
        coeff[-i] += 1
        coeff[-i] %= 2
    result = []
    for i in range(0, len(coeff), 8):
        result.append(int("".join([str(j) for j in coeff[i:i+8]]), 2))
    return bytes(result[::-1])

crc_val = crc32(b'abc')
reverted = crc32_revert(crc_val)
new_crc = crc32(reverted)
print(reverted.hex())
print(b'abc')

print(crc_val == new_crc)
