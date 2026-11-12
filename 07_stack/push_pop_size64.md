# push_pop_size64.asm

Pushes a 64-bit value and a small value, then pops both back. The goal is to show how many bytes each push uses and how the bytes sit in memory.

## Build and run

```
nasm -f elf64 -g -F dwarf push_pop_size64.asm -o push_pop_size64.o
ld push_pop_size64.o -o push_pop_size64
./push_pop_size64
echo $?          # 0
```

The program prints nothing and exits with code 0. I inspected memory in GDB with `x/16xb $rsp`.

## Execution from start to end

Let `S` be RSP at the start. In my run `S = 0x7fffffffea00`.

| Instruction | RAX | RBX | RSP after |
|---|---|---|---|
| start | 0 | 0 | S |
| `mov rax, 0x1122334455667788` | `0x1122334455667788` | 0 | S |
| `mov rbx, 0x1234` | `0x1122334455667788` | `0x1234` | S |
| `push rax` | same | same | S - 8 |
| `push rbx` | same | same | S - 16 |
| `pop rbx` | same | `0x1234` | S - 8 |
| `pop rax` | `0x1122334455667788` | `0x1234` | S |
| `mov rax, 60`, `xor rdi, rdi`, `syscall` | 60 | `0x1234` | S |

## Stack bytes at the first `nop`

`x/16xb $rsp` printed these bytes, lowest address first:

```
S-16: 34 12 00 00 00 00 00 00     RBX = 0x0000000000001234
S-8:  88 77 66 55 44 33 22 11     RAX = 0x1122334455667788
```

## How the stack works here

1. `push rax` lowers RSP by 8 and writes all 8 bytes of RAX.
2. `push rbx` lowers RSP by 8 again. RBX holds `0x1234`, so the upper 6 bytes written are zero.
3. `pop rbx` reads the top 8 bytes, which came from the second push. RBX gets `0x1234` back. RSP rises by 8.
4. `pop rax` reads the next 8 bytes. RAX gets `0x1122334455667788` back. RSP rises by 8 and equals `S` again.

## Observations

- Each push uses 8 bytes in 64-bit mode, whatever the value size. Pushing `0x1234` still writes 8 bytes.
- x86 is little-endian. The least significant byte sits at the lowest address. `0x1122334455667788` appears as `88 77 66 ... 11`.
- The pops run in reverse order of the pushes. Because the order is reversed, each register gets its own value back.
- `mov rbx, 0x1234` assembles to a 32-bit `mov ebx`. That write zero-extends into RBX.
- `push rax`, `push rbx`, `pop rbx` and `pop rax` each encode as one byte: `50`, `53`, `5b`, `58`.
