#!/bin/bash
if [ ! -f ~/.bashrc ]; then
  tee ~/.bashrc <<EOF
# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi
# User specific aliases and functions
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
export PATH="\$HOME/.local/bin:\$PATH"
EOF
fi
