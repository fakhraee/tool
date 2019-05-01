#!/usr/bin/env fish

function help -d 'show help'
  echo inf.fish \
       [-i interval] [-p "print_something_every_loop"] [command_to_run]
  exit
end


function main
  set interval 1
  set options 'h/help' 'i/interval=' 'p/print='
  argparse -n whiler $options -- $argv; or return

  set -q _flag_help; or test -z "$argv"; and help
  set -q _flag_interval; and set -g interval $_flag_interval
  set -q _flag_print; and set -g print $_flag_print

  whiler $argv
end


function whiler -d 'the while'
  while true
    command $argv
    set -q print; and echo -e $print
    sleep $interval
  end
end


main $argv
