
#!/bin/bash

sudo apt update -y && sudo apt install -y ansible

mkdir /home/my/bootstrap-kali

# create sub directories
mkdir -p /home/my/bootstrap-kali/roles/ms-repo-cleanup/tasks
mkdir -p /home/my/bootstrap-kali/roles/desktop-cleanup/tasks
mkdir -p /home/my/bootstrap-kali/roles/core-tools/tasks
mkdir -p /home/my/bootstrap-kali/roles/pentest-tools/tasks
mkdir -p /home/my/bootstrap-kali/roles/vscode/tasks
mkdir -p /home/my/bootstrap-kali/roles/docker/tasks
mkdir -p /home/my/bootstrap-kali/roles/browser/tasks
mkdir -p /home/my/bootstrap-kali/roles/browser/defaults
mkdir -p /home/my/bootstrap-kali/roles/python-env/tasks
mkdir -p /home/my/bootstrap-kali/roles/productivity/tasks
mkdir -p /home/my/bootstrap-kali/roles/configs/tasks
mkdir -p /home/my/bootstrap-kali/roles/fonts/tasks
mkdir -p /home/my/bootstrap-kali/roles/fonts/handlers
mkdir -p /home/my/bootstrap-kali/roles/zsh_theme/tasks
mkdir -p /home/my/bootstrap-kali/roles/zsh_theme/handlers
mkdir -p /home/my/bootstrap-kali/roles/zsh/tasks
mkdir -p /home/my/bootstrap-kali/roles/zsh/templates
mkdir -p /home/my/bootstrap-kali/roles/tmux/tasks
mkdir -p /home/my/bootstrap-kali/roles/tmux/handlers
mkdir -p /home/my/bootstrap-kali/roles/vmware_mount/tasks

# inventory
cat<<'EOF' > /home/my/bootstrap-kali/inventory.ini
[local]
127.0.0.1 ansible_connection=local ansible_user=my
EOF

# ansible.cfg
cat<<'EOF' > /home/my/bootstrap-kali/ansible.cfg
[default]
inventory = /home/my/bootstrap-kali/inventory.ini
remote_user = my
ask_become_pass = false
host_key_checking = false
EOF

# site.yml
cat<<'EOF' > /home/my/bootstrap-kali/site.yml
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

    - name: Show home directory
      ansible.builtin.debug:
        msg: "Home directory is {{ ansible_env.HOME }}"
    
    - name: Show current user id
      ansible.builtin.debug:
        msg: "Current user is {{ ansible_user_id }}"

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
    #- vmware_mount
    - zsh
    - zsh_theme

EOF

# ms-repo-cleanup role
cat<<'EOF' > /home/my/bootstrap-kali/roles/ms-repo-cleanup/tasks/main.yml
---
- name: Ensure Microsoft keyrings directory exists
  ansible.builtin.file:
    path: /usr/share/keyrings
    state: directory
    mode: '0755'

- name: Download Microsoft GPG key
  ansible.builtin.get_url:
    url: https://packages.microsoft.com/keys/microsoft.asc
    dest: /usr/share/keyrings/microsoft.gpg
    mode: '0644'

- name: Add VSCode repository (arm64)
  ansible.builtin.apt_repository:
    repo: "deb [arch=arm64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
    state: present
    filename: "vscode"

- name: Update apt cache
  ansible.builtin.apt:
    update_cache: yes

EOF

# core-tools role
cat<<'EOF' > /home/my/bootstrap-kali/roles/core-tools/tasks/main.yml
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
      - build-essential
      - libssl-dev
      - zlib1g-dev
      - libncurses5-dev
      - libffi-dev
      - libsqlite3-dev
      - wget
      - curl
      - libreadline-dev
      - libbz2-dev
      - rlwrap
      - braa
      - seclists
      - dnsrecon
      - enum4linux
      - feroxbuster
      - gobuster
      - impacket-scripts
      - nbtscan
      - nikto
      - nmap
      - onesixtyone
      - oscanner
      - redis-tools
      - smbclient
      - smbmap
      - snmp
      - sslscan
      - sipvicious
      - tnscmd10g
      - whatweb
      - pipx
    state: present
