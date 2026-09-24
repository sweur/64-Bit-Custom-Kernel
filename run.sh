#!/bin/bash
# -nographic redirects everything (GRUB's menu, kernel VGA text output)
# straight into this terminal — no separate window, no monitor stealing
# your input.
qemu-system-x86_64 -cdrom mykernel.iso -nographic
