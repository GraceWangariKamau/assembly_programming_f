# MUL: Flags Analysis


## How MUL sets the flags

MUL is unsigned. The product is twice the size of the operands:

| Operand size | Product goes into |
|---|---|
| 16-bit | DX:AX |
| 32-bit | EDX:EAX |

MUL sets CF and OF together:

- CF = OF = 1 when the upper half (DX or EDX) is not zero. The product does not fit in AX or EAX alone.
- CF = OF = 0 when the upper half is zero. The product fits in the lower register.

The Intel manual lists SF, ZF, AF and PF as undefined after MUL. GDB displays a value for them, but the CPU gives no guarantee about it. I do not use those four flags to reason about the result.

---

## Program 1: mul2.asm (16-bit MUL)

```
mov ax, [num1]      ; AX = 3000
mul word [num2]     ; DX:AX = 3000 * 200
```

| | Decimal | Hex |
|---|---|---|
| num1 | 3000 | 0x0BB8 |
| num2 | 200 | 0x00C8 |
| Product | 600,000 | 0x000927C0 |
| DX (high) | 9 | 0x0009 |
| AX (low) | 10,176 | 0x27C0 |

GDB after `mul`: CF and OF appear in the eflags list.

| Flag | Value | Reason |
|------|-------|--------|
| CF | 1 | 600,000 exceeds 65,535, the max for 16 bits. DX holds 0x0009, which is not zero. |
| OF | 1 | MUL sets OF to the same value as CF. |
| SF, ZF, AF, PF | Undefined | MUL does not define them. |

CF = 1 warns me AX alone (10,176) is the wrong answer. The program stores AX at `result` and DX at `result+2`, so the 32-bit variable holds the full 600,000.

---

## Program 2: mul3.asm (32-bit MUL)

```
mov eax, [num1]     ; EAX = 100000
mul dword [num2]    ; EDX:EAX = 100000 * 300000
```

| | Decimal | Hex |
|---|---|---|
| num1 | 100,000 | 0x000186A0 |
| num2 | 300,000 | 0x000493E0 |
| Product | 30,000,000,000 | 0x00000006FC23AC00 |
| EDX (high) | 6 | 0x00000006 |
| EAX (low) | 4,230,196,224 | 0xFC23AC00 |

GDB after `mul`: CF and OF appear in the eflags list.

| Flag | Value | Reason |
|------|-------|--------|
| CF | 1 | 30,000,000,000 exceeds 4,294,967,295, the max for 32 bits. EDX holds 6, which is not zero. |
| OF | 1 | MUL sets OF to the same value as CF. |
| SF, ZF, AF, PF | Undefined | MUL does not define them. |

EAX alone holds 4,230,196,224, which is wrong. The program stores EAX at `result` and EDX at `result+4`, so the 64-bit variable holds the full 30,000,000,000.

With small inputs, for example 100 * 300 = 30,000, EDX would be 0 and MUL would clear CF and OF.