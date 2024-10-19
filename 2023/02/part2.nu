#!/usr/bin/env -S nu --stdin

def main [] { 
  parse games
  | get-max
  | get-power
  | math sum
}

def "parse games" []: string -> table {
  lines
  | parse 'Game {id}: {turns}'
  | update id { into int }
  | update turns {
    split row ';'
    | each {
      parse -r '(\d+) (red|green|blue)'
      | reduce -f { red: 0 green: 0 blue: 0 } {|it, acc|
        $acc | update $it.capture1 ($it.capture0 | into int)
      }
    }
  }
}

def get-max []: table -> table {
  update turns { math max }
  | each {
    {
      id: $in.id
      red: $in.turns.red
      green: $in.turns.green
      blue: $in.turns.blue
    }
  }
}

def "get-power" [] {
  reject id
  | each { values | math product }
}
