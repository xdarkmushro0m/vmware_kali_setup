
# main.sh

```bash
rm -rf ~/bootstrap-kali && bash ~/Desktop/main.sh &&  cd ~/bootstrap-kali && sudo ansible-playbook -i ~/bootstrap-kali/inventory.ini ~/bootstrap-kali/site.yml

sudo bash /home/Desktop/main.sh
```

```bash
sudo apt update -y && sudo apt install -y ansible

mkdir ~/bootstrap-kali

# create sub directories
mkdir -p ~/bootstrap-kali/roles/ms-repo-cleanup/tasks
mkdir -p ~/bootstrap-kali/roles/desktop-cleanup/tasks
mkdir -p ~/bootstrap-kali/roles/core-tools/tasks
mkdir -p ~/bootstrap-kali/roles/pentest-tools/tasks
mkdir -p ~/bootstrap-kali/roles/vscode/tasks
mkdir -p ~/bootstrap-kali/roles/docker/tasks
mkdir -p ~/bootstrap-kali/roles/browser/tasks
mkdir -p ~/bootstrap-kali/roles/browser/defaults
mkdir -p ~/bootstrap-kali/roles/python-env/tasks
mkdir -p ~/bootstrap-kali/roles/productivity/tasks
mkdir -p ~/bootstrap-kali/roles/configs/tasks
mkdir -p ~/bootstrap-kali/roles/fonts/tasks
mkdir -p ~/bootstrap-kali/roles/fonts/handlers
mkdir -p ~/bootstrap-kali/roles/zsh_theme/tasks
mkdir -p ~/bootstrap-kali/roles/zsh_theme/handlers
mkdir -p ~/bootstrap-kali/roles/zsh/tasks
mkdir -p ~/bootstrap-kali/roles/zsh/templates
mkdir -p ~/bootstrap-kali/roles/tmux/tasks
mkdir -p ~/bootstrap-kali/roles/tmux/handlers
mkdir -p ~/bootstrap-kali/roles/vmware_mount/tasks

# inventory
cat<<'EOF' > ~/bootstrap-kali/inventory.ini
[local]
127.0.0.1 ansible_connection=local ansible_user=my
EOF

# ansible.cfg
cat<<'EOF' > ~/bootstrap-kali/ansible.cfg
[default]
inventory = /home/my/bootstrap-kali/inventory.ini
remote_user = my
ask_become_pass = false
host_key_checking = false
EOF

# site.yml
cat<<'EOF' > ~/bootstrap-kali/site.yml
---
- hosts: all
  become: true

  pre_tasks:
    - name: Remove conflicting Microsoft repo list files
      ansible.builtin.find:
        paths: /etc/apt/sources.list.d
        patterns: "*code*.list"
      register: bad_lists

    - name: Delete conflicting repo list files
      ansible.builtin.file:
        path: "{{ item.path }}"
        state: absent
      loop: "{{ bad_lists.files }}"

    - name: Remove conflicting Microsoft keyrings
      ansible.builtin.file:
        path: "{{ item }}"
        state: absent
      loop:
        - /usr/share/keyrings/microsoft.gpg
        - /etc/apt/keyrings/microsoft.gpg

  roles:
    - tmux  
    - ms-repo-cleanup
    - core-tools
    - pentest-tools
    - python-env
    - vscode
    - docker
    - browser
    - productivity
    - desktop-cleanup
    - fonts
    - vmware_mount
    - zsh
    - zsh_theme


EOF

# ms-repo-cleanup role
cat<<'EOF' > ~/bootstrap-kali/roles/ms-repo-cleanup/tasks/main.yml
---
- name: Ensure Microsoft keyrings directory exists
  ansible.builtin.file:
    path: /etc/apt/keyrings
    state: directory
    mode: '0755'

- name: Download Microsoft GPG key
  ansible.builtin.get_url:
    url: https://packages.microsoft.com/keys/microsoft.asc
    dest: /etc/apt/keyrings/microsoft.gpg
    mode: '0644'

- name: Add VSCode repository (arm64)
  ansible.builtin.apt_repository:
    repo: "deb [arch=arm64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
    state: present
    filename: "vscode"

- name: Update apt cache
  ansible.builtin.apt:
    update_cache: yes


EOF

# core-tools role
cat<<'EOF' > ~/bootstrap-kali/roles/core-tools/tasks/main.yml
---
- name: Install core utilities
  apt:
    name:
      - git
      - curl
      - wget
      - unzip
      - build-essential
      - net-tools
      - htop
      - tmux
      - zsh
      - vim
      - obsidian
      - flameshot
      - ligolo-ng
      - terminator
      - golang
      - ssh
      - bloodhound
      - neo4j
      - terminator
      - make 
      - build-essential
      - libssl-dev
      - zlib1g-dev
      - libbz2-dev
      - libreadline-dev
      - libsqlite3-dev
      - wget
      - curl
      - llvm
      - libncursesw5-dev
      - xz-utils
      - tk-dev
      - libxml2-dev
      - libxmlsec1-dev
      - libffi-dev
      - liblzma-dev
      - krb5-user
    state: present
EOF

# pentest-tools role
cat<<'EOF' > ~/bootstrap-kali/roles/pentest-tools/tasks/main.yml
---
- name: Install Burp Suite
  apt:
    name: burpsuite
    state: present

- name: Install common pentest tools
  apt:
    name:
      - nmap
      - metasploit-framework
      - john
      - hydra
      - sqlmap
      - nikto
      - gobuster
      - wfuzz
      - seclists
      - snmp-mibs-downloader
    state: present
EOF

# python-env role
cat<<'EOF' > ~/bootstrap-kali/roles/python-env/tasks/main.yml
---
- name: Install pyenv dependencies
  apt:
    name:
      - libssl-dev
      - zlib1g-dev
      - libbz2-dev
      - libreadline-dev
      - libsqlite3-dev
      - llvm
      - libncurses5-dev
      - libncursesw5-dev
      - xz-utils
      - tk-dev
      - libffi-dev
      - liblzma-dev
    state: present

- name: Clone pyenv
  git:
    repo: https://github.com/pyenv/pyenv.git
    dest: "{{ ansible_env.HOME }}/.pyenv"
    update: yes

- name: Ensure pyenv init in bashrc
  lineinfile:
    path: ~/.bashrc
    line: "{{ item }}"
    insertafter: EOF
  with_items:
    - 'export PYENV_ROOT="$HOME/.pyenv"'
    - 'export PATH="$PYENV_ROOT/bin:$PATH"'
    - 'eval "$(pyenv init --path)"'

- name: Install Python versions
  shell: pyenv install -s {{ item }}
  args:
    executable: /bin/bash
  environment:
    PYENV_ROOT: "{{ ansible_env.HOME }}/.pyenv"
    PATH: "{{ ansible_env.HOME }}/.pyenv/bin:{{ ansible_env.PATH }}"
  with_items:
    - "2.7.18"
    - "3.11.8"

- name: Set global Python version
  shell: pyenv global 3.11.8
  args:
    executable: /bin/bash
  environment:
    PYENV_ROOT: "{{ ansible_env.HOME }}/.pyenv"
    PATH: "{{ ansible_env.HOME }}/.pyenv/bin:{{ ansible_env.PATH }}"
EOF

# vscode role
cat<<'EOF' > ~/bootstrap-kali/roles/vscode/tasks/main.yml
---
- name: Install VSCode
  apt:
    name: code
    state: present
EOF

# docker role
cat<<'EOF' > ~/bootstrap-kali/roles/docker/tasks/main.yml
---
- name: Install Docker
  apt:
    name: docker.io
    state: present
EOF

# browser role
cat<<'EOF' > ~/bootstrap-kali/roles/browser/tasks/main.yml
---
# roles/browser/tasks/main.yml

- name: Install browsers
  apt:
    name:
      - firefox-esr
      - chromium
    state: present
  become: true

# --- SAFEGUARD: Set default profile name ---
- name: Set Firefox profile fact
  set_fact:
    firefox_profile: "default-release"

# --- Ensure extensions directory exists ---
- name: Ensure Firefox extensions directory exists
  file:
    path: "{{ ansible_env.HOME }}/.mozilla/firefox/{{ firefox_profile }}/extensions"
    state: directory
    mode: '0755'

# --- FoxyProxy installation ---
- name: Download FoxyProxy extension
  get_url:
    url: "https://addons.mozilla.org/firefox/downloads/latest/foxyproxy-standard/latest.xpi"
    dest: "{{ ansible_env.HOME }}/.mozilla/firefox/{{ firefox_profile }}/extensions/foxyproxy-standard@eric.h.jung.xpi"
    mode: '0644'

# --- Verification ---
- name: Verify FoxyProxy extension installed
  stat:
    path: "{{ ansible_env.HOME }}/.mozilla/firefox/{{ firefox_profile }}/extensions/foxyproxy-standard@eric.h.jung.xpi"
  register: foxyproxy_installed

- name: Debug extension status
  debug:
    msg: "FoxyProxy installed: {{ foxyproxy_installed.stat.exists }}"

EOF

cat<<'EOF' > ~/bootstrap-kali/roles/browser/defaults/main.yml
install_foxyproxy: true
EOF

# productivity role
cat<<'EOF' > ~/bootstrap-kali/roles/productivity/tasks/main.yml
---
- name: Install productivity tools
  apt:
    name: keepassxc
    state: present
EOF

# desktop-cleanup role
cat<<'EOF' > ~/bootstrap-kali/roles/desktop-cleanup/tasks/main.yml
---
- name: Disable GNOME screensaver lock
  command: gsettings set org.gnome.desktop.screensaver lock-enabled false
  become_user: "{{ ansible_user_id }}"
  when: ansible_env['XDG_CURRENT_DESKTOP'] is search("GNOME")

- name: Disable GNOME idle delay (no auto lock)
  command: gsettings set org.gnome.desktop.session idle-delay 0
  become_user: "{{ ansible_user_id }}"
  when: ansible_env['XDG_CURRENT_DESKTOP'] is search("GNOME")

- name: Disable Xfce screensaver lock
  command: xfconf-query -c xfce4-session -p /general/LockCommand -s ""
  become_user: "{{ ansible_user_id }}"
  when: ansible_env['XDG_CURRENT_DESKTOP'] is search("XFCE")
EOF

# configs setup
cat<<'EOF' > ~/bootstrap-kali/roles/configs/tasks/main.yml
---
- name: Disable screen lock in Kali
  hosts: localhost
  become: yes
  tasks:
    - name: Disable GNOME screensaver lock
      command: gsettings set org.gnome.desktop.screensaver lock-enabled false
      become_user: "{{ ansible_user_id }}"
      when: ansible_env['XDG_CURRENT_DESKTOP'] is search("GNOME")

    - name: Disable GNOME idle delay (no auto lock)
      command: gsettings set org.gnome.desktop.session idle-delay 0
      become_user: "{{ ansible_user_id }}"
      when: ansible_env['XDG_CURRENT_DESKTOP'] is search("GNOME")

    - name: Disable Xfce screensaver lock
      command: xfconf-query -c xfce4-session -p /general/LockCommand -s ""
      become_user: "{{ ansible_user_id }}"
      when: ansible_env['XDG_CURRENT_DESKTOP'] is search("XFCE")
      
- name: Download SNMP MIBs via shell
  become: true
  ansible.builtin.shell: download-mibs
  
EOF

# fonts
cat<<'EOF' > ~/bootstrap-kali/roles/fonts/tasks/main.yml
---
- name: Ensure fonts directory exists
  file:
    path: "{{ ansible_env.HOME }}/.fonts"
    state: directory

- name: Download MesloLGS NF Regular
  get_url:
    url: "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    dest: "{{ ansible_env.HOME }}/.fonts/MesloLGS NF Regular.ttf"
    mode: '0644'

- name: Download MesloLGS NF Bold
  get_url:
    url: "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    dest: "{{ ansible_env.HOME }}/.fonts/MesloLGS NF Bold.ttf"
    mode: '0644'

- name: Download MesloLGS NF Italic
  get_url:
    url: "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    dest: "{{ ansible_env.HOME }}/.fonts/MesloLGS NF Italic.ttf"
    mode: '0644'

- name: Download MesloLGS NF Bold Italic
  get_url:
    url: "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
    dest: "{{ ansible_env.HOME }}/.fonts/MesloLGS NF Bold Italic.ttf"
    mode: '0644'
  notify: Rebuild font cache

- name: Verify MesloLGS fonts are installed
  command: fc-list
  register: fc_list

- name: Report MesloLGS installation
  debug:
    msg: "MesloLGS NF fonts detected ✅"
  when: "'MesloLGS NF' in fc_list.stdout"


EOF

cat<<'EOF' > ~/bootstrap-kali/roles/fonts/handlers/main.yml
---
- name: Rebuild font cache
  command: fc-cache -f

EOF

cat<<'EOF' > ~/bootstrap-kali/roles/zsh_theme/tasks/main.yml
---
- name: Ensure oh-my-zsh custom themes directory exists
  file:
    path: "{{ ansible_env.HOME }}/.oh-my-zsh/custom/themes"
    state: directory

- name: Clone Powerlevel10k
  git:
    repo: "https://github.com/romkatv/powerlevel10k.git"
    dest: "{{ ansible_env.HOME }}/.oh-my-zsh/custom/themes/powerlevel10k"
    depth: 1
    update: yes
  notify: Reload zsh

- name: Add Powerlevel10k to .zshrc
  lineinfile:
    path: "{{ ansible_env.HOME }}/.zshrc"
    line: "source {{ ansible_env.HOME }}/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme"
    insertafter: EOF
  notify: Reload zsh

- name: Source p10k config if exists
  lineinfile:
    path: "{{ ansible_env.HOME }}/.zshrc"
    line: '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
    insertafter: EOF
  notify: Reload zsh

EOF

cat<<'EOF' > ~/bootstrap-kali/roles/zsh_theme/handlers/main.yml
---
- name: Reload zsh
  shell: "zsh -ic 'source /home/my/.zshrc'"

EOF

cat<<'EOF' > ~/bootstrap-kali/roles/tmux/tasks/main.yml
---
- name: Check if .tmux.conf exists
  stat:
    path: "{{ ansible_env.HOME }}/.tmux.conf"
  register: tmux_conf

- name: Create .tmux.conf if missing
  copy:
    src: "/home/my/Desktop/tmux.conf"
    dest: "{{ ansible_env.HOME }}/.tmux.conf"
    mode: '0644'
  when: not tmux_conf.stat.exists
  notify: Reload tmux

- name: Ensure tmux plugins directory exists
  file:
    path: "{{ ansible_env.HOME }}/.tmux/plugins"
    state: directory

- name: Clone TPM
  git:
    repo: "https://github.com/tmux-plugins/tpm"
    dest: "{{ ansible_env.HOME }}/.tmux/plugins/tpm"
    depth: 1
    update: yes
  notify: Reload tmux

- name: Deploy tmux.conf
  copy:
    src: "/home/my/Desktop/tmux.conf"
    dest: "{{ ansible_env.HOME }}/.tmux.conf"
    mode: '0644'
  notify: Reload tmux

EOF

cat<<'EOF' >  ~/bootstrap-kali/roles/tmux/handlers/main.yml
---
- name: Reload tmux
  shell: "tmux source-file ~/.tmux.conf"
  ignore_errors: yes   # avoids failure if tmux isn’t running

EOF

cat<<'EOF' > ~/bootstrap-kali/roles/zsh/tasks/main.yml
---
- name: Deploy custom .zshrc for user "my"
  copy:
    src: /home/my/Desktop/zshrc
    dest: /home/my/.zshrc
    owner: my
    group: my
    mode: '0644'

EOF

cat<<'EOF' > ~/bootstrap-kali/roles/vmware_mount/tasks/main.yml
---
- name: Ensure VMware shared folders mount point exists
  ansible.builtin.file:
    path: "/mnt/psf/"
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Add vmhgfs-fuse mount to fstab and mount it
  ansible.posix.mount:
    path: "/mnt/psf/"
    src: vmhgfs-fuse
    fstype: fuse
    opts: "defaults,allow_other,nofail,subtype=vmhgfs-fuse"
    state: mounted

- name: Mount VMware shared folder immediately
  ansible.builtin.command: >
    /usr/bin/vmhgfs-fuse .host:/ "/mnt/psf/"
    -o subtype=vmhgfs-fuse,allow_other
  args:
    creates: "/mnt/psf/"
  register: mount_cmd
  ignore_errors: true

- name: Verify that VMware shared folder is mounted
  ansible.builtin.command: mountpoint -q "/mnt/psf/"
  register: mount_check
  ignore_errors: true

- name: Report mount status
  ansible.builtin.debug:
    msg: >
      VMware shared folder Documents mount status:
      {{ 'Mounted successfully' if mount_check.rc == 0 else 'Mount failed or not present' }}

EOF

```

