# History: large, shared live between open shells, no duplicates, timestamps kept.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY       # start time and duration per entry
setopt SHARE_HISTORY          # every shell sees new lines from the others
setopt HIST_IGNORE_ALL_DUPS   # a repeated command replaces its older copy
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE      # a command starting with a space is not saved
setopt HIST_VERIFY            # !! and friends are shown before they run
