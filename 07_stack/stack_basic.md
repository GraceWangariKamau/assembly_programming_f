# stack_basic.asm

Pushes two values onto the stack, then pops them back into different registers.

## Build and run

```
nasm -f elf64 -g -F dwarf stack_basic.asm -o stack_basic.o
ld stack_basic.o -o stack_basic
./stack_basic
echo $?          # 0
```

The program prints nothing. It exits with code 0. I checked it step by step in GDB (`starti`, then `stepi`, printing registers and `x/2gx $rsp`).

## Execution from start to end

Let `S` be the value of RSP when `_start` begins. In my run `S = 0x7fffffffea10`. Your address will differ. The offsets from `S` stay the same.

| Instruction | RAX | RBX | RCX | RDX | RSP after |
|---|---|---|---|---|---|
| start | 0 | 0 | 0 | 0 | S |
| `mov rax, 100` | 100 | 0 | 0 | 0 | S |
| `mov rbx, 200` | 100 | 200 | 0 | 0 | S |
| `push rax` | 100 | 200 | 0 | 0 | S - 8 |
| `push rbx` | 100 | 200 | 0 | 0 | S - 16 |
| `pop rcx` | 100 | 200 | 200 | 0 | S - 8 |
| `pop rdx` | 100 | 200 | 200 | 100 | S |
| `mov rax, 60`, `xor rdi, rdi`, `syscall` | exit(0) | | | | S |

## How the stack works here

1. `mov` instructions do not touch the stack. RSP stays at `S`.
2. `push rax` does two things. It subtracts 8 from RSP, then writes RAX (100) at the new address. The stack grows toward lower addresses.
3. `push rbx` repeats this. RSP is now `S - 16`. The value 200 sits at the top. The value 100 sits 8 bytes above it.
4. At the first `nop`, `x/2gx $rsp` shows:
   ```
   S-16:  0x00000000000000c8   (200, top of stack)
   S-8:   0x0000000000000064   (100)
   ```
5. `pop rcx` reads 8 bytes at RSP into RCX, then adds 8 to RSP. RCX gets 200.
6. `pop rdx` does the same. RDX gets 100. RSP returns to `S`.

## Observations

- The stack is last in, first out. RBX was pushed last, so it comes off first. RCX receives 200 and RDX receives 100, the reverse of the push order.
- Each push and pop moves RSP by exactly 8 bytes in 64-bit mode.
- RSP at the end equals RSP at the start. The pushes and pops are balanced.
- After the pops, the old values still sit in memory below RSP. The CPU does not erase them. They are no longer part of the stack and later pushes overwrite them.
