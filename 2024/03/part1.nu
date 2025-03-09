#!/usr/bin/env nu

def main [] {
  (
    # rg 'mul\((\d{1,3}),(\d{1,3})\)' -o
    rg 'mul\((\d{1,3}),(\d{1,3})\)' --json
    | from json -o
    | where type == 'match'
    | get data.submatches
    | flatten
    | get match.text
    | parse 'mul({a},{b})'
    | each {
      ($in.a | into int) * ($in.b | into int)
    }
    | math sum
  )
}
