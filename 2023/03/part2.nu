#!/usr/bin/env -S nu --stdin

def main [] {
  let data = $in;

  let gears = ($in | gears);

  let lines = ($data | lines);

  $gears
  | insert lines { |it|
    $lines | range ($it.y - 2)..($it.y) | str join "\n"
  }
  | insert numbers { |gear|
    $gear.lines | numbers | touches-gear $gear
  }
  | reject lines
  | filter { ($in.numbers | length)  == 2 }
  | each {
    $in.numbers | get value | math product
  }
  | math sum
}

def "from rg" [] {
  from json -o
  | where type == 'match'
  | get data
  | select line_number submatches
}

def "gears" [] {
  rg --json '\*' | from rg | reject submatches.match | flatten | flatten
  | each { |it|
    {
      x: $it.start
      y: $it.line_number
    }
  }
}

def "numbers" [] {
  rg --json '\d+' | from rg | flatten | update submatches.match { get text }
  | flatten
  | each {
    {
      value: ($in.match | into int)
      x: ($in.start - 1)..$in.end
      y: $in.line_number
    }
  }
}

def "touches-gear" [gear: record<x: int, y: int>]: table -> table {
  filter {
    $gear.x in $in.x
  }
}

def "contains x" [sym] {
  $in.x | any { |n| $n in ($sym.x)..($sym.x + 1) }
}

# def "contains y" [sym] {
#   $in.y in ($sym.y - 1)..($sym.y + 1)
# }
