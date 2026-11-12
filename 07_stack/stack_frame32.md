# stack_frame32.asm

The 32-bit (i386) version of a stack frame. It uses EBP and ESP, 4-byte slots, and exits with `int 0x80`.

## Build and run

```
nasm -f elf32 -g -F dwarf stack_frame32.asm -o stack_frame32.o
ld -m elf_i386 stack_frame32.o -o stack_frame32
./stack_frame32
echo $?          # 0
```

The program prints nothing and exits with code 0. I stepped through it in GDB.

## Execution from start to end

Let `S` be ESP at the start of `_start`. In my run `S = 0xffffdb20`. EBP starts at 0.

| Instruction | ESP after | EBP after | Note |
|---|---|---|---|
| start | S | 0 | |
| `call work` | S - 4 | 0 | pushes return address `0x08049005` |
| `push ebp` | S - 8 | 0 | saves old EBP |
| `mov ebp, esp` | S - 8 | S - 8 | frame base |
| `sub esp, 8` | S - 16 | S - 8 | reserves 8 bytes |
| `mov dword [ebp - 4], 100` | S - 16 | S - 8 | store |
| `mov dword [ebp - 8], 200` | S - 16 | S - 8 | store |
| `mov eax, [ebp - 4]` | S - 16 | S - 8 | EAX = 100 |
| `mov ebx, [ebp - 8]` | S - 16 | S - 8 | EBX = 200 |
| `mov esp, ebp` | S - 8 | S - 8 | frees locals |
| `pop ebp` | S - 4 | 0 | restores EBP |
| `ret` | S | 0 | pops `0x08049005` into EIP |
| `mov eax, 1`, `xor ebx, ebx`, `int 0x80` | S | 0 | exit(0) |

## Stack layout at the first `nop`

Values from my run:

```
0xffffdb1c  0x08049005   return address
0xffffdb18  0x00000000   saved EBP      <- EBP
0xffffdb14  0x00000064   [ebp - 4] = 100
0xffffdb10  0x000000c8   [ebp - 8] = 200   <- ESP
```

## How the stack works here

1. `call` pushes a 4-byte return address. ESP drops by 4.
2. `push ebp` saves the caller's EBP. ESP drops by 4.
3. `mov ebp, esp` sets the frame base. `sub esp, 8` reserves room for two 4-byte locals.
4. The locals sit at `ebp - 4` and `ebp - 8`. The stores do not move ESP.
5. `mov esp, ebp` and `pop ebp` undo the frame. `ret` pops the return address into EIP.

## Observations

- Every slot is 4 bytes. In the 64-bit version every slot is 8 bytes. The structure is the same.
- ESP at the end is `S`, the same as at the start.
- The exit uses `int 0x80` with EAX = 1. The 64-bit programs use `syscall` with RAX = 60.
- The file needs `BITS 32` and `-f elf32`. It links with `ld -m elf_i386`. A 64-bit build would fail or behave incorrectly.
