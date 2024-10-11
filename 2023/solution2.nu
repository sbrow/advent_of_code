#!/usr/bin/env -S nu --stdin

def main [] {

  open input.txt
  | lines
  | wrap text
  | insert value {
    let it = $in;
    
    (
      $it.text | parse first number | $in * 10
    ) + (
      $it.text | parse last number
    )
  } #| get value | math sum
}

def "parse first number" []: string -> int {
  parse -r '(\d|one|two|three|four|five|six|seven|eight|nine)'
  | get capture0.0
  | parse number
}

def "parse last number" [] { #: string -> int {
  | str reverse
  | parse -r '(\d|enin|thgie|neves|xis|evif|ruof|eerht|owt|eno)'
  | get capture0.0
  | parse number
}

def "parse number" []: [string -> int, int -> int] {
  match $in {
    1 | 2| 3| 4| 5| 6| 7| 8| 9 => ($in | into int),
    'one' | 'eno' => 1,
    'two' | 'owt' => 2,
    'three' | 'eerht' => 3,
    'four' | 'ruof' => 4,
    'five' | 'evif' => 5,
    'six' | 'xis' => 6,
    'seven' | 'neves' => 7,
    'eight' | 'thgie' => 8,
    'nine' | 'enin' => 9,
  }
}
