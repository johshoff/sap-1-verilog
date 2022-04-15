This is an implementation of [Ben
Eater](https://www.youtube.com/c/BenEater/videos)'s Simple As Possible
architecture SAP-1.

**This is my first foray into Verilog and FPGA**. As such, there are probably
numerous errors and problems with the way I've done it. I had fun doing it,
though, and maybe you'll find it interesting too. The assembler was quickly
thrown together and has numerous known and unknown bugs.

There are some small deviations from the videos:

- the clock is much simpler here, since it's been running in a simulator (so
  far),
- there are added instructions `jnc` and `jz` as suggested by [Scott
  Shambaugh](https://theshamblog.com/programs-and-more-commands-for-the-ben-eater-8-bit-breadboard-computer/),
- the FI (flags in) is being inferred from ∑O (ALU read), and instead I use it
  to reset the micro instruction counter, to speed up the execusion,
- the exact memory layout on the ROM is slightly different,
- the naming is different in many places I mostly did it from memory,
- and probably more...

Finally, a huge thanks to Ben Eater for making his video series and also to
Stefan for his game [Turing Complete](https://turingcomplete.game/). I wouldn't
have been able to do this without both of them.

## Running

Running this requires a Verilog simulator. I've only used [Icarus
Verilog](http://iverilog.icarus.com/).

To run, simply run

    make

in the root folder of the project. It should run show the Fibonacci sequence:

    OUT   0
    OUT   1
    OUT   2
    OUT   3
    OUT   5
    OUT   8
    OUT  13
    OUT  21
    OUT  34
    OUT  55
    OUT  89
    OUT 144
    OUT 233
    cpu.v:204: $finish called at 552 (1s)
