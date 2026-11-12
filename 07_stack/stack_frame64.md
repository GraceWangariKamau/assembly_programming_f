# stack_frame64.asm

Calls a function that builds a stack frame, stores two local variables, reads them back, and tears the frame down.

## Build and run

```
nasm -f elf64 -g -F dwarf stack_frame64.asm -o stack_frame64.o
ld stack_frame64.o -o stack_frame64
./stack_frame64
echo $?          # 0
```

The program prints nothing and exits with code 0. I stepped through it in GDB and printed RAX, RBX, RBP, RSP and memory at each instruction.

## Execution from start to end

Let `S` be RSP at the start of `_start`. In my run `S = 0x7fffffffea10`. RBP starts at 0 because `_start` has no caller.

| Instruction | RSP after | RBP after | Note |
|---|---|---|---|
| start of `_start` | S | 0 | |
| `call work` | S - 8 | 0 | pushes return address `0x401005` |
| `push rbp` | S - 16 | 0 | saves old RBP (0) |
| `mov rbp, rsp` | S - 16 | S - 16 | RBP now marks the frame |
| `sub rsp, 16` | S - 32 | S - 16 | reserves 16 bytes of locals |
| `mov qword [rbp - 8], 100` | S - 32 | S - 16 | store, RSP unchanged |
| `mov qword [rbp - 16], 200` | S - 32 | S - 16 | store, RSP unchanged |
| `mov rax, [rbp - 8]` | S - 32 | S - 16 | RAX = 100 |
| `mov rbx, [rbp - 16]` | S - 32 | S - 16 | RBX = 200 |
| `mov rsp, rbp` | S - 16 | S - 16 | frees the locals |
| `pop rbp` | S - 8 | 0 | restores caller RBP |
| `ret` | S | 0 | pops `0x401005` into RIP |
| `mov rax, 60`, `xor rdi, rdi`, `syscall` | S | 0 | exit(0) |

## Stack layout at the first `nop`

Values from my run (`S = 0x7fffffffea10`):

```
0x7fffffffea08  0x0000000000401005   return address (pushed by call)
0x7fffffffea00  0x0000000000000000   saved RBP      <- RBP
0x7fffffffe9f8  0x0000000000000064   [rbp - 8]  = 100
0x7fffffffe9f0  0x00000000000000c8   [rbp - 16] = 200   <- RSP
```

## How the stack works here

1. `call work` pushes the address of the next instruction (`mov rax, 60`) and jumps to `work`. RSP drops by 8.
2. `push rbp` saves the caller's frame pointer. RSP drops by 8 again.
3. `mov rbp, rsp` copies RSP into RBP. RBP stays fixed for the whole function. Locals are reached at fixed offsets from it.
4. `sub rsp, 16` moves RSP down to make room for two 8-byte locals. Nothing is pushed. The space is just reserved.
5. The two `mov qword` stores write into that space using RBP-relative addresses. RSP does not move.
6. `mov rsp, rbp` throws the locals away by moving RSP back up to the saved RBP.
7. `pop rbp` restores the caller's RBP and raises RSP by 8.
8. `ret` pops the return address into RIP and raises RSP by 8. Execution continues at `mov rax, 60`.

## Observations

- RSP at the end equals RSP at the start of `_start`. Every byte taken was returned.
- The registers still hold RAX = 100 and RBX = 200 after the function returns. Only the stack memory is discarded.
- The order in memory is return address, saved RBP, then locals, from high to low address.
- Saved RBP is 0 because `_start` is the first code to run. No earlier frame exists.
- Using `mov rsp, rbp` before `pop rbp` works even if RSP changed inside the function. The `leave` instruction does the same two steps.
