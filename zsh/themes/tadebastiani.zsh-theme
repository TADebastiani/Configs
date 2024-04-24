# tadebastiani ZSH THEME
# Example:
#   ~/dir (master) 
#   ➜                                                               [22:00:00]

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg[blue]%})%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[yellow]%}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[yellow]%}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}%{$reset_color%}"


tad_git_info () {
  local ref
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  echo "${ref#refs/heads/}"
}

tad_git_files_status() {
  local result gitstatus
  gitstatus="$(command git status --porcelain -b 2>/dev/null)"

  # check status of files
  local gitfiles="$(tail -n +2 <<< "$gitstatus")"
  if [[ -n "$gitfiles" ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_DIRTY"
  #else
    #result+="$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi

  echo $result
}

tad_git_status() {
  local result gitstatus
  gitstatus="$(command git status --porcelain -b 2>/dev/null)"

  # check status of local repository
  local gitbranch="$(head -n 1 <<< "$gitstatus")"
  if [[ "$gitbranch" =~ '^## .*ahead' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_AHEAD"
  fi
  if [[ "$gitbranch" =~ '^## .*behind' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_BEHIND"
  fi

  echo $result
}

tad_git_prompt() {
  # ignore non git folders and hidden repos (adapted from lib/git.zsh)
  if ! command git rev-parse --git-dir &> /dev/null \
     || [[ "$(command git config --get oh-my-zsh.hide-info 2>/dev/null)" == 1 ]]; then
    return
  fi

  # check git information
  local gitinfo=$(tad_git_info)
  if [[ -z "$gitinfo" ]]; then
    return
  fi

  local result="${ZSH_THEME_GIT_PROMPT_PREFIX}"

  # quote % in git information
  local output="${gitinfo:gs/%/%%}"

  # check git status
  local gitstatus=$(tad_git_status)
  if [[ -n "$gitstatus" ]]; then
    output+=" $gitstatus"
  fi

  result+="${output}"
  result+="${ZSH_THEME_GIT_PROMPT_SUFFIX}"

  # check git files status
  local gitfilesstatus=$(tad_git_files_status)
  if [[ -n "$gitfilesstatus" ]]; then
    result+=" $gitfilesstatus"
  fi

  echo "$result"
}

get_spaces() {
  local STR=$1$2
  local zero='%([BSUbfksu]|([FB]|){*})'
  local LENGTH=${#${STR//$~zero/}}
  #local LENGTH=${#${(S%%)STR//$~zero/}}
  local SPACES=$(( COLUMNS - LENGTH - ${ZLE_RPROMPT_INDENT:-1} ))

  (( SPACES > 0 )) || return
  printf ' %.0s' {1..$SPACES}
}

tad_precmd() {
  local left="%{$fg[cyan]%}%10~%{$reset_color%}"
  left+=' $(tad_git_prompt)'
  #local right="[%*]"
  #local spaces="$(get_spaces $left $right)"
  #print
  #print -rP "$left$spaces$right"
  print -rP "$left"
}

setopt prompt_subst
PROMPT="%(?:%{$fg_bold[green]%}%1{➜%}:%{$fg_bold[red]%}%1{➜%})%{$reset_color%} "
RPROMPT="%{$fg[lightgray]%}[%*]%{$reset_color%}"

autoload -U add-zsh-hook
add-zsh-hook precmd tad_precmd

