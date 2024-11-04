#!/usr/bin/env -S nu --stdin

def main [] {
  lines
  | parse 'Card {card_no}: {winning} | {got}' 
  | update winning { from spaces }
  | update got { from spaces }
  | insert matches { |it|
    $in.got | filter {
      $in in $it.winning
    }    
  }
  | insert score {
    let length = ($in.matches | length);

    if ($length > 0) {
      2 ** ($length - 1)
    } else {
      0
    }
  }
  | get score
  | math sum
}

def "from spaces" [] {
  split row -r ' '
  | filter { is-not-empty }
  | each { into int }
}