EOF

# pentest-tools role
cat<<'EOF' > /home/my/bootstrap-kali/roles/pentest-tools/tasks/main.yml
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
cat<<'EOF' > /home/my/bootstrap-kali/roles/python-env/tasks/main.yml
---
- name: Install pyenv build dependencies
  become: yes
  apt:
    name:
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
      - libncurses5-dev
      - libncursesw5-dev
      - xz-utils
      - tk-dev
      - libffi-dev
      - liblzma-dev
    state: present
    update_cache: yes

- name: Clone pyenv into /home/my/.pyenv
  git:
    repo: "https://github.com/pyenv/pyenv.git"
    dest: "/home/my/.pyenv"
    update: yes
  become: false
  run_once: true

- name: Install Python versions with pyenv (under user my)
  shell: |
    export PYENV_ROOT="/home/my/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    if [ "{{ item }}" = "2.7.18" ]; then
      export CFLAGS="-std=gnu89"
    fi
    pyenv install -s {{ item }}
  args:
    executable: /bin/bash
  become: false
  environment:
    HOME: "/home/my"
  loop:
    - "2.7.18"
    - "3.11.8"

EOF

# vscode role
cat<<'EOF' > /home/my/bootstrap-kali/roles/vscode/tasks/main.yml
---
- name: Install VSCode
  apt:
    name: code
    state: present
EOF

# docker role
cat<<'EOF' > /home/my/bootstrap-kali/roles/docker/tasks/main.yml
---
- name: Install Docker
  apt:
    name: docker.io
    state: present
EOF

# browser role
cat<<'EOF' > /home/my/bootstrap-kali/roles/browser/tasks/main.yml
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
    path: "/home/my/.mozilla/firefox/{{ firefox_profile }}/extensions"
    state: directory
    mode: '0755'

# --- FoxyProxy installation ---
- name: Download FoxyProxy extension
  get_url:
    url: "https://addons.mozilla.org/firefox/downloads/latest/foxyproxy-standard/latest.xpi"
    dest: "/home/my/.mozilla/firefox/{{ firefox_profile }}/extensions/foxyproxy-standard@eric.h.jung.xpi"
    mode: '0644'

# --- Verification ---
- name: Verify FoxyProxy extension installed
  stat:
    path: "/home/my/.mozilla/firefox/{{ firefox_profile }}/extensions/foxyproxy-standard@eric.h.jung.xpi"
  register: foxyproxy_installed

- name: Debug extension status
  debug:
    msg: "FoxyProxy installed: {{ foxyproxy_installed.stat.exists }}"


EOF

cat<<'EOF' > /home/my/bootstrap-kali/roles/browser/defaults/main.yml
install_foxyproxy: true
EOF

# productivity role
cat<<'EOF' > /home/my/bootstrap-kali/roles/productivity/tasks/main.yml
---
- name: Install productivity tools
  apt:
    name: keepassxc
    state: present
EOF

# desktop-cleanup role
cat<<'EOF' > /home/my/bootstrap-kali/roles/desktop-cleanup/tasks/main.yml
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
cat<<'EOF' > /home/my/bootstrap-kali/roles/configs/tasks/main.yml
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
cat<<'EOF' > /home/my/bootstrap-kali/roles/fonts/tasks/main.yml
---
- name: Set user home directory
  set_fact:
    user_home: "/home/my"

- name: Ensure fonts directory exists
  file:
    path: "{{ user_home }}/.fonts"
    state: directory

- name: Download MesloLGS NF Regular
  get_url:
    url: "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    dest: "{{ user_home }}/.fonts/MesloLGS NF Regular.ttf"
    mode: '0644'

