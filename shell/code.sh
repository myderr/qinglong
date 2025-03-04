#!/usr/bin/env bash

## 导入通用变量与函数
dir_shell=/ql/shell
. $dir_shell/share.sh

## 生成pt_pin清单
gen_pt_pin_array() {
    local tmp1 tmp2 i pt_pin_temp
    for ((user_num = 1; user_num <= $user_sum; user_num++)); do
        tmp1=Cookie$user_num
        tmp2=${!tmp1}
        i=$(($user_num - 1))
        pt_pin_temp=$(echo $tmp2 | perl -pe "{s|.*pt_pin=([^; ]+)(?=;?).*|\1|; s|%|\\\x|g}")
        [[ $pt_pin_temp == *\\x* ]] && pt_pin[i]=$(printf $pt_pin_temp) || pt_pin[i]=$pt_pin_temp
    done
}

## 导出互助码的通用程序，$1：去掉后缀的脚本名称，$2：config.sh中的后缀，$3：活动中文名称
export_codes_sub() {
    local task_name=$1
    local config_name=$2
    local chinese_name=$3
    local config_name_my=My$config_name
    local config_name_for_other=ForOther$config_name
    local i j k m n pt_pin_in_log code tmp_grep tmp_my_code tmp_for_other user_num random_num_list
    if cd $dir_log/$task_name &>/dev/null && [[ $(ls) ]]; then
        ## 寻找所有互助码以及对应的pt_pin
        i=0
        pt_pin_in_log=()
        code=()
        pt_pin_and_code=$(ls -r *.log | xargs awk -v var="的$chinese_name好友互助码" 'BEGIN{FS="[（ ）】]+"; OFS="&"} $3~var {print $2,$4}')
        for line in $pt_pin_and_code; do
            pt_pin_in_log[i]=$(echo $line | awk -F "&" '{print $1}')
            code[i]=$(echo $line | awk -F "&" '{print $2}')
            let i++
        done

        ## 输出My系列变量
        if [[ ${#code[*]} -gt 0 ]]; then
            for ((m = 0; m < ${#pt_pin[*]}; m++)); do
                tmp_my_code=""
                j=$((m + 1))
                for ((n = 0; n < ${#code[*]}; n++)); do
                    if [[ ${pt_pin[m]} == ${pt_pin_in_log[n]} ]]; then
                        tmp_my_code=${code[n]}
                        break
                    fi
                done
                echo "$config_name_my$j='$tmp_my_code'"
            done
        else
            echo "## 从日志中未找到任何互助码"
        fi

        ## 输出ForOther系列变量
        if [[ ${#code[*]} -gt 0 ]]; then
            echo
            for ((m = 0; m < ${#pt_pin[*]}; m++)); do
                tmp_for_other=""
                j=$((m + 1))
                for ((n = 0; n < $HelpType; n++)); do
                    [[ $m -eq $n ]] && continue
                    k=$((n + 1))
                    tmp_for_other="$tmp_for_other@\${$config_name_my$k}"
                done
                echo "$config_name_for_other$j=\"$tmp_for_other\"" | perl -pe "s|($config_name_for_other\d+=\")@|\1|"
            done
        fi
    else
        echo "## 未运行过 $task_name.js 脚本，未产生日志"
    fi
}

## 汇总输出
export_all_codes() {
    gen_pt_pin_array
    echo -e "\n# 从日志提取互助码，编号和配置文件中Cookie编号完全对应，如果为空就是所有日志中都没有。\n\n# 即使某个MyXxx变量未赋值，也可以将其变量名填在ForOtherXxx中，jtask脚本会自动过滤空值。\n"
    echo -n "# 你的互助人数为：$HelpType"
    for ((i = 0; i < ${#name_js[*]}; i++)); do
        echo -e "\n## ${name_chinese[i]}："
        export_codes_sub "${name_js[i]}" "${name_config[i]}" "${name_chinese[i]}"
    done
}

## 执行并写入日志
log_time=$(date "+%Y-%m-%d-%H-%M-%S")
log_path="$dir_code/$log_time.log"
make_dir "$dir_code"
export_all_codes | perl -pe "{s|京东种豆|种豆|; s|crazyJoy任务|疯狂的JOY|}" | tee $log_path
