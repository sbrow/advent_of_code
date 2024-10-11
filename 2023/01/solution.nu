#!/usr/bin/env nu

def main [] {
  open input.txt
  | lines
  | each {
    str replace --all -r '[^\d]' ''
    | split chars
    | $'($in | first)($in | last)'
    | into int
  } | math sum
}
