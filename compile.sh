#!/usr/bin/env bash

set -e

nasm -f elf64 ./pong.asm -o ./pong.o
ld ./pong.o -o ./pong
