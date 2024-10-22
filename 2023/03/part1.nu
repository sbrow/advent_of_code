#!/usr/bin/env -S nu --stdin

def main [] {
  let data = $in;
  let symbols = ($in | symbols);

  $data
  | numbers
  | filter { touches-symbol $symbols }
  | get value
  | each { into int }
  | math sum
}

def "from rg" [] {
  from json -o
  | where type == 'match'
  | get data
  | select line_number submatches
}

def "symbols" [] {
  rg --json '[^\d\.]' | from rg | reject submatches.match | flatten | flatten #| group-by line_number
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
      value: $in.match
      x: $in.start..$in.end
      y: $in.line_number
    }
  }
}

def "touches-symbol" [symbols: table]: record<value: int, x: int, y: int> -> bool {
  let number = $in;

  let touching_symbols = (
    $symbols | any { |sym|
      ($number | contains y $sym) and ($number | contains x $sym)
    }
  );

  $touching_symbols
}

def "contains x" [sym] {
  $in.x | any { |n| $n in ($sym.x)..($sym.x + 1) }
}

def "contains y" [sym] {
  $in.y in ($sym.y - 1)..($sym.y + 1)
}
