# push_pop_size32.asm

The 32-bit version of the push and pop size test. It uses EAX, EBX and ESP.

## Build and run

```
nasm -f elf32 -g -F dwarf push_pop_size32.asm -o push_pop_size32.o
ld -m elf_i386 push_pop_size32.o -o push_pop_size32
./push_pop_size32
echo $?          # 0
```

The program prints nothing and exits with code 0. I inspected memory in GDB with `x/8xb $esp`.

## Execution from start to end

Let `S` be ESP at the start. In my run `S = 0xffffdb10`.

| Instruction | EAX | EBX | ESP after |
|---|---|---|---|
| start | 0 | 0 | S |
| `mov eax, 0x11223344` | `0x11223344` | 0 | S |
| `mov ebx, 0x1234` | `0x11223344` | `0x1234` | S |
| `push eax` | same | same | S - 4 |
| `push ebx` | same | same | S - 8 |
| `pop ebx` | same | `0x1234` | S - 4 |
| `pop eax` | `0x11223344` | `0x1234` | S |
| `mov eax, 1`, `xor ebx, ebx`, `int 0x80` | 1 | 0 | S |

## Stack bytes at the first `nop`

`x/8xb $esp` printed these bytes, lowest address first:

```
S-8: 34 12 00 00     EBX = 0x00001234
S-4: 44 33 22 11     EAX = 0x11223344
```

## How the stack works here

1. `push eax` lowers ESP by 4 and writes 4 bytes.
2. `push ebx` lowers ESP by 4 and writes 4 bytes. The upper two bytes are zero.
3. `pop ebx` reads the top 4 bytes into EBX and raises ESP by 4.
4. `pop eax` reads the next 4 bytes into EAX and raises ESP by 4. ESP equals `S` again.

## Observations

- Each push and pop moves ESP by 4. The 64-bit version moves RSP by 8.
- The byte order is little-endian. `0x11223344` appears as `44 33 22 11`.
- The opcodes are the same as in the 64-bit file: `50`, `53`, `5b`, `58`. The CPU mode sets the operand size.
- Before the exit, EAX holds `0x11223344` and EBX holds `0x1234`. The program then overwrites both with `mov eax, 1` and `xor ebx, ebx` for `int 0x80`.
- The exit uses `int 0x80` with EAX = 1. The sys_exit status comes from EBX, which is 0.
