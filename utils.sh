#! /bin/bash

##################################
# Tiago's default configurations #
#                                #
# Utils methods                  #
##################################


# COPY FROM OH-MY-ZSH INSTALL.SH
# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
if [ -t 1 ]; then
  is_tty() {
    true
  }
else
  is_tty() {
    true
  }
fi

# COPY FROM OH-MY-ZSH INSTALL.SH
supports_truecolor() {
    case "$COLORTERM" in
        truecolor|24bit) return 0 ;;
    esac

    case "$TERM" in
        iterm           |\
        tmux-truecolor  |\
        linux-truecolor |\
        xterm-truecolor |\
        screen-truecolor) return 0 ;;
    esac

    return 1
}

fmt_link() {
    # $1: text, $2: url, $3: fallback mode
    if supports_hyperlinks; then
        printf '\033]8;;%s\033\\%s\033]8;;\033\\\n' "$2" "$1"
        return
    fi

    case "$3" in
        --text) printf '%s\n' "$1" ;;
        --url|*) fmt_underline "$2" ;;
    esac
}

fmt_underline() {
  is_tty && printf '\033[4m%s\033[24m\n' "$*" || printf '%s\n' "$*"
}

# shellcheck disable=SC2016 # backtick in single-quote
fmt_code() {
  is_tty && printf '`\033[2m%s\033[22m`\n' "$*" || printf '`%s`\n' "$*"
}

fmt_error() {
  printf '%sError: %s%s\n' "${FMT_BOLD}${FMT_RED}" "$*" "$FMT_RESET" >&2
}

fmt_message() {
  echo "${FMT_BLUE}-${FMT_RESET} $*"
}

fmt_title() {
  echo "${FMT_BOLD}${FMT_BLUE}::${FMT_RESET} $*${FMT_RESET}"
}

fmt_question() {
  echo -n "${FMT_BOLD}${FMT_BLUE}::${FMT_RESET} $*${FMT_RESET}"
}


setup_colors() {
  # Only use colors if connected to a terminal
  if ! is_tty; then
    FMT_RAINBOW=""
    FMT_RED=""
    FMT_GREEN=""
    FMT_YELLOW=""
    FMT_BLUE=""
    FMT_BOLD=""
    FMT_RESET=""
    return
  fi

  if supports_truecolor; then
    FMT_RAINBOW="
      $(printf '\033[38;2;255;0;0m')
      $(printf '\033[38;2;255;97;0m')
      $(printf '\033[38;2;247;255;0m')
      $(printf '\033[38;2;0;255;30m')
      $(printf '\033[38;2;77;0;255m')
      $(printf '\033[38;2;168;0;255m')
      $(printf '\033[38;2;245;0;172m')
    "
  else
    FMT_RAINBOW="
      $(printf '\033[38;5;196m')
      $(printf '\033[38;5;202m')
      $(printf '\033[38;5;226m')
      $(printf '\033[38;5;082m')
      $(printf '\033[38;5;021m')
      $(printf '\033[38;5;093m')
      $(printf '\033[38;5;163m')
    "
  fi
  FMT_RED=$(printf '\033[31m')
  FMT_GREEN=$(printf '\033[32m')
  FMT_YELLOW=$(printf '\033[33m')
  FMT_BLUE=$(printf '\033[34m')
  FMT_BOLD=$(printf '\033[1m')
  FMT_RESET=$(printf '\033[0m')
}

is_installed() {
  if yay -Qi $1 > /dev/null;
  then
    return 0
  fi
  return 1
}

install_dependencies() {
  fmt_title "Installing dependencies..."
  
  local packages="$1"
  local toInstall=()

  for pkg in ${packages[@]}
  do
    if ! is_installed $pkg;
    then
      toInstall+=($pkg)
    fi
  done

  if [[ ${toInstall[@]} != "" ]]
  then
    yay -Sy --noconfirm ${toInstall[@]} 
  fi
}
