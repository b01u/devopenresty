#!/usr/bin/env bash
# coding=utf-8
# author: b0lu
# mail: b0lu_xyz@163.com
worker_processes=$(cat /proc/cpuinfo |grep processor|wc -l)
client_header_buffer_size=`expr $(getconf PAGESIZE) / 1024`k
worker_rlimit_nofile=$(ulimit -n)
function get_suggest_params(){
    echo "worker_processes: "${worker_processes}
    echo "client_header_buffer_size: "${client_header_buffer_size}
    echo "worker_rlimit_nofile: "${worker_rlimit_nofile}
    echo -e
    echo "可使用./"$0" -f path 设置nginx配置文件参数"
}

function replace_params(){
    echo "设置nginx配置文件参数"
}

function usage(){
    echo "Usage: ./"$0" [options]"
    echo -e "\t-h | --help"
    echo -e "\t-f path\t\t:nginx config file path; Defaut: ./conf/nginx.conf"
}

if [ $# -gt 0 ]; then
    case $1 in
        -h|--help)
            usage
            ;;
        -f)
            replace_params
            ;;
        *)
            usage
            ;;
    esac
else
    echo "获取建议设置的nginx参数"
    get_suggest_params
fi

