#!/usr/bin/env -S nu --stdin

def main [] {
  lines
  | parse 'Card {num}: {winning} | {got}' 
  | update num { into int }
  | update winning { from spaces }
  | update got { from spaces }
  | insert matches { |it|
    $in.got | filter {
      $in in $it.winning
    }    
  }
  | insert new_cards { |card|
    $in.matches
    | enumerate
    | reduce -f {} { |it, acc|
      $acc | insert $'($card.num + $it.index + 1)' 1
    }
  }
  | select num new_cards
  | reduce -f {} {|card, acc|
    let num_copies = ($acc | get $'($card.num)' -i | default 1);
    let new_cards = (
      $card.new_cards
      | transpose
      | update column1 { $in * $num_copies }
      | transpose -ird
      | if (($in | describe) =~ 'list') {
        {}
      } else {
        $in
      }
    );

    let new = (
      $new_cards
      | upsert $'($card.num)' {
        default 0 | $in + $num_copies
      });

    [
      $acc
      $new      
    ] | math sum
  } # | transpose | into int | sort-by column0 | transpose -ird 
  | values | math sum
}

def "from spaces" [] {
  split row -r ' '
  | filter { is-not-empty }
  | each { into int }
}
