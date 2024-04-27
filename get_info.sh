#!/bin/bash
set -u

declare -A options_array
declare -i NO_COLOR=0
readonly declare MINIMAL_PERCENT_PART_HIGHLIGHT=10

show_help() {
  set -u

  echo "Использование: $(basename "$0") [опции]"
  echo "Опции:"
  echo "  -h, --help          Показать справку (данный текст)."

  echo "  -s[аргументы раздела], --host[аргументы раздела] Показать информацию о хосте:"
  echo "    [аргументы раздела]:"
  echo "      <без аргументов> / all  показть все разделы"
  echo "       cpu                    показать данные о процессоре"
  echo "       memory                 показать данные по использованию памяти"
  echo "       disk                   показать данные о диске"
  echo "       load                   показать среднюю загрузку системы"
  echo "       time                   показать текущее время"
  echo "       uptime                 показать время работы ОС"
  echo "       network                показать информацио о сети"
  echo "       ports                  показать открытые в ОС порты"
  echo "  -u[аргументы раздела], --user[аргументы раздела] Показать информацию о пользователе:"
  echo "    [аргументы раздела]: "
  echo "      <без аргументов> / all  показать все разделы."
  echo "      root                    показать root пользователей."
  echo "      who                     показать кто сейчас онлайн."
  echo "      users                   показать список пользователей ОС."
  echo "  -n, --no_color      Не раскрашивать вывод на консоль."
  echo ""
  echo "Пример: $(basename "$0") --user=root -scpu"
  echo "        $(basename "$0") -u --host"

  set +u
}

prepare_host_info() {
  set -u

  local option=$1

  show_host_info $1

  case "${option^^}" in
    "CPU")
       show_cpu
    ;;

    "MEMORY")
       show_memory
    ;;

    "DISK")
       show_disk
    ;;

    "LOAD")
       show_load
    ;;

    "TIME")
       show_time
    ;;

    "UPTIME")
       show_uptime
    ;;

    "NETWORK")
       show_network
    ;;

    "PORTS")
       show_ports
    ;;

    *)
       show_cpu
       show_memory
       show_disk
       show_load
       show_time
       show_uptime
       show_network
       show_ports
    ;;
  esac

  set +u
}

prepare_users_info() {
  set -u

  local option=$1

  show_user_info $1

  case "${option^^}" in
    "WHO")
       show_who_online_users
    ;;

    "USERS")
       show_users_list
    ;;

    "ROOT")
       show_root_users
    ;;

    *)
       show_who_online_users
       show_users_list
       show_root_users
    ;;
  esac

  set +u
}

prepare_color_echo() {
   if [[ $NO_COLOR -eq 0 ]]; then
     echo -e "$1"
   else
      echo $(echo "$1" | sed -r 's/(\\033\[31m)|(\\033\[31m)|(\\033\[0m)//g')
       #'s/([\\]\d{1,}\[\d{1,2}m)//g')
   fi
}

show_user_info() {
  set +u

  echo -n "Информация по пользователям"

  if [ "$1" != "" ]; then prepare_color_echo ": указана опция \033[33m$1\033[0m"
    else echo "."
  fi

  echo  "------------------------------------------"
  echo  ""
  prepare_color_echo "Текущий пользователь: \033[31m${USER} (eid: ${UID})"
  prepare_color_echo "\033[0m"

}

show_host_info() {
  set +u

  echo -n "Информация по хосту"

  if [ "$1" != "" ]; then prepare_color_echo ": указана опция \033[33m$1\033[0m"
    else echo "."
  fi

  echo "-------------------"
  echo  ""

  prepare_color_echo "Текущий хост: \033[31m$(hostname)\033[0m"

}

show_cpu() {
  set -u

  echo "Информация о процессоре:"
  echo ""

  local model=$(grep '^model name' /proc/cpuinfo -m 1 | awk -F ':' '{print $2}')
  echo "Модель:$model"

  local cores=$(grep -c '^processor' /proc/cpuinfo)
  echo "Количество ядер процессора: $cores"

  local freq=$(grep '^cpu MHz' /proc/cpuinfo -m 1 | awk -F ':' '{print $2}' | tr -d ' ')
  echo "Частота: $freq"

  local cache=$(grep '^cache size' /proc/cpuinfo -m 1 | awk -F ':' '{print $2}' | tr -d ' ')
  echo "Кеш: $cache"

  echo ""

  set +u
}

