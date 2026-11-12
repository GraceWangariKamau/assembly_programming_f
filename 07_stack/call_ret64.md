# call_ret64.asm

Calls a small function with `call` and returns with `ret`. The function adds 5 to RAX.

## Build and run

```
nasm -f elf64 -g -F dwarf call_ret64.asm -o call_ret64.o
ld call_ret64.o -o call_ret64
./call_ret64
echo $?          # 0
```

The program prints nothing. I confirmed in GDB that RAX is 15 at `after_call`.

## Execution from start to end

Let `S` be RSP at the start. In my run `S = 0x7fffffffea10`.

| Instruction | RAX | RSP after | Note |
|---|---|---|---|
| start | 0 | S | |
| `mov rax, 10` | 10 | S | |
| `call calculate` | 10 | S - 8 | pushes `0x40100a`, RIP jumps to `calculate` |
| `add rax, 5` | 15 | S - 8 | RSP unchanged |
| `ret` | 15 | S | pops `0x40100a` into RIP |
| `nop` at `after_call` | 15 | S | |
| `mov rax, 60`, `xor rdi, rdi`, `syscall` | 60 | S | exit(0) |

## How the stack works here

1. No `push` or `pop` appears in the source. The stack is still in use.
2. `call` pushes the address of the instruction after it. That address is the label `after_call`, `0x40100a`. GDB shows `x/gx $rsp` equal to `0x40100a` and resolves it to `after_call`.
3. Inside `calculate`, RSP points at the return address. The function does not change RSP.
4. `ret` pops 8 bytes from the stack into RIP. RSP rises by 8 and the CPU runs `after_call`.

## Observations

- `call` is a push plus a jump. `ret` is a pop into RIP.
- RAX changes from 10 to 15 and the change survives the return. Registers are shared between caller and callee.
- `ret` trusts whatever RSP points at. If `calculate` had pushed a value and not popped it, `ret` would jump to that value and the program would crash.
- RSP is `S` again before the `nop`. The call and return are balanced.
