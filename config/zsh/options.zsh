# Shell options (zshoptions(1)).
setopt AUTO_CD               # a directory name alone changes into it
setopt AUTO_PUSHD            # cd pushes onto the directory stack (cd -<Tab> lists it)
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt INTERACTIVE_COMMENTS  # allow # comments on the command line
setopt EXTENDED_GLOB
setopt NO_BEEP
setopt NO_FLOW_CONTROL       # frees Ctrl+S / Ctrl+Q (Ctrl+S searches the completion menu)
