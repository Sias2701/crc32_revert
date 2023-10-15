from sage.all import *
from zlib import crc32

def crc32_revert(checksum: int, length=4) -> bytes:
    PR = PolynomialRing(GF(2),'x')
    x = PR.gen()
    g = x ** 32 + x ** 26 + x ** 23 + x ** 22 + x ** 16 + x ** 12 + x ** 11 + x ** 10 + x ** 8 + x ** 7 + x ** 5 + x ** 4 + x** 2 + x + 1
    p = x ** 32

    # revert postprocessing
    checksum = [int(i) for i in bin(checksum ^ 0xffffffff)[2:].zfill(32)]

    r = PR(checksum)
    k = -r * inverse_mod(g, p) % p

    if length > 4:
        k += PR.random_element(degree=7 * (length - 4)) * p
    
    fp = k * g + r

    
    f = fp // p
    if length > 4:
        f += PR([0] * ((length - 4) * 8) + [1] * 32)
    else:
        f += PR([1] * 32)
    f = vector(f)

    bits = list(f)
    bits.extend(0 for _ in range(length * 8 -len(f)))
    bits = bits[::-1]
    ret = []
    for bp in range(0, len(bits), 8):
        bit = bits[bp:bp+8]
        ret.append(int("".join([str(i) for i in bit[::-1]]), 2))
    return bytes(ret)
pt = b'abc'
val = crc32(pt)
rev = crc32_revert(val)

print(hex(val))
print(hex(crc32(rev)))
