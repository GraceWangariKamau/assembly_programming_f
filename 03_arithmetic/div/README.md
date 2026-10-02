# DIV: Flags Analysis

## How DIV affects the flags

The Intel manual lists CF, OF, SF, ZF, AF and PF as undefined after DIV. DIV does not use flags to report its result. The values GDB shows after DIV are leftovers or CPU-specific behaviour. They say nothing about the quotient or remainder.

DIV reports errors through a divide error exception (#DE) instead. Linux shows it as "Floating point exception" (SIGFPE). #DE happens in two cases:

1. The divisor is 0.
2. The quotient is too large for the destination register (AX for 16-bit, EAX for 32-bit).

Before `div`, the programs run only MOV instructions. MOV does not change flags, so EFLAGS at the `div` line still holds the starting value, `0x202 [ IF ]`. Comparing eflags before and after `div` in GDB shows what my CPU does, but no program should depend on it.

| Operand size | Dividend | Quotient | Remainder |
|---|---|---|---|
| 16-bit | DX:AX | AX | DX |
| 32-bit | EDX:EAX | EAX | EDX |

---

## Program 1: div3.asm (32-bit DIV)

```
mov eax, [dividend]   ; EAX = 300000000
mov edx, [highpart]   ; EDX = 0
mov ebx, [divisor]    ; EBX = 1000
div ebx               ; EDX:EAX / EBX
```

| | Decimal | Hex |
|---|---|---|
| EDX:EAX (dividend) | 300,000,000 | 0x00000000:11E1A300 |
| EBX (divisor) | 1,000 | 0x000003E8 |
| EAX (quotient) | 300,000 | 0x000493E0 |
| EDX (remainder) | 0 | 0x00000000 |

| Flag | Value | Reason |
|------|-------|--------|
| CF, OF, SF, ZF, AF, PF | Undefined | DIV does not define any arithmetic flag. |

The remainder is 0, but DIV does not guarantee ZF = 1. To test for a zero remainder, a program needs `test edx, edx` or `cmp edx, 0` after the DIV.

No #DE occurs. The divisor is not 0, and the quotient 300,000 fits in EAX (max 4,294,967,295).

The program loads 0 into EDX on purpose. DIV treats EDX as the high 32 bits of the dividend. Leftover data in EDX would change the dividend and give a wrong quotient or a #DE.

---

## Program 2: div2.asm (16-bit DIV)

```
mov ax, [dividend]    ; AX = 50000
mov dx, [highpart]    ; DX = 0
mov bx, [divisor]     ; BX = 300
div bx                ; DX:AX / BX
```

| | Decimal | Hex |
|---|---|---|
| DX:AX (dividend) | 50,000 | 0x0000:C350 |
| BX (divisor) | 300 | 0x012C |
| AX (quotient) | 166 | 0x00A6 |
| DX (remainder) | 200 | 0x00C8 |

Check: 166 x 300 + 200 = 50,000.

| Flag | Value | Reason |
|------|-------|--------|
| CF, OF, SF, ZF, AF, PF | Undefined | DIV does not define any arithmetic flag. |

No #DE occurs. The quotient 166 fits in AX (max 65,535).

Overflow example: if DX held 300 or more, the dividend would reach 300 x 65,536 = 19,660,800. The quotient would be 65,536 or higher, too large for AX. The CPU would raise #DE and the program would crash. No flag records this case, which is why DIV leaves the flags undefined.