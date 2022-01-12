###########################
# CUSTOM ALIASES
###########################

alias htb="cd /home/odysseus/Documents/Study/Infosec/HacktheBox"
alias htbvpn="sudo openvpn /home/odysseus/Documents/Study/Infosec/HacktheBox/OdysseusVIP.ovpn"
alias lsgit="ls -lh $HOME/Documents/github"
alias cdgit="cd $HOME/Documents/github"
alias brutefolder="python3 /home/odysseus/Documents/Study/Programming/Python/Projects/BruteFolder/brutefolder.py"
alias logparser="python3 /home/odysseus/Documents/Study/Programming/Python/Projects/LogParser/logParser.py"
alias wlgen="python3 /home/odysseus/Documents/Study/Programming/Python/Projects/WordlistGen/wordlistGen.py"
alias sitelist="python3 /home/odysseus/Documents/Study/Programming/Python/Projects/SiteList/sitelist.py"
alias brutelogin="python3 /home/odysseus/Documents/Study/Programming/Python/Projects/BruteLogin/bruteLogin.py"
alias gitupdate="$HOME/Documents/github/gitupdate.sh"
alias lsnse="ls /usr/share/nmap/scripts | tr ' ' '\n' | egrep "
alias lsnuclei="find ~/nuclei-templates/ -type f -name \"*.yaml\" | grep -Ei"
alias data="cd /mnt/hgfs/DATA"
alias cdzetels="cd /mnt/hgfs/DATA/OneDrive/Documents/MyZettelkasten"
alias update="sudo apt update && sudo apt full-upgrade"
alias checkip="while :; do clear; curl ip-api.com; sleep 5; done"
alias ipi="ifconfig| grep -Po -A1 '.*:(?= flags)|(?<=inet) ([0-9]{1,3}\.){3}[0-9]{1,3}'"
alias ipe="curl ipinfo.io/ip"
alias ls="exa -lh --icons  --classify --sort=ext --group-directories-first -S --color-scale --icons"
alias lr="exa -lR  --classify --sort=ext --group-directories-first -S --color-scale"
alias pyweb="python3 -m http.server "
alias untar="tar -zxvf"
alias wget="wget -c"
alias nmap="grc nmap"
alias cmds="cat $HOME/.tmux.conf | egrep '^cmd_'"
alias tcpdump="grc tcpdump"
alias kill_socks="ps aux | egrep 'ssh -N -f -D' | head -n1 | awk '{ print  }' | xargs kill &> /dev/null"
alias nstat="netstat -antp"
alias rd80="rdesktop -g 80%"
alias chx="chmod +x"
alias src="source $HOME/.bashrc"
alias vrc="vim $HOME/.bashrc"
alias vmux="vim $HOME/.tmux/tmux.conf"
alias wipeblanks="sed -i '/^[ \t]*$/d'"
alias clw="sed 's/^[ \t]*//g' -i"
alias nc="ncat"
alias psexec="rlwrap python3 $HOME/Documents/github/impacket/examples/psexec.py"
alias pth-winexe="pth-winexe"
alias tnew="tmux new -c /mnt/hgfs/DATA -n MISC -s"
alias ta="tmux a -t"
alias tte="tmuxinator edit"
alias tts="tmuxinator start"
alias gitdots="cd ~/dotfiles; git add .; git commit -m 'update dotfiles'; git push -u origin main; cd -"

alias dud='du -d 1 -h'
alias duf='du -sh *'
alias fd='find . -type d -name'
alias ff='find . -type f -name'

alias h='history'
alias hgrep="fc -El 0 | grep"
alias help='man'
alias p='ps -f'
alias sortnr='sort -n -r'
alias unexport='unset'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
