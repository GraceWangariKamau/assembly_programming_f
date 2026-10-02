# ADD and ADC: Flags Analysis


## Flag reference

| Flag | Name | Set to 1 when |
|------|------|---------------|
| CF | Carry | Unsigned result needs a bit beyond the register size |
| PF | Parity | Low 8 bits of the result hold an even number of 1 bits |
| AF | Auxiliary carry | A carry moves from bit 3 into bit 4 |
| ZF | Zero | Result equals 0 |
| SF | Sign | Most significant bit of the result is 1 |
| OF | Overflow | Signed result falls outside the signed range |

---

## Program 1: add2.asm

```
mov ax, [num1]    ; AX = 32000
add ax, [num2]    ; AX = 32000 + 500
```

| | Decimal | Hex | Binary |
|---|---|---|---|
| num1 | 32000 | 0x7D00 | 0111 1101 0000 0000 |
| num2 | 500 | 0x01F4 | 0000 0001 1111 0100 |
| AX | 32500 | 0x7EF4 | 0111 1110 1111 0100 |

GDB after `add`: `eflags 0x202 [ IF ]`

| Flag | Value | Reason |
|------|-------|--------|
| CF | 0 | 32500 fits in 16 bits (max 65535). No carry leaves bit 15. |
| PF | 0 | Low byte 0xF4 = 1111 0100 holds five 1 bits. Five is odd. |
| AF | 0 | Low nibbles: 0x0 + 0x4 = 0x4. No carry from bit 3 into bit 4. |
| ZF | 0 | The result is 32500, not 0. |
| SF | 0 | Bit 15 of 0x7EF4 is 0. The signed result is positive. |
| OF | 0 | Both operands are positive. 32500 stays below the signed max of 32767, so the sign bit did not flip. |

Every arithmetic flag is clear. IF (interrupts enabled) is a system flag set by the OS. ADD does not touch it.

The result sits close to the signed limit. Adding 268 more (32768) would flip bit 15 and set both SF and OF.

---

## Program 2: adc4.asm

```
mov ax, [num1]    ; AX = 0xFFFF
add ax, [num2]    ; AX = 0xFFFF + 1
adc ax, 0         ; AX = AX + 0 + CF
```

### After `add ax, [num2]`

0xFFFF + 0x0001 = 0x10000. The 17-bit result does not fit in AX, so AX keeps the low 16 bits: 0x0000.

GDB: `eflags 0x255 [ CF PF AF ZF IF ]`

| Flag | Value | Reason |
|------|-------|--------|
| CF | 1 | Unsigned 65535 + 1 = 65536 needs 17 bits. Bit 16 goes into CF. |
| PF | 1 | Low byte 0x00 holds zero 1 bits. Zero is even. |
| AF | 1 | Low nibbles: 0xF + 0x1 = 0x10. A carry moves from bit 3 into bit 4. |
| ZF | 1 | AX = 0x0000. |
| SF | 0 | Bit 15 of 0x0000 is 0. |
| OF | 0 | Signed view: -1 + 1 = 0. The operands have different signs, and adding numbers with different signs never overflows. |

CF and OF disagree here. CF = 1 tells me the unsigned answer (0) is wrong. OF = 0 tells me the signed answer (-1 + 1 = 0) is correct.

### After `adc ax, 0`

ADC adds the source plus the current CF: AX = 0 + 0 + 1 = 1.

GDB: `eflags 0x202 [ IF ]`

| Flag | Value | Reason |
|------|-------|--------|
| CF | 0 | 0 + 0 + 1 = 1. No carry leaves bit 15. |
| PF | 0 | Low byte 0x01 holds one 1 bit. One is odd. |
| AF | 0 | Low nibbles: 0x0 + 0x0 + 1 = 0x1. No carry from bit 3. |
| ZF | 0 | AX = 1. |
| SF | 0 | Bit 15 is 0. |
| OF | 0 | 0 + 0 + 1 = 1. A positive result from non-negative inputs. |

AX ends at 1, the value of the carry lost in the first ADD. In multi-word addition, ADD handles the low word and ADC adds the carry into the high word. The full answer 0x10000 is high word 0x0001 and low word 0x0000.