show_memory() {
  set -u

  echo "Информация по использованию оперативной памяти:"
  echo ""

  local readonly RIGHT_COLUMN_WIDTH=0
  local readonly LEFT_COLUMN_WIDTH=0

  local total=$(grep '^MemTotal' /proc/meminfo | awk -F ':' '{print $2}' | tr -d ' ')
  printf "%${LEFT_COLUMN_WIDTH}s %${RIGHT_COLUMN_WIDTH}s\n" "Общий объем памяти:" "$total"

  local free=$(grep '^MemFree' /proc/meminfo | awk -F ':' '{print $2}' | tr -d ' ')
  printf "%${LEFT_COLUMN_WIDTH}s %${RIGHT_COLUMN_WIDTH}s\n" "Неиспользуемая память:" "$free"

  local avail=$(grep '^MemAvailable' /proc/meminfo | awk -F ':' '{print $2}' | tr -d ' ')
  printf "%${LEFT_COLUMN_WIDTH}s %${RIGHT_COLUMN_WIDTH}s\n" "Доступная память:" "$avail"

  local cached=$(grep '^Cached' /proc/meminfo | awk -F ':' '{print $2}' | tr -d ' ')
  printf "%${LEFT_COLUMN_WIDTH}s %${RIGHT_COLUMN_WIDTH}s\n" "Кешировано:" "$cached"

  local buffer=$(grep '^Buffers' /proc/meminfo | awk -F ':' '{print $2}' | tr -d ' ')
  printf "%${LEFT_COLUMN_WIDTH}s %${RIGHT_COLUMN_WIDTH}s\n" "В буфере:" "$buffer"

  local swap=$(grep '^SwapCache' /proc/meminfo | awk -F ':' '{print $2}' | tr -d ' ')
  printf "%${LEFT_COLUMN_WIDTH}s %${RIGHT_COLUMN_WIDTH}s\n" "В файле-подкачки:" "$swap"

  echo ""

  set +u
}

show_load() {
  set -u

  echo "Информация о средней загрузке ОС:"
  echo ""

  local load
  read -r -a load <<< $(cat /proc/loadavg)

  echo "Нагруженность системы за последние 5 минут: ${load[0]}"
  echo "Нагруженность системы за последние 10 минут: ${load[1]}"
  echo "Нагруженность системы за последние 15 минут: ${load[2]}"

  echo ""

  echo "Количество процессов в ОС: ${load[3]}"
  echo "Последний PID выделенный системой: ${load[4]}"

  echo ""

  set +u
}

show_time() {
  set -u

  local time=$(date)

  echo "Текущее время ОС: $time"
  echo ""

  set +u
}

