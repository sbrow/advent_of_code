#!/usr/bin/env -S nu --stdin

def main [] {
  split row "\n\n"
  | skip 1
  | each {
    lines
    #str replace -r '(?<from>[a-z]+)-to-(?<to>[a-z]+) map:' '${1} ${2}'
  }
  | each { |it|
    first
    | parse '{from}-to-{to} map:'
    | first
  }
}
