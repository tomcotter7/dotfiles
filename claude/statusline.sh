#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
TOK=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd' | cut -c1-4)
VIM_MODE=$(echo "$input" | jq -r '.vim.mode // ""')
EFFORT_LEVEL=$(echo "$input" | jq -r '.effort.level')

# Separator lives inside VIM_DISPLAY so the field vanishes cleanly when vim
# mode is off and .vim is absent from the input.
case "$VIM_MODE" in
    NORMAL) VIM_DISPLAY=" | \033[31mNORMAL\033[0m" ;;
    INSERT) VIM_DISPLAY=" | \033[32mINSERT\033[0m" ;;
    VISUAL) VIM_DISPLAY=" | \033[33mVISUAL\033[0m" ;;
    "")     VIM_DISPLAY="" ;;
    *)      VIM_DISPLAY=" | $VIM_MODE" ;;
esac

if [ "$TOK" -ge 500000 ]; then
    CTX_COLOUR="\033[31m"
elif [ "$TOK" -ge 200000 ]; then
    CTX_COLOUR="\033[38;5;208m"
else
    CTX_COLOUR="\033[32m"
fi

TOK_K=$(( TOK / 1000 ))

printf "\033[36m%s\033[0m | %s - %s | ${CTX_COLOUR}%dk (%s%%)\033[0m | \$%s%b" \
    "$(basename "$DIR")" "$MODEL" "$EFFORT_LEVEL" "$TOK_K" "$PCT" "$COST" "$VIM_DISPLAY"