show_disk() {
  set -u

  echo "Информация о дисках:"
  echo ""

  local devices=$(ls /dev/?d?)

  #echo $devices
  local hdd_list=( $devices )

  echo "1. Список HDD:"
  for hdd in "${hdd_list[@]}";
  do
    local hdd_size=$(fdisk -l "$hdd" | grep "^Disk $hdd" | awk -F ':' '{print $2}' | awk -F ',' '{print $1}')
    echo "Диск $hdd. Размер: ${hdd_size/' '}. Разделы:"
    #echo "  Разделы:"
    local part_list=( $(fdisk -l "$hdd" -oDevice | grep "^$hdd") )
    local sizes_list=( $(fdisk -l "$hdd" -oDevice,Size | grep "^$hdd" | awk -F ' ' '{print $2}') )
    local part_fixed_name="${hdd//\//\\/}"

    local types_list=
    mapfile -t types_list < <(fdisk -l "$hdd" -o Device,Type | grep "^$hdd" | sed -r "s/$part_fixed_name\S//g")

    declare -i ind=0
    for (( ind = 0; ind < ${#part_list[*]}; ind++ ))
    do
       local temp_var="${types_list[$ind]}"
       echo " - ${part_list[$ind]} (${sizes_list[$ind]}, ${temp_var/'  '/})"
    done
  done

  echo ""
  echo "2. Список файловых систем:"
  local fs=
  mapfile -t fs < <(df -h | grep "^/dev/")

  local mount_point=""
  local name=""
  local temp_var=0

  for detail in "${fs[@]}";
  do
     local name=$(echo "$detail" | awk '{print $1}')
     local size=$(echo "$detail" | awk '{print $2}')
     local free=$(echo "$detail" | awk '{print $4}')
     local mount_point=$(echo "$detail" | awk '{print $6}')
     local percent_free=$(echo "$detail" | awk '{print $5}')

     percent_free=$(( 100 - ${percent_free//%/} ))
     if [[ $percent_free -lt $MINIMAL_PERCENT_PART_HIGHLIGHT ]];
     then
        percent_free="\033[31m${percent_free}\033[0m"
	name="\033[31m${name}\033[0m"
        temp_var=1
     fi
     prepare_color_echo "$name (размер: $size, доступно: $free ($percent_free%), подключено к: $mount_point)"
  done  

  if [[ $NO_COLOR -ne 1 && $temp_var -eq 1 ]]; then
    echo ""
    prepare_color_echo "\033[31mЦветом\033[0m выделены разделы, у которых свободное место менее $MINIMAL_PERCENT_PART_HIGHLIGHT%."
    echo "                                                   ---------"
  fi

  echo ""

  local errors_exist=0
  echo "3. Список ошибок дисков ???:"

  local fixed_drive_name=
  for hdd in "${hdd_list[@]}";
  do  
    declare -i disk_stat_error=0
    declare -i part_stat_error=0

    fixed_drive_name=$(echo "$hdd" | sed  's/\/dev\///g')
    disk_stat_error=$(cat /proc/diskstats | grep -E "(\s$fixed_drive_name\s)" | awk '{print $13}')

    if [[ "$disk_stat_error" -gt 0 ]];
    then
       errors_exist=1
       prepare_color_echo "\033[31m$hdd ($disk_stat_error)\033[0m"
    fi

    local part_list=( $(fdisk -l "$hdd" -oDevice | grep "^$hdd") )
    for part in "${part_list[@]}";
    do  
      fixed_part_name=$(echo "$part" | sed  's/\/dev\///g')
      part_stat_error=$(cat /proc/diskstats | grep -E "(\s$fixed_part_name\s)" | awk '{print $13}')

      if [[ "$part_stat_error" -gt 0 ]];
      then
         errors_exist=1
         prepare_color_echo "\033[31m$part ($part_stat_error)\033[0m"
      fi
    done
  done

  if [[ $NO_COLOR -ne 1 && $errors_exist -eq 1 ]]; then
    echo ""
    prepare_color_echo "\033[31mЦветом\033[0m выделены разделы, у которых обнаружены ошибки в статистике."
  else
    echo "Ошибок не найдено."
  fi
  echo ""

  set +u
}

show_network() {
  set -u

  local temp_var=0

  echo "Информация о сетевых интерфейсах:"
  echo ""

  local adapters=
  mapfile -t adapters < <(cat /proc/net/dev | grep ':' | awk -F':' {'print $1'})

  echo "1. Список сетевых адаптеров:"
  local first_print_argument="%-11s %-8s %-20s %-19s %-10s %-12s %-10s"
  printf "${first_print_argument}\n" "if-name" "status" "ip" "mac" "received" "transmitted" "errors"

  for adapter in "${adapters[@]}";
  do
    adapter="${adapter//' '/}"
    local ip=$(ip addr show "${adapter}" | grep "inet\s" | awk '{print $2'})
    local mac=$(ip addr show "${adapter}" | grep "link/ether\s" | awk '{print $2'})
    #local status=$(ip addr show "$adapter" | grep "${adapter}:" | awk '{print $2'})
 
    local status=
    local state=
    local packet_in=
    local packet_out=
    local errors=0
    local errors_in=0
    local errors_out=0
    mapfile -t state < <(ip addr show "${adapter}" | grep "${adapter}:")
    state="${state//[<>]/}"
    status=$(echo "${state}" | grep -o -E '\s(state)\s\S*\s' | awk '{print $2}')

    packet_in=$(netstat -i | grep "^${adapter}\s" | awk '{print $3}')
    packet_out=$(netstat -i | grep "^${adapter}\s" | awk '{print $7}')
    errors_in=$(netstat -i | grep "^${adapter}\s" | awk '{print $4}')
    errors_out=$(netstat -i | grep "^${adapter}\s" | awk '{print $8}')

    errors=$(( $errors_in+$errors_out ))

    local first_print_argument="%-11s %-8s %-20s %-19s %-10s %-12s %-10s"

    if [[ "$status" == "DOWN" ]];
    then
       temp_var=1

       if [[ $NO_COLOR -ne 1 ]]; then
          local first_print_argument="\033[31m%-11s\033[0m \033[31m%-8s\033[0m %-20s %-19s %-10s %-12s %-10s"
       fi
    fi

    printf "${first_print_argument}\n" "${adapter}" "${status}" "${ip}" "${mac}" "${packet_in}" "${packet_out}" "${errors}"
  done

  if [[ $NO_COLOR -ne 1 && $temp_var -eq 1 ]]; then
    echo ""
    prepare_color_echo "\033[31mЦветом\033[0m выделены интерфейсы, у которых интерфейс отключен."
    echo "                                                --------"
  fi

  echo ""

  set +u
}

show_ports() {
  set -u

  echo "Информация об открытых портах:"
  echo ""

  local ports=
  mapfile -t ports < <(ss -tuln)

  for port in "${ports[@]}";
  do
	echo $port | awk '{printf $1; printf " "; print $5}'
  done

  echo ""

  set +u
}

show_uptime() {
  set -u

  local uptime=$(uptime | awk -F ',' '{print $1}')

  echo "Время работы ОС: ${uptime/' '/}"
  echo ""

  set +u
}


show_who_online_users() {
  set -u

  local users=$(who | awk '{print $1}' | uniq | sort)
  echo -n "Список активных пользователей в данный момент: "

  local out_users

  for value in $users
  do
    out_users+=",$value"
  done

  echo "${out_users}" | awk '{gsub(/^[,]+/, ""); print $0}'
  echo ""

  set +u
}

show_users_list() {
  set -u

  echo  "Список пользователей ОС:"

  echo ""

  local out_users=$(
    if [ -e /etc/shadow ]; then
       echo ""
       echo $(getent shadow | awk -F ':' '{ if (($2 == "*") || (substr($2, 0, 1) == "!")) print "*"$1; else print $1 }' | sort)
    else
       echo "Ошибка. Файла shadow в ОС нет. Будет использован passwd." >&2
       echo ""
       echo $(getent passwd | awk -F ':' '{ if (($2 == "x") || (substr($2, 0, 1) == "!"))  print "x"$1; else print $1 }' | sort)
    fi
  )

  for value in $out_users
  do
    if [[ "${value:0:1}" == "*" || "${value:0:1}" == "x" ]]; then
       prepare_color_echo "\033[31m${value:1}\033[0m"
    else echo "$value"
    fi
  done

  if [[ $NO_COLOR -ne 1 ]]; then
    echo ""
    prepare_color_echo "\033[31mЦветом\033[0m выделены пользователи, у которых отключена авторизация по паролю."
    echo "                                        ---------"
  fi

  echo ""

  set +u
}

show_root_users() {
  set -u

  echo "Список пользователей с привилегиями root:"
  echo ""

  echo "1. Список пользователей с id=0:"
  declare -a out_users
  out_users=$(grep 'x:0:' /etc/passwd | awk -F ':' '{ print $1 }')

  echo $out_users
  if [ ${#out_users[*]} -gt 1 ]; then
     prepare_color_echo "\033[33mВнимание! В ОС более одного пользователя с нулевым идентификатором.\033[0m"
  fi

  echo ""

  echo "2. Список группы sudo:"
  grep -Po '^sudo.+:\K.*$' /etc/group

  echo ""

  set +u
}

if [[ $EUID -ne 0 ]]; then
   prepare_color_echo "\033[31mЭтот скрипт должен быть запущен с правами суперпользователя.\033[0m" 
   exit 5
fi

trap "prepare_color_echo '\033[31mНеопределенная опция или параметр.\033[0m' && show_help && exit 1" ERR
OPTIONS=$(getopt -o "hu::s::n " -l "help,host:,user::,no_color" -- "$@" 2>/dev/nul)

if [[ $# -eq 0 ]]; then
  show_help
  exit 0
fi

eval set -- "$OPTIONS"

options_array[error]="false"

while true; do
  if [[ $# -eq 0 ]]; then
     break
  fi

  options_array[argument]=$1

  case "$1" in
    -n|no_color)
      NO_COLOR=1
    shift
    ;;

    -h|--help)
      options_array[help]="true"
      shift
      ;;

    -s|--host)
      if [[ (! "${2^^}" =~ ^((ALL)|(CPU)|(MEMORY)|(DISK)|(LOAD)|(TIME)|(UPTIME)|(NETWORK)|(PORT))) && ("$2" != "") ]];
      then
            prepare_color_echo "Неверная опция \033[31m$2\033[0m!"
            show_help
            exit 1
      else
            options_array[host]="true"
            options_array[host_detail]="$2"
      fi
      shift 2
      ;;

    -u|--user)
      if [[ (! "${2^^}" =~ ^((ALL)|(USERS)|(ROOT)|(WHO))) && "$2" != "" ]];
      then
            prepare_color_echo "Неверная опция \033[31m$2\033[0m!"
            show_help
            exit 1
      else
            options_array[user]="true"
            options_array[user_detail]="$2"
      fi
      shift 2
      ;;

    --)
      shift
      break ;;

    *)
      options_array[error]="true"
      break
      shift
      ;;
  esac
done

#show_help

#ПРОВЕРКА НА НАЛИЧИЕ НЕИЗВЕСТНЫХ ОПЦИЙ
set +u
if [[ "${options_array[error]}" == "true" ]]; then
    prepare_color_echo "Неправильный аргумент: \033[31m${options_array[argument]}\033[0m"
    echo  ""

    show_help
    exit 1
fi

#ПРОВЕРКА НА НАЛИЧИЕ ВОПРОСА HELP
if [[ "${options_array[help]}" == "true" ]]; then
    show_help
    exit 0
fi

#ПРОВЕРКА НА ДАННЫЕ ПО ПОЛЬЗОВАТЕЛЮ
if [[ "${options_array[user]}" == "true" ]]; then
    prepare_users_info "${options_array[user_detail]}"
fi

#ПРОВЕРКА НА ДАННЫЕ ПО ХОСТУ
if [[ "${options_array[host]}" == "true" ]]; then
    prepare_host_info "${options_array[host_detail]}"
fi

set -u