# zshrc

```bash
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ~/.zshrc file for zsh interactive shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

setopt autocd              # change directory just by typing its name
#setopt correct            # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

WORDCHARS='_-' # Don't consider certain characters part of the word

# hide EOL sign ('%')
PROMPT_EOL_MARK=""

# configure key keybindings
bindkey -e                                        # emacs key bindings
bindkey ' ' magic-space                           # do history expansion on space
bindkey '^U' backward-kill-line                   # ctrl + U
bindkey '^[[3;5~' kill-word                       # ctrl + Supr
bindkey '^[[3~' delete-char                       # delete
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[H' beginning-of-line                  # home
bindkey '^[[F' end-of-line                        # end
bindkey '^[[Z' undo                               # shift + tab undo last action

# enable completion features
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
#setopt share_history         # share command history data

# force zsh to show the complete history
alias history="history 0"

# configure `time` format
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

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

configure_prompt() {
    prompt_symbol=㉿
    # Skull emoji for root terminal
    #[ "$EUID" -eq 0 ] && prompt_symbol=💀
    case "$PROMPT_ALTERNATIVE" in
        twoline)
            PROMPT=$'%F{%(#.blue.green)}┌──${debian_chroot:+($debian_chroot)─}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))─}(%B%F{%(#.red.blue)}%n'$prompt_symbol$'%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\n└─%B%(#.%F{red}#.%F{blue}$)%b%F{reset} '                               
            # Right-side prompt with exit codes and background processes
            #RPROMPT=$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'
            ;;
        oneline)
            PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{%(#.red.blue)}%n@%m%b%F{reset}:%B%F{%(#.blue.green)}%~%b%F{reset}%(#.#.$) '                                                                                                                                       
            RPROMPT=
            ;;
        backtrack)
            PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{red}%n@%m%b%F{reset}:%B%F{blue}%~%b%F{reset}%(#.#.$) '
            RPROMPT=
            ;;
    esac
    unset prompt_symbol
}

# The following block is surrounded by two delimiters.
# These delimiters must not be modified. Thanks.
# START KALI CONFIG VARIABLES
PROMPT_ALTERNATIVE=twoline
NEWLINE_BEFORE_PROMPT=yes
# STOP KALI CONFIG VARIABLES

if [ "$color_prompt" = yes ]; then
    # override default virtualenv indicator in prompt
    VIRTUAL_ENV_DISABLE_PROMPT=1

    configure_prompt

    # enable syntax-highlighting
    if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
        ZSH_HIGHLIGHT_STYLES[default]=none
        ZSH_HIGHLIGHT_STYLES[unknown-token]=underline
        ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
        ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[global-alias]=fg=green,bold
        ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[path]=bold
        ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
        ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=
        ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[command-substitution]=none
        ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[process-substitution]=none
        ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta,bold
        #ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=green
        ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=green,bold
        #ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=green
        ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=green,bold
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
        #ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow,bold
        #ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow,bold
        ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[assign]=none
        ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
        #ZSH_HIGHLIGHT_STYLES[comment]=fg=yellow,bold #black,bold
        ZSH_HIGHLIGHT_STYLES[comment]=fg=magenta,bold #black,bold
        ZSH_HIGHLIGHT_STYLES[named-fd]=none
        ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
        ZSH_HIGHLIGHT_STYLES[arg0]=fg=cyan,bold
        #ZSH_HIGHLIGHT_STYLES[arg0]=fg=cyan
        ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
        ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
    fi
else
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%(#.#.$) '
fi
unset color_prompt force_color_prompt

toggle_oneline_prompt(){
    if [ "$PROMPT_ALTERNATIVE" = oneline ]; then
        PROMPT_ALTERNATIVE=twoline
    else
        PROMPT_ALTERNATIVE=oneline
    fi
    configure_prompt
    zle reset-prompt
}
zle -N toggle_oneline_prompt
bindkey ^P toggle_oneline_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty)
    TERM_TITLE=$'\e]0;${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%n@%m: %~\a'
    ;;
*)
    ;;
esac

precmd() {
    # Print the previously configured title
    print -Pnr -- "$TERM_TITLE"

    # Print a new line before the prompt, but only if it is not the first line
    if [ "$NEWLINE_BEFORE_PROMPT" = yes ]; then
        if [ -z "$_NEW_LINE_BEFORE_PROMPT" ]; then
            _NEW_LINE_BEFORE_PROMPT=1
        else
            print ""
        fi
    fi
}

# enable color support of ls, less and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    export LS_COLORS="di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:*.txt=1;37" # fix ls color for folders with 777 permissions
    #export LS_COLORS="$LS_COLORS:ow=30;44:" # fix ls color for folders with 777 permissions

    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    #export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_mb=$'\E[1;31m'   # bright red blink
    #export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_md=$'\E[1;36m'   # bright cyan bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    #export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_us=$'\E[1;32m'   # bright green underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline



    # Take advantage of $LS_COLORS for completion as well
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# enable auto-suggestions based on the history
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # change suggestion color
    #ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8,bold'
fi

# enable command-not-found if installed
if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH:/home/my/.local/share/gem/ruby/3.3.0/bin"  # Pyenv initialization
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# plugins
plugins=(git zsh-syntax-highlighting)

source /mnt/psf/Documents/lmy-vm-shared/kali_settings/.aliases

# this is create a wrapper for output coloring
# Universal cyan wrapper
cyan_wrap() {
  # Run the command with all arguments
  "$@" | sed 's/.*/\x1b[1;36m&\x1b[0m/'
}

# Universal cyan wrapper
cyan_wrap() {
  # Run the command with all arguments
  "$@" | sed 's/.*/\x1b[1;36m&\x1b[0m/'
}

# List of commands to wrap safely
# add all commands to the part of the for-loop elements
for cmd in ls cat grep snmpwalk snmpbulkwalk snmp-check dmesg tail head
do
  alias $cmd="cyan_wrap $cmd"
done

```