- name: Download MesloLGS NF Bold
  get_url:
    url: "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    dest: "{{ user_home }}/.fonts/MesloLGS NF Bold.ttf"
    mode: '0644'

- name: Download MesloLGS NF Italic
  get_url:
    url: "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    dest: "{{ user_home }}/.fonts/MesloLGS NF Italic.ttf"
    mode: '0644'

- name: Download MesloLGS NF Bold Italic
  get_url:
    url: "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
    dest: "{{ user_home }}/.fonts/MesloLGS NF Bold Italic.ttf"
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

cat<<'EOF' > /home/my/bootstrap-kali/roles/fonts/handlers/main.yml
---
- name: Rebuild font cache
  command: fc-cache -f

EOF

cat<<'EOF' > /home/my/bootstrap-kali/roles/zsh_theme/tasks/main.yml
---
- name: Ensure base home directory exists
  file:
    path: "/home/my"
    state: directory
    mode: "0755"

- name: Set user home directory
  set_fact:
    user_home: "/home/my"

- name: Ensure oh-my-zsh custom themes directory exists
  file:
    path: "{{ user_home }}/.oh-my-zsh/custom/themes"
    state: directory

- name: Clone Powerlevel10k
  git:
    repo: "https://github.com/romkatv/powerlevel10k.git"
    dest: "{{ user_home }}/.oh-my-zsh/custom/themes/powerlevel10k"
    depth: 1
    update: yes
  notify: Reload zsh

- name: Add Powerlevel10k to .zshrc
  lineinfile:
    path: "{{ user_home }}/.zshrc"
    line: "source {{ user_home }}/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme"
    insertafter: EOF
  notify: Reload zsh

- name: Source p10k config if exists
  lineinfile:
    path: "{{ user_home }}/.zshrc"
    line: '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
    insertafter: EOF
  notify: Reload zsh

EOF

cat<<'EOF' > /home/my/bootstrap-kali/roles/zsh_theme/handlers/main.yml
---
- name: Reload zsh
  shell: "zsh -ic 'source /home/my/.zshrc'"

EOF

cat<<'EOF' > /home/my/bootstrap-kali/roles/tmux/tasks/main.yml
---
- name: Check if .tmux.conf exists
  stat:
    path: "{{ ansible_env.HOME }}/.tmux.conf"
  register: tmux_conf

- name: Set user home directory
  set_fact:
    user_home: "/home/my"

- name: Create .tmux.conf if missing
  copy:
    src: "/home/my/Desktop/vmware_kali_setup-main/tmux.conf"
    dest: "{{ user_home }}/.tmux.conf"
    mode: '0644'
  when: not tmux_conf.stat.exists
  notify: Reload tmux

- name: Ensure tmux plugins directory exists
  file:
    path: "{{ user_home }}/.tmux/plugins"
    state: directory

- name: Clone TPM
  git:
    repo: "https://github.com/tmux-plugins/tpm"
    dest: "/home/my/.tmux/plugins/tpm"
    depth: 1
    update: yes
  notify: Reload tmux

- name: Deploy tmux.conf
  copy:
    src: "/home/my/Desktop/vmware_kali_setup-main/tmux.conf"
    dest: "/home/my/.tmux.conf"
    mode: '0644'
  notify: Reload tmux

EOF

cat<<'EOF' >  /home/my/bootstrap-kali/roles/tmux/handlers/main.yml
- name: Reload tmux if running
  shell: "tmux source-file /home/my/.tmux.conf"
  when: "'tmux' in ansible_env.PS1 or lookup('pipe','pgrep tmux')|length > 0"

EOF

cat<<'EOF' > /home/my/bootstrap-kali/roles/zsh/tasks/main.yml
---
- name: Deploy custom .zshrc for user "my"
  copy:
    src: /home/my/Desktop/vmware_kali_setup-main/zshrc
    dest: /home/my/.zshrc
    owner: my
    group: my
    mode: '0644'

EOF