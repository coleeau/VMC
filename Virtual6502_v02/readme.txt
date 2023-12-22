Title:		Virtual6502
Author:		Rich Whitehouse
Date:		2007-05-31
Version:	0.2
Homepage:	http://www.telefragged.com/thefatal/
----------------------------------------------------
Virtual6502 is a multi-purpose emulator for the 6502
microprocessor.

Virtual6502 has many unique features, such as:

-A unique plugin system. Plugin modules can be dropped in the
 modules subfolder, and they will be loaded and run automatically.
 Modules have many nice features. They can act as video/audio
 processing devices, observing the CPU context and memory map,
 and they can even override Virtual6502's handling of opcodes.
 This means a custom module can properly interpet undocumented
 instructions for a specific platform, while acting as the audio
 and video processor for it at the same time, or any number of
 other possibilities.
-A built-in disassembler, which can instantly seek and interpret
 from any point in the 6502 binary, as well as a memory viewer
 with similar capabilities.
-Robust debugging functionality. Data breakpoints are supported,
 as well as standard program counter breakpoints. Breakpoints
 are also saved off with their relative address settings when you
 exit Virtual6502, so you don't have to worry about setting them
 all up again the next time you want to test your binary.
-Register and status windows for all of the CPU's context members.
 You can modify them in real-time, and your changes will be
 effective immediately. You can also modify memory, including in
 blocks through the convenient modify feature.
-You're able to break into debugging at any point during execution,
 single-step through instructions, and modify breakpoints, memory,
 and other values even during normal execution.
-You have the ability to choose custom cycle and tick rates for
 the CPU.

I have been using this extensively in my Commodore64 development. I
haven't tested all of the instructions in all addressing modes,
though, so my CPU emulation may or may not still have bugs in it.
Feel free to let me know if you find any problems.

Additionally, source code for a basic framework for plugin modules
is included in the archive. There is also a crude plugin module
in the modules folder, which needs to be renamed (just rename it
to plugin_c64multi.dll) to do anything inside Virtual6502. When it's
enabled, it acts as a poorly implemented renderer for the Commodore
64's multi-color bitmap mode (it is hardcoded to this mode, it
doesn't look at the actual registers or anything). This probably
won't be useful to you unless you also happen to be writing C64
software with this video mode, but it's there more for the purpose
of demonstration.

Version History
---------------
0.2:
-Attempted fix to get rid of unrecognizable characters displayed
 on some systems (presumably relating to unicode support).

0.1:
-Initial release.