# tmux.conf

```bash
# create or add this to ur ~/.tmux.conf 

#set prefix
set -g prefix C-q
bind C-q send-prefix
unbind C-b

# enable mouse
setw -g mode-keys vi

set -g history-limit 100000
set -g allow-rename off

bind-key j command-prompt -p "Join pan from:" "join-pane -s :'%%'"
bind-key s command-prompt -p "Send pane to:" "join-pane -t :'%%'"

# enable mouse
set -g mouse
set-window-option -g mode-keys vi

# message display time
set-option -g display-time 4000

# reload tmux file
unbind r
bind r source-file ~/.tmux.conf

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-logging'
set -g @plugin 'tmux-plugins/tmux-yank'

# -- copy mode -----------------------------------------------------------------                                             
                                                                                                                             
bind Enter copy-mode # enter copy mode                                                                                       
                                                                                                                             
run -b 'tmux bind -t vi-copy v begin-selection 2> /dev/null || true'                                                         
run -b 'tmux bind -T copy-mode-vi v send -X begin-selection 2> /dev/null || true'                                            
run -b 'tmux bind -t vi-copy C-v rectangle-toggle 2> /dev/null || true'                                                      
run -b 'tmux bind -T copy-mode-vi C-v send -X rectangle-toggle 2> /dev/null || true'                                         
run -b 'tmux bind -t vi-copy y copy-selection 2> /dev/null || true'                                                          
run -b 'tmux bind -T copy-mode-vi y send -X copy-selection-and-cancel 2> /dev/null || true'                                  
run -b 'tmux bind -t vi-copy Escape cancel 2> /dev/null || true'                                                             
run -b 'tmux bind -T copy-mode-vi Escape send -X cancel 2> /dev/null || true'                                                
run -b 'tmux bind -t vi-copy H start-of-line 2> /dev/null || true'                                                           
run -b 'tmux bind -T copy-mode-vi H send -X start-of-line 2> /dev/null || true'                                              
run -b 'tmux bind -t vi-copy L end-of-line 2> /dev/null || true'                                                             
run -b 'tmux bind -T copy-mode-vi L send -X end-of-line 2> /dev/null || true'

# from IPPSEC - not sure what will this do
# run-shell /opt/tmux-logging/logging.tmux

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Max pane without requiring prefix key
bind-key -n M-z resize-pane -Z

set -g default-terminal "xterm-256color" # colors!

setw -g automatic-rename on   # rename window to reflect current program
set -g renumber-windows on    # renumber windows when a window is closed

set -g set-titles on          # set terminal title

set -g display-panes-time 800 # slightly longer pane indicators display time
set -g display-time 1000      # slightly longer status messages display time

set -g status-interval 10     # redraw status line every 10 seconds

# activity
set -g monitor-activity on
set -g visual-activity off

run -b '~/.tmux/plugins/tpm/tpm'

# stay in the same dir
# Set new panes to open in current directory
bind c new-window -c "#{pane_current_path}"
bind '"' split-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"

# enable mouse
setw -g mouse on

# swap winodw
bind-key < swap-window -t -1 # move window to the left
bind-key > swap-window -t +1 # move window to the right

run '~/.tmux/plugins/tpm/tpm'

```

