# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    prompt_color='\[\033[1;34m\]'
    path_color='\[\033[1;32m\]'
    if [ "$EUID" -eq 0 ]; then # Change prompt colors for root user
	prompt_color='\[\033[1;31m\]'
	path_color='\[\033[1;34m\]'
    fi
    PS1='${debian_chroot:+($debian_chroot)}'$prompt_color'\u@\h\[\033[00m\]:'$path_color'\w\[\033[00m\]\$ '
    unset prompt_color path_color
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls, less and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
######################
# CUSTOM FUNCIONS
######################

function e64 {
	if [ $# -eq 0 ]; then
	    input=$(</dev/stdin)
	else
		input=$1
	fi
	
	echo -n "$input" | base64
}

function d64 {
	if [ $# -eq 0 ]; then
	    input=$(</dev/stdin)
	else
		input=$1
	fi
	
	echo -n "$input" | base64 -d
	echo
}

function randstr {
	strings /dev/urandom | grep -o '[[:alnum:][:punct:]]' | head -n $1 | tr -d '\n'
	echo
}

function crtsh {
	curl -s "https://crt.sh/?q=%.$1&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u >> crtsh-$1.txt
}

function certspt {
	curl -s "GET https://api.certspotter.com/v1/issuances?domain=$1&expand=dns_names&expand=issuer" | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $1 >> certspotter-$1.txt
}

function gclone {
	cd $HOME/Documents/github
	if [ "$2" == "-r" ]; then
		git clone --recursive "$1"
		echo "--recursive $1" >> $HOME/Documents/github/tools.txt
	else
		git clone "$1"
		echo "$1" >> $HOME/Documents/github/tools.txt
	cd -
	fi
}

function am {
	amass enum -json $1.json -d $1
	jq .name $1.json | sed "s/\"//g"| httprobe -c 60 | tee -a $1-domains.txt
}

function hidden_ssh {
	ssh -o UserKnownHostsFile=/dev/null -T $1@$2 "bash -i"
}

function new_container {
        dd if=/dev/urandom of=~/Engagements/containers/$1 bs=1M count=51200 iflag=fullblock
        sudo cryptsetup luksFormat ~/Engagements/containers/$1
        sudo cryptsetup luksOpen ~/Engagements/containers/$1 $1
        sudo mkfs.ext4 /dev/mapper/$1
        sudo cryptsetup luksClose $1
        mkdir -p ~/Engagements/$1
}

function mount_enc {
        sudo cryptsetup luksOpen ~/Engagements/containers/$1 $1
        sudo mount -t ext4 /dev/mapper/$1 ~/Engagements/$1
        sudo chown ${USER} ~/Engagements/$1
}

function umount_enc {
        sudo umount ~/Engagements/$1
        sudo cryptsetup luksClose $1
}

function local_socks {
	ssh -N -f -D $3 $1@$2
}

function remote_socks {
	ssh -N -f -R $3 $1@$2
}

function tssh {
	if ! ssh -t $1 "tmux new -s VPS"; then
		echo 'Usage: tssh <hostalias>'
	fi
}

function hssh {
	if ! ssh -o UserKnownHostsFile=/dev/null -p $3 -t $1@$2 'bash --init-file <(echo "script -f /dev/null") -i'; then
		echo 'Usage: hssh <user> <host> <port>'
	fi
}

function sshtunnel {
	# Permit root login and tunnel on localhost
	{ sudo sed -ir -e 's/^#?PermitRootLogin .*$/PermitRootLogin yes/g' -e 's/^#?PermitTunnel .*$/PermitTunnel yes/g' /etc/ssh/sshd_config && echo 'Local config updated'
	sudo service ssh restart
	# Permit root login and tunnel on remote host
	ssh "$1" -M -S '~/.ssh/sockets/%r@%h:%p' -o ControlPersist=2m "sed -ir -e 's/^#?PermitRootLogin .*$/PermitRootLogin yes/g' -e 's/^#?PermitTunnel .*$/PermitTunnel yes/g'  /etc/ssh/sshd_config && echo 'Remote config updated'; service ssh restart"

	# Starts the tunnel connectionin background. Creates a tun interface in each end
	echo 'Starting SSH tunnel...'
	sudo ssh "$1" -i /home/odysseus/.ssh/id_rsa -f -N -w "$4:$4" && echo "Tunnel initiated. Interface tun$4 created."
	
	# Sets up the ip address for the interface, brings it up and adds the route to the internal network
	sudo ip addr add "$2/32" peer "$3" dev "tun$4" && echo "IP address $2 set up for tun$4."
	sudo ip link set "tun$4" up && echo "Interface tun$4 is up."
	sudo route add -net "$6" netmask "$7" dev "tun$4" && echo "Route to $$6 added to tun$4."
	
	# Sets up the ip address for the interface, brings it up and adds a iptables rule for NAT
	ssh "$1"  -S '~/.ssh/sockets/%r@%h:%p' -o ControlPersist=2m  "sleep 5; ip addr add \"$3/32\" peer \"$2\" dev \"tun$4\"; ip link set \"tun$4\" up; echo 1 > /proc/sys/net/ipv4/ip_forward; iptables -t nat -A POSTROUTING -s \"$2\" -o \"$5\" -j MASQUERADE" && echo "Remote interface tun$4 added and set up."
	
	} && echo "The VPN over SSH tunnel is ready." || echo "Usage: sshtunnel <root@host> <local-ip> <remote-ip> <tun-number> <remote-iface> <internal-net> <internal-mask>" 
}

function locamount {
	if [[ "$1" == "notes" ]]; then
		sshfs -o allow_other,IdentityFile=/home/odysseus/.ssh/id_odysseus elastic:/home/opsec/Engagements/notes /home/odysseus/Documents/Work/Locaweb/LocaNotes
	else
	    mkdir -p /home/odysseus/Documents/Work/Locaweb/Engagements/$1
    	sshfs -o allow_other,IdentityFile=/home/odysseus/.ssh/id_odysseus elastic:/home/opsec/Engagements/$1 /home/odysseus/Documents/Work/Locaweb/Engagements/$1
	fi
}

function encmount {
    mkdir -p /home/odysseus/Documents/Work/Engagements/"$1"
    sshfs -v -o allow_other,IdentityFile=/home/odysseus/.ssh/id_odysseus "$2":/home/ubuntu/Engagements/"$1" /home/odysseus/Documents/Work/Engagements/"$1" || echo "Usage: encmount <container-name> <vps-alias>"
}

function scTmux {
	[ ! -d "./5-logs/$4/tmuxlogs" ] && mkdir -p "./5-logs/$4/tmuxlogs"
	script -a -f -O ./5-logs/"$4"/tmuxlogs/"$1"-"$2"-"$3".log
}

function logCommands {
    jsonlog="{\"hostname\":\"$(hostname)\",\"user\":\"$(whoami)\",\"pid\":$$,\"cwd\":\"$(pwd)\",\"command\":\"$(history 1 | sed 's/^[ ]*[0-9]\+[ ]*//' )\",\"status_code\":$status_code,\"date_begin\":$date_begin,\"date_end\":$date_end,\"elapsed\":$elapsed}"
    logger -p local6.debug "$jsonlog"
}

function smartnmap {
	ports=$(nmap -n -Pn -vvv -p- --min-rate=5000 $1 | egrep -o '^[0-9]+' | tr '\n' ',' | sed s/,$//)
	echo "Found ports $ports"
	nmap -n -Pn -p $ports -sVC -vvv -oA nmap/nmap-$ports $1
}

function postweb {
	echo 'Enabling port 4242 on firewall...'
	# sudo firewall-cmd --add-port=4242/tcp
	python3 -m http.server 4242 --directory $HOME/Documents/Payloads/ >> $(tty) &
	# pid=$!
	# trap "kill $pid; echo 'Disabling port 4242 on firewall...'; sudo firewall-cmd --remove-port=4242/tcp" SIGINT
}

function show {
	echo -n "$(<$1)"
}

function md {
    mkdir "$1"
    cd "$1"
}

function cidr2list {
read -r a b c d e f g h <<< $(
ipcalc -nb "$1" | grep -oE '[0-9.]{7,}' | tr '\n .' ' '
);
eval "echo {$a..$e}.{$b..$f}.{$c..$g}.{$(($d-1))..$(($h+1))}"
} 



FGBLK=$( tput setaf 0 ) # 000000
FGRED=$( tput setaf 1 ) # ff0000
FGGRN=$( tput setaf 2 ) # 00ff00
FGYLO=$( tput setaf 3 ) # ffff00
FGBLU=$( tput setaf 4 ) # 0000ff
FGMAG=$( tput setaf 5 ) # ff00ff
FGCYN=$( tput setaf 6 ) # 00ffff
FGWHT=$( tput setaf 7 ) # ffffff

BGBLK=$( tput setab 0 ) # 000000
BGRED=$( tput setab 1 ) # ff0000
BGGRN=$( tput setab 2 ) # 00ff00
BGYLO=$( tput setab 3 ) # ffff00
BGBLU=$( tput setab 4 ) # 0000ff
BGMAG=$( tput setab 5 ) # ff00ff
BGCYN=$( tput setab 6 ) # 00ffff
BGWHT=$( tput setab 7 ) # ffffff

RESET=$( tput sgr0 )
BOLDM=$( tput bold )
UNDER=$( tput smul )
REVRS=$( tput rev )

if [ "$PS1" ]; then
  # PS1="[\u@\h:\l \W]\\$ "
  PS1="\[$FGYLO\]╭──\[$RESET\][\[$FGRED\]\u\[$FGMAG\]@\[$FGGRN\]\h\[$RESET\]]-[\[$FGBLU\]\W\[$RESET\]]\n\[$FGYLO\]╰─➤\[$RESET\] \\\$ "
fi
export EDITOR=vim
export VISUAL=vim
export MANPAGER="bat -l man -p"
export GIT=$HOME/Documents/github
export PYPROJ=/mnt/hgfs/DATA/Personal/Study/Programming/Python
source "$HOME/.cargo/env"
export PATH="/home/odysseus/.local/bin:$PATH"
export PATH="/home/odysseus/bin:$PATH"
export PATH="/usr/local/texlive/2020/bin/x86_64-linux:$PATH"
export PATH="~/go/bin:$PATH"
export PATH="/home/odysseus/.local/bin/:$PATH"
export MANPATH="/usr/local/texlive/2020/texmf-dist/doc/man:$MANPATH"
export INFOPATH="/usr/local/texlive/2020/texmf-dist/doc/info:$INFOPATH"

# Bash Pre-Exec
# https://github.com/rcaloras/bash-preexec
if [[ -f ~/.bash-preexec.sh ]]; then
    unset preexec_functions
    unset precmd_functions
    export date_begin=0
    export date_end=0

    preexec_timestamp() { 
        export date_begin=$(date +%s);
        echo -e "Begin: $(date +%Y%m%d%H%M%S)\n"; 
    }

    precmd_timestamp() { 
        export status_code="$?";
        export date_end=$(date +%s); 
        echo -e "\nEnd: $(date +%Y%m%d%H%M%S)"; 
        export elapsed=$(( $date_end-$date_begin ));
        echo "Elapsed: $elapsed seconds"; 
    }

    # Add it to the array of functions to be invoked each time.
    preexec_functions=(preexec_timestamp ${preexec_functions[@]})
    # Add it to the array of functions to be invoked each time.
    precmd_functions=(precmd_timestamp ${precmd_functions[@]})
    source ~/.bash-preexec.sh
fi
. "$HOME/.cargo/env"
