# SUB and SBB: Flags Analysis



## How SUB sets the flags

For subtraction, CF means borrow. CF = 1 when the unsigned value being subtracted is larger than the destination. AF = 1 when the low nibble needs a borrow from bit 4. OF = 1 when the signed result falls outside -32768 to 32767. Subtracting two numbers with the same sign never overflows.

---

## Program 1: sub2.asm

```
mov ax, [num1]    ; AX = 1000
sub ax, [num2]    ; AX = 1000 - 2000
```

| | Decimal | Hex | Binary |
|---|---|---|---|
| num1 | 1000 | 0x03E8 | 0000 0011 1110 1000 |
| num2 | 2000 | 0x07D0 | 0000 0111 1101 0000 |
| AX | -1000 (signed) / 64536 (unsigned) | 0xFC18 | 1111 1100 0001 1000 |

GDB after `sub`: `eflags 0x285 [ CF PF SF IF ]`

| Flag | Value | Reason |
|------|-------|--------|
| CF | 1 | Unsigned 1000 is smaller than 2000. The subtraction borrows from beyond bit 15. |
| PF | 1 | Low byte 0x18 = 0001 1000 holds two 1 bits. Two is even. |
| AF | 0 | Low nibbles: 0x8 - 0x0 = 0x8. No borrow from bit 4. |
| ZF | 0 | The result is not 0. |
| SF | 1 | Bit 15 of 0xFC18 is 1. The signed result is negative (-1000). |
| OF | 0 | Positive minus positive never overflows. -1000 fits in the signed 16-bit range. |

CF and OF give opposite verdicts. CF = 1 says the unsigned answer (64536) is wrong. OF = 0 says the signed answer (-1000) is correct. The bits in AX stay the same. The flags tell me which interpretation holds.

---

## Program 2: sub3.asm

```
mov ax, [num1]    ; AX = 0x0000
sub ax, [num2]    ; AX = 0 - 1
sbb ax, 0         ; AX = AX - 0 - CF
```

### After `sub ax, [num2]`

0x0000 - 0x0001 = 0xFFFF (-1 signed, 65535 unsigned).

GDB: `eflags 0x295 [ CF PF AF SF IF ]`

| Flag | Value | Reason |
|------|-------|--------|
| CF | 1 | Unsigned 0 is smaller than 1, so the subtraction borrows. |
| PF | 1 | Low byte 0xFF holds eight 1 bits. Eight is even. |
| AF | 1 | Low nibbles: 0x0 - 0x1 needs a borrow from bit 4. |
| ZF | 0 | The result is 0xFFFF, not 0. |
| SF | 1 | Bit 15 of 0xFFFF is 1. The signed result is -1. |
| OF | 0 | 0 - 1 = -1, inside the signed range. |

### After `sbb ax, 0`

SBB subtracts the source plus the current CF: AX = 0xFFFF - 0 - 1 = 0xFFFE (-2 signed).

GDB: `eflags 0x282 [ SF IF ]`

| Flag | Value | Reason |
|------|-------|--------|
| CF | 0 | 0xFFFF (65535) is larger than 0 + 1. No borrow. |
| PF | 0 | Low byte 0xFE = 1111 1110 holds seven 1 bits. Seven is odd. |
| AF | 0 | Low nibbles: 0xF - 0x0 - 1 = 0xE. No borrow from bit 4. |
| ZF | 0 | The result is not 0. |
| SF | 1 | Bit 15 of 0xFFFE is 1. The signed result is -2. |
| OF | 0 | -1 - 1 = -2, inside the signed range. |

SBB consumed the borrow from the first SUB and cleared CF. In multi-word subtraction, SUB handles the low word and SBB subtracts the borrow from the high word.