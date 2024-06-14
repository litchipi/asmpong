#!/usr/bin/env bash

as ./pong.s -o ./pong.o
gcc -o ./pong -nostdlib -static ./pong.o
