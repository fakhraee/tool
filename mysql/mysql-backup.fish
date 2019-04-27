#!/usr/bin/env fish

function help -d 'show help'
  echo \
  --login,\t\t-l\t\t[user:pass]\n\
  \b--server,\t\t-s\t\t[server:port]\n\
    \t'-s' 1.2.3.4:3306\n\t'-s' 1.2.3.4\n\t-s :3307\n\
  \b--interval,\t-i\t\t[table_name]
  exit
end


function main
  set options 'h/help' 's/server=' 'l/login=' 'i/interval=' \
              'e/send=' 'c/clean=' 'v/verbose' 'n/dryrun'
  argparse -n mysql-backup $options -- $argv; or return

  set -q _flag_help; and help
  set -q _flag_verbose; and set -g verbose
  set -q _flag_dryrun; and set -g dryrun
  if set -q _flag_server
    set server_array (string split -m1 : $_flag_server)
    set -g server_name $server_array[1]
    set -g server_port $server_array[2]
  end
  if set -q _flag_login
    set login_array (string split -m1 : $_flag_login)
    set -g login_user $login_array[1]
    set -g login_pass $login_array[2]
  end
  set -g interval $_flag_interval
  set -g mysqldump /usr/bin/mysqldump
  test -z "$server_name"; and set -g server_name '127.0.0.1'
  if test -z "$server_port"; or test "$server_port" = "$server_name"
    set -g server_port '3306'
  end
  test -z "$login_user"; and set -g login_user 'root'
  if set -q _flag_send
    set send_array (string split -m1 : $_flag_send)
    set -g rsync_exec $send_array[1]
    set -g rsync_dest $send_array[2]
  end
  if set -q _flag_interval
    interval $_flag_interval $argv
  else
    mysql_dump $argv
  end
end


function mysql_dump -d 'the backup'
  set mydump $mysqldump --single-transaction \
                        -u$login_user -h$server_name -P $server_port
  test -n "$login_pass"; and set -a mydump "-p$login_pass"
  set backup_file $server_name

  if test -z "$argv"
    set -a mydump --all-databases
    set backup_file {$backup_file}_all
  else
    set backup_file {$server_name}_not-all
  end
  set backup_file {$backup_file}_(date +%y%m%d-%H%M).sql.bz2
  if set -q verbose
    echo
    echo dump cmd: $mydump $argv ">" $backup_file
    echo dumping...

  end
  if not set -q dryrun
    eval ($mydump $argv | bzip2 > "$backup_file")
  end

  if set -q rsync_dest
    set send_rsync rsync -az $backup_file -e {$rsync_exec} {$rsync_dest}
    if set -q verbose
      echo send cmd: $send_rsync
      echo sending...
    end
    if not set -q dryrun
      eval ($send_rsync)
    end
  end
end

function interval
  while true
    mysql_dump $argv[2..-1]
    echo sleeping for $argv[1] on (date +%H:%M)...
    sleep $argv[1]
  end
end


function clean_up -d 'remove older than'
  #find $path -maxdepth 1 -iname "*.sql.bz2" -mtime 2.5 -delete
end


main $argv
