#!/usr/bin/env bash

set -e

nasm -f elf64 -F dwarf -g ./pong.asm -o ./pong.o
ld ./pong.o -o ./pong

nasm -f elf64 -F dwarf -g ./inputs.asm -o ./inputs.o
ld ./inputs.o -o ./inputs
