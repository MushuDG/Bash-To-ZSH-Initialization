#!/bin/bash
#################################################################################
# General information                                                           #
#################################################################################
# Author:               MushuDG                                                 #
# Project:              Bash-To-ZSH-Initialization                              #
# File:                 install.sh                                              #
# Creation date:        18.03.2024                                              #
# Modification date:    16.02.2026                                              #
# Description:          Script managing the initialization process for          #
#                       transitioning from Bash to Zsh shell environment.       #
#################################################################################

#################################################################################
# Global variables and constants                                                #
#################################################################################
PACKAGE_MANAGER=""  # Detected package manager (e.g., "apt", "pacman", "brew")
PM_UPDATE_CMD=""    # Command to update package lists (e.g., "sudo apt-get update")
PM_INSTALL_CMD=""   # Command to install packages (e.g., "sudo apt-get install -y")
USE_PYWAL=0         # Flag indicating whether the user uses Pywal (0 = no, 1 = yes)


#################################################################################
# Spinner                                                                       #
#################################################################################
# Description:  Displays a spinner animation while a process is running.        #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
spinner() {
    # Local variables for spinner function
    local pid="$1"                                      # PID of the process to wait for
    local delay=0.1                                     # Delay between spinner updates (in seconds)
    local spinstr=('⣷' '⣯' '⣟' '⡿' '⢿' '⣻' '⣽' '⣾') # Spinner characters (8 frames for smoother animation)
    local i=0                                           # Index for spinner array
    local n=${#spinstr[@]}                              # Number of spinner frames

    # Hide cursor and set up trap to restore it on exit
    tput civis
    trap "tput cnorm; exit" INT TERM

    # Loop until the process with the given PID finishes
    while kill -0 "$pid" 2>/dev/null; do
        printf " [%s]  " "${spinstr[i]}"
        i=$(( (i + 1) % n ))
        sleep "$delay"
        printf "\b\b\b\b\b\b"
    done

    # Restore cursor and clear spinner
    trap - INT TERM
    tput cnorm
    printf "    \b\b\b\b"
}


#################################################################################
# verify_root_permissions                                                       #
#################################################################################
# Description:  Checks if the script is being run with root privileges. If not, #
#               it prompts the user to enter their password to gain temporary   #
#               root access.                                                    #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
verify_root_permissions(){
    # Check if the script is running as root (EUID 0). If not, prompt for sudo access.
    if [[ $EUID -ne 0 ]]; then
        echo "This script requires root privileges to perform certain tasks."
        sudo echo ""
    fi
}


#################################################################################
# ask_for_pywal                                                                 #
#################################################################################
# Description:  Asks the user if they are using Pywal and applies the necessary #
#               configurations to the .zshrc file if they are.                  #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
ask_for_pywal() {
    # Prompt the user to check if they are using Pywal and set the USE_PYWAL flag accordingly
    echo "Are you using Pywal? [Y/n] (default: N)"
    read -r use_pywal

    # Default to "N" if the user just presses Enter
    if [[ $use_pywal == "Y" || $use_pywal == "y" ]]; then
        USE_PYWAL=1
        echo "Pywal will be enabled in ~/.zshrc."
    else
        USE_PYWAL=0
        echo "Pywal configurations not applied."
    fi
}


#################################################################################
# update_and_install_packages                                                   #
#################################################################################
# Description:  Updates package lists and installs packages silently.           #
#               Shows full logs ONLY if something fails.                        #
#                                                                               #
# Args:         1) $1: package manager id: "apt" | "pacman" | "brew"            #
#               2) $2: update command (string)                                  #
#               3) $3: install command (string)                                 #
#               4..n) $@: packages to install                                   #
# Returns:      - None                                                          #
#################################################################################
update_and_install_packages() {
    # Local variables for package installation function
    local pm="$1"               # Package manager identifier (e.g., "apt", "pacman", "brew")
    local update_command="$2"   # Command to update package lists (e.g., "sudo apt-get update")
    local install_command="$3"  # Command to install packages (e.g., "sudo apt-get install -y")
    shift 3                     # Shift the first three arguments so that "$@" now contains only the package names to install
    local -a packages=( "$@" )  # Array of packages to install (remaining arguments)
    
    # Local variables for logging and tracking installation status
    local log pid rc                # Log file for command output, PID of background process, and return code
    local -a final_packages=()      # Array of packages that are available and will be installed
    local -a missing_required=()    # Array of required packages that are missing (not available in the package manager)
    local -a missing_optional=()    # Array of optional packages that are missing (not available in the package manager)

    # Optional packages: script stays functional without them
    local -a OPTIONAL_PACKAGES=(thefuck neofetch fastfetch)

    # Check if a package is in the optional list
    _is_optional() {
        local p="$1"
        local x
        for x in "${OPTIONAL_PACKAGES[@]}"; do
            [[ "$x" == "$p" ]] && return 0
        done
        return 1
    }

    # Check if a package is available in the package manager
    _pkg_available() {
        local _pm="$1" _pkg="$2"
        case "$_pm" in
            apt)
                # Force English output to avoid locale parsing issues
                local cand
                cand="$(LC_ALL=C apt-cache policy "$_pkg" 2>/dev/null | awk -F': ' '/Candidate:/{print $2; exit}')"
                [[ -n "$cand" && "$cand" != "(none)" ]]
                ;;
            pacman)
                pacman -Si "$_pkg" &>/dev/null
                ;;
            brew)
                brew info "$_pkg" &>/dev/null
                ;;
            *)
                return 1
                ;;
        esac
    }

    #########################
    # UPDATE
    #########################
    log="$(mktemp_compat)"
    echo -ne "Updating packages..."

    # Run the update command in the background, redirecting output to a log file
    bash -c "$update_command" >"$log" 2>&1 &
    pid=$!
    spinner "$pid"
    wait "$pid"
    rc=$?

    # Check if the update command succeeded
    if (( rc != 0 )); then
        echo -e " [✗]"
        echo "Update failed (exit $rc). Output:" >&2
        sed 's/^/  /' "$log" >&2
        rm -f "$log"
        return "$rc"
    fi

    echo -ne " [✓]\n"
    rm -f "$log"

    #########################
    # AVAILABILITY CHECK
    #########################
    # Check availability of each package and categorize them into final, missing required, and missing optional lists
    local p
    for p in "${packages[@]}"; do
        if _pkg_available "$pm" "$p"; then
            final_packages+=( "$p" )
        else
            if _is_optional "$p"; then
                missing_optional+=( "$p" )
            else
                missing_required+=( "$p" )
            fi
        fi
    done

    # If there are missing required packages, report and exit with error
    if (( ${#missing_required[@]} )); then
        echo "Some REQUIRED packages are not available for '$pm': ${missing_required[*]}" >&2
        return 1
    fi

    # If there are missing optional packages, report but continue with installation of available packages
    if (( ${#missing_optional[@]} )); then
        echo "Warning: optional packages not available for '$pm': ${missing_optional[*]}" >&2
    fi

    # Nothing to install? (rare but safe)
    if (( ${#final_packages[@]} == 0 )); then
        echo "Installing packages... [✓]"
        return 0
    fi

    #########################
    # INSTALL
    #########################
    # Install the available packages, showing a spinner and logging output. If installation fails, show the log.
    log="$(mktemp_compat)"
    echo -ne "Installing packages..."

    # Run the install command in the background, redirecting output to a log file
    bash -c "$install_command \"\$@\"" _ "${final_packages[@]}" >"$log" 2>&1 &
    pid=$!
    spinner "$pid"
    wait "$pid"
    rc=$?

    # Check if the install command succeeded
    if (( rc != 0 )); then
        echo -e " [✗]"
        echo "Install failed (exit $rc). Output:" >&2
        sed 's/^/  /' "$log" >&2
        rm -f "$log"
        return "$rc"
    fi

    echo -ne " [✓]\n"
    rm -f "$log"

    # Debian/Ubuntu: "bat" binary can be "batcat"
    if [[ "$pm" == "apt" ]] && command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat 2>/dev/null || true
    fi

    return 0
}


#################################################################################
# detect_package_manager                                                        #
#################################################################################
# Description:  Detects the package manager and installs common packages.       #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
detect_package_manager() {
    # Local variables for package manager detection and installation
    local pm update_cmd install_cmd                                     # Detected package manager and corresponding commands
    local -a base_packages=(bat btop curl fzf git lsd neovim wget zsh)  # Base packages to install across all platforms
    local -a extra_packages=()                                           # Extra packages to install based on the package manager

    # Detect the package manager and set the appropriate update and install commands, as well as any extra packages needed for that platform
    # macOS: Homebrew is the default package manager, but neofetch is disabled -> use fastfetch instead; thefuck is available
    if [[ "$(uname -s)" == "Darwin" ]]; then
        if ! command -v brew &>/dev/null; then
            echo "Homebrew not found. Please install Homebrew first." >&2
            return 1
        fi
        pm="brew"
        update_cmd="brew update"
        install_cmd="brew install"

        # neofetch is disabled on Homebrew -> use fastfetch
        extra_packages+=(fastfetch thefuck)

    # Arch Linux: pacman is the default package manager
    elif command -v pacman &>/dev/null; then
        pm="pacman"
        update_cmd="sudo pacman -Syu --noconfirm"
        install_cmd="sudo pacman -S --noconfirm --needed"

        # Arch: fastfetch available in official repos
        extra_packages+=(fastfetch thefuck)

    # Debian/Ubuntu: apt is the default package manager
    elif command -v apt-get &>/dev/null; then
        pm="apt"
        update_cmd="sudo apt-get update"
        install_cmd="sudo DEBIAN_FRONTEND=noninteractive apt-get install -y"

        # Debian/Ubuntu: neofetch widely available; fastfetch may not be in stable repos
        extra_packages+=(neofetch)

        # Ubuntu 24.04+: thefuck (apt) is broken due to distutils removal -> skip it
        if ! is_ubuntu_2404_plus; then
            extra_packages+=(thefuck)
        fi

    # Unsupported platform
    else
        echo "Unsupported package manager. Supported: Homebrew (brew), APT (apt-get), Pacman" >&2
        return 1
    fi

    # Save context globally for later steps (plugins, etc.)
    PACKAGE_MANAGER="$pm"
    PM_UPDATE_CMD="$update_cmd"
    PM_INSTALL_CMD="$install_cmd"

    # Call the update and install function with the detected package manager and the list of packages to install
    update_and_install_packages "$pm" "$update_cmd" "$install_cmd" \
        "${base_packages[@]}" "${extra_packages[@]}"
}


#################################################################################
# install_oh_my_zsh                                                             #
#################################################################################
# Description:  Installs Oh My Zsh using the official installation script.      #
#               The installation is done in a non-interactive way,              #
#               and the output is logged. A spinner is shown                    #
#               while the installation is in progress. If the installation      #
#               fails, the log is displayed.                                    #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
install_oh_my_zsh() {
    local log pid rc
    log="$(mktemp 2>/dev/null || mktemp -t omzlog.XXXXXX)"

    echo -ne "Installing Oh My Zsh..."

    # Non-interactive install, keeps ZSH as default shell change prompt off.
    # RUNZSH=no prevents auto-switching into zsh at the end.
    # CHSH=no prevents changing the default shell (you can handle that later).
    env RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        </dev/null >"$log" 2>&1 &
    pid=$!

    # Show spinner while installation is in progress, and wait for the process to finish
    spinner "$pid" || { rm -f "$log"; echo -e " [✗]"; return 130; }
    wait "$pid"
    rc=$?

    # Check if the installation succeeded
    if (( rc != 0 )); then
        echo -e " [✗]"
        echo "Oh My Zsh install failed (exit $rc). Output:" >&2
        sed 's/^/  /' "$log" >&2
        rm -f "$log"
        return "$rc"
    fi

    # Installation succeeded
    echo -ne " [✓]\n"
    rm -f "$log"
    return 0
}


#################################################################################
# mktemp_compat                                                                 #
#################################################################################
# Description:  Provides a compatible mktemp function that works on both GNU    #
#               and BSD systems.                                                #
#               It tries to use the standard mktemp command, and if it fails    #
#               (e.g., on BSD systems), it falls back to a compatible syntax.   #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - A temporary file path created by mktemp.                      #  
#################################################################################
mktemp_compat() {
    mktemp 2>/dev/null || mktemp -t btzsh.XXXXXX
}


#################################################################################
# run_quiet                                                                     #
#################################################################################
# Description:  Runs a command quietly, showing a spinner and logging output.   #
#               If the command fails, it shows the log output.                  #
#                                                                               #
# Args:         1) $1: label to display while running the command               #
#               (e.g., "Installing...")                                         #
#               2..) $@: command and arguments to run (as an array)             #
# Returns:      - Exit code of the command.                                     #
#################################################################################
run_quiet() {
    # Local variables for running a command quietly with logging and spinner
    local label="$1"; shift     # Label to display while running the command (e.g., "Installing...")
    local log pid rc            # Log file for command output, PID of background process, and return code

    # Create a temporary log file for the command output
    log="$(mktemp_compat)"
    echo -ne "${label}..."

    # Run the command in the background, redirecting output to the log file
    ( "$@" ) >"$log" 2>&1 &
    pid=$!
    spinner "$pid"
    wait "$pid"
    rc=$?

    # Check if the command succeeded
    if (( rc != 0 )); then
        echo -e " [✗]"
        echo "${label} failed (exit $rc). Output:" >&2
        sed 's/^/  /' "$log" >&2
        rm -f "$log"
        return "$rc"
    fi

    # Command succeeded
    echo -ne " [✓]\n"
    rm -f "$log"
    return 0
}


#################################################################################
# ensure_omz_wrapper_plugin                                                     #
#################################################################################
# Description:  Ensures that an Oh My Zsh plugin wrapper script exists for      #
#               a given plugin. The wrapper script will attempt to source       #
#               the plugin from multiple possible locations                     #
#               (e.g., system-wide, Homebrew) to provide a consistent           #
#               experience regardless of how the plugin was installed.          #
#               This allows users to simply add the plugin name                 #
#               to their plugins list without worrying about the installation   # 
#               method. The wrapper is generated based on the provided plugin   #
#               name and potential source file paths.                           #
#                                                                               #
# Args:         1) $1: plugin name (e.g., "zsh-autosuggestions")                #
#               2..n) $@: potential file paths to source for the plugin         # 
#               (e.g., "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh")#
# Returns:      - None                                                          #
#################################################################################
ensure_omz_wrapper_plugin() {
    # Local variables for ensuring an Oh My Zsh wrapper plugin
    local plugin="$1"; shift                                # Plugin name (e.g., "zsh-autosuggestions")
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"   # Base directory for Oh My Zsh custom plugins
    local pdir="${custom}/plugins/${plugin}"                # Directory for the wrapper plugin
    local pfile="${pdir}/${plugin}.plugin.zsh"              # Path to the wrapper plugin file

    # Create the plugin directory if it doesn't exist
    mkdir -p "$pdir"

    # Generate the wrapper plugin script that tries to source the plugin from multiple potential locations
    {
        # The generated script will check each provided file path in order, and source the first one that exists and is readable.
        echo "# Autogenerated wrapper for ${plugin}"
        echo "for f in \\"
        local f
        for f in "$@"; do
            [[ -n "$f" ]] && printf "  %q \\\n" "$f"
        done
        echo "; do"
        echo "  if [[ -r \"\$f\" ]]; then"
        if [[ "$plugin" == "zsh-syntax-highlighting" ]]; then
            echo "    if [[ \"\$f\" == *\"/zsh-syntax-highlighting.zsh\" ]]; then"
            echo "      _dir=\"\${f%/zsh-syntax-highlighting.zsh}\""
            echo "      if [[ -d \"\$_dir/highlighters\" ]]; then"
            echo "        export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=\"\$_dir/highlighters\""
            echo "      fi"
            echo "    fi"
        fi
        echo "    source \"\$f\""
        echo "    return 0"
        echo "  fi"
        echo "done"
        echo "return 0"
    } > "$pfile"    # Write the generated wrapper script to the plugin file
}


#################################################################################
# git_install_or_update_plugin                                                  #
#################################################################################
# Description:  Installs or updates a Zsh plugin from a git repository. If the  #
#               plugin directory already exists and is a git repository,        #
#               it will attempt to pull the latest changes. If the directory    #
#               exists but is not a git repository, it will skip installation   #
#               and print a warning. If the directory does not exist, it will   #
#               clone the repository. This ensures that plugins installed via   #
#               git can be easily updated by re-running the script. The function#
#               takes care of both installation and updates in a consistent way.#
#                                                                               #
# Args:         1) $1: plugin name (e.g., "zsh-autosuggestions")                #
#               2) $2: git repository URL                                       #
#               (e.g., "https://github.com/zsh-users/zsh-autosuggestions.git")  #
# Returns:      - None                                                          #
#################################################################################
git_install_or_update_plugin() {
    # Local variables for git installation or update of a plugin
    local name="$1" # Plugin name (e.g., "zsh-autosuggestions")
    local url="$2"  # Git repository URL for the plugin (e.g., "https://github.com/zsh-users/zsh-autosuggestions.git")

    # Determine the target directory for the plugin within the Oh My Zsh custom plugins directory
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"   # Base directory for Oh My Zsh custom plugins
    local target="${custom}/plugins/${name}"                # Target directory for the plugin (e.g., "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions")

    # Check if the target directory exists and is a git repository. If it is, attempt to pull the latest changes. 
    # If it exists but is not a git repository, print a warning and skip. If it does not exist, clone the repository.
    if [[ -d "${target}/.git" ]]; then
        run_quiet "Updating ${name}" git -C "$target" pull --ff-only
    elif [[ -d "$target" ]]; then
        echo "Skipping ${name}: ${target} exists but is not a git repo." >&2
        return 0
    else
        run_quiet "Installing ${name}" git clone --depth=1 "$url" "$target"
    fi
}


#################################################################################
# install_zsh_plugins                                                           #
#################################################################################
# Description:  Installs Zsh plugins using the best method available for the    #
#               detected package manager. It first tries to install plugins via #
#               the package manager if they are available, then creates         #
#               Oh My Zsh wrapper plugins to source them from consistent        #
#               locations, and finally installs any remaining plugins directly  #
#               from their git repositories. This ensures that users get        #
#               the best experience with properly sourced plugins regardless of #
#               how they were installed. The function handles different         #
#               platforms and package managers gracefully, providing            #
#               a consistent setup for the user. It also logs the installation  #
#               process and shows a spinner for better UX. If any step fails,   #
#               it provides detailed output for troubleshooting.                #
#                                                                               #
# Args:         1) $1: package manager identifier                               #
#               (e.g., "apt", "pacman", "brew")                                 #
# Returns:      - None                                                          #
#################################################################################
install_zsh_plugins() {
    # Local variables for Zsh plugin installation
    local pm="$1"           # Package manager identifier (e.g., "apt", "pacman", "brew")
    local brew_prefix=""    # Prefix for Homebrew installations (used for plugin source paths on macOS)

    # Determine the Homebrew prefix if Homebrew is the detected package manager, as this will be needed for sourcing plugins installed via Homebrew on macOS.
    if [[ "$pm" == "brew" ]] && command -v brew &>/dev/null; then
        brew_prefix="$(brew --prefix 2>/dev/null || true)"
    fi

    # Log the start of the plugin installation process
    echo "Installing Zsh plugins (best method per platform)..."

    # 1) Packaged plugins when available
    case "$pm" in
        apt)
            update_and_install_packages "$pm" "$PM_UPDATE_CMD" "$PM_INSTALL_CMD" \
                zsh-autosuggestions zsh-syntax-highlighting
            ;;
        pacman)
            update_and_install_packages "$pm" "$PM_UPDATE_CMD" "$PM_INSTALL_CMD" \
                zsh-autosuggestions zsh-syntax-highlighting
            ;;
        brew)
            update_and_install_packages "$pm" "$PM_UPDATE_CMD" "$PM_INSTALL_CMD" \
                zsh-autosuggestions zsh-syntax-highlighting zsh-you-should-use
            ;;
        *)
            echo "install_zsh_plugins: unknown pm '$pm'" >&2
            return 1
            ;;
    esac

    # 2) OMZ wrappers for packaged plugins (so plugins=(...) works consistently)
    ensure_omz_wrapper_plugin "zsh-autosuggestions" \
        "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
        "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
        "${brew_prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

    ensure_omz_wrapper_plugin "zsh-syntax-highlighting" \
        "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
        "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
        "${brew_prefix}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    # you-should-use:
    # - brew: prefer formula, wrapper is needed
    # - apt/pacman: git clone (no reliable official package)
    if [[ "$pm" == "brew" ]]; then
        ensure_omz_wrapper_plugin "you-should-use" \
            "${brew_prefix}/share/zsh-you-should-use/you-should-use.plugin.zsh"
    else
        git_install_or_update_plugin "you-should-use" "https://github.com/MichaelAquilina/zsh-you-should-use.git"
    fi

    # 3) Always via git (best portable option)
    git_install_or_update_plugin "zsh-bat" "https://github.com/fdellwing/zsh-bat.git"
    git_install_or_update_plugin "zsh-z"   "https://github.com/agkozak/zsh-z.git"

    echo -ne "Plugins setup... [✓]\n"
    return 0
}


#################################################################################
# remove_zsh_config                                                             #
#################################################################################
# Description:  Removes existing Zsh configuration files (.zshrc and .p10k.zsh) #
#               if they exist. This is done to ensure a clean slate before      #
#               copying the new configuration files. It checks for              #
#               the existence of these files in the user's home directory       #
#               and deletes them if found. This function is called before       #
#               copying the new configuration files to prevent conflicts        #
#               and ensure that the new configurations are applied correctly.   #
#               It also handles the removal of the .p10k.zsh file, which        #
#               is used for Powerlevel10k theme configuration, if it exists.    #
#               This ensures that any old configurations that might interfere   #
#               with the new setup are removed, providing a smoother transition #
#               to the new Zsh environment. The function is designed to be safe #
#               and will not throw errors if the files do not exist.            #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
remove_zsh_config() {
    # Remove existing .zshrc and .p10k.zsh configuration files if they exist to ensure a clean setup
    [ -e ~/.zshrc ] && rm -f ~/.zshrc
    [ -e ~/.p10k.zsh ] && rm -f ~/.p10k.zsh 
}


#################################################################################
# moving_config_files                                                           #
#################################################################################
# Description:  Copies the new configuration files for Zsh and Powerlevel10k    #
#               to the user's home directory. It also ensures that the necessary#
#               Oh My Zsh plugins are copied to the custom plugins directory.   #
#               The function uses a spinner to indicate progress during         #
#               the copying process, providing a better user experience.        #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
moving_config_files() {
    run_quiet "Copying OMZ extract plugin" cp -r "${ZSH:-$HOME/.oh-my-zsh}/plugins/extract" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/extract"
    run_quiet "Copying OMZ command-not-found plugin" cp -r "${ZSH:-$HOME/.oh-my-zsh}/plugins/command-not-found" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/command-not-found"

    run_quiet "Copying .p10k.zsh" cp ./config/.p10k.zsh "$HOME/.p10k.zsh"
    run_quiet "Copying .zshrc" cp ./config/.zshrc "$HOME/.zshrc"

    # Powerlevel10k theme: update if already exists
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ -d "$p10k_dir/.git" ]]; then
        run_quiet "Updating Powerlevel10k" git -C "$p10k_dir" pull --ff-only
    elif [[ -d "$p10k_dir" ]]; then
        echo "Skipping Powerlevel10k: $p10k_dir exists but is not a git repo." >&2
    else
        run_quiet "Installing Powerlevel10k" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    fi
}


#################################################################################
# set_zsh_default                                                               #
#################################################################################
# Description:  Prompts the user to set Zsh as the default shell.               #
#               If the user agrees, it attempts to change the default shell     #
#               to Zsh for the current user (or the original user if running    #
#               with sudo). It checks for the presence of Zsh in the system,    #
#               ensures that it is listed in /etc/shells (which is required     #
#               for chsh on many systems), and then runs the chsh command       #
#               to change the default shell. The function provides feedback     #
#               on whether Zsh was set as the default shell or if the user      #
#               chose not to change it. It also handles potential errors during #
#               the process and informs the user accordingly.                   #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
set_zsh_default() {
    # Prompt the user to set Zsh as the default shell, and if they agree, 
    # change the default shell to Zsh for the current user (or original user if running with sudo)
    echo "Set Zsh as the default shell? [Y/n] (default: Y)"
    read -r reply
    reply="${reply:-Y}"
    [[ "$reply" =~ ^[Nn]$ ]] && { echo "Zsh is not set as the default shell."; return 0; }

    # Determine the target user for changing the shell. If running with sudo, use the original user; otherwise, use the current user.
    local target_user="${SUDO_USER:-$USER}"
    local zsh_path
    zsh_path="$(command -v zsh 2>/dev/null)"

    # Check if Zsh is available in the system. If not, print an error message and return with an error code.
    [[ -n "$zsh_path" ]] || { echo "zsh not found in PATH." >&2; return 1; }

    # Ensure in /etc/shells (needed for chsh on many systems)
    if [[ -r /etc/shells ]] && ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
        sudo sh -c "echo '$zsh_path' >> /etc/shells" >/dev/null 2>&1 || true
    fi

    # Change the default shell to Zsh for the target user, showing a spinner during the process. If it fails, print an error message.
    run_quiet "Changing default shell" sudo chsh -s "$zsh_path" "$target_user"

    # Provide feedback to the user that Zsh is now the default shell (effective on next login/new terminal)
    echo "Zsh is now the default shell (effective on next login/new terminal)."
}


#################################################################################
# patch_user_zshrc                                                              #
#################################################################################
# Description:  Patches the user's .zshrc file to ensure it has the correct     #
#               plugins and fetch block. It uses awk to process the .zshrc      #
#               file line by line, looking for specific patterns to replace.    #
#               It replaces any existing single fastfetch or neofetch line with #
#               a block that checks for both and runs                           #
#               the one that is available. It also forces a consistent plugins  #
#               line with the correct order of plugins. Additionally, it makes  #
#               the ls alias safe by checking for the presence of lsd           #
#               and aliasing ls to lsd if it is available, or to a safe default #
#               if not. If the user chose to use pywal, it also enables         #
#               the lines that source the pywal colors.                         #
#               The function is designed to be idempotent, meaning that running #
#               it multiple times will not cause duplicate entries              #
#               or unintended side effects. It ensures that the user's .zshrc   #
#               is properly configured to work with the installed plugins       #
#               and tools, providing a consistent experience regardless         #
#               of the user's previous configuration. The function also handles #
#               the case where the .zshrc file does not exist, in which case it #
#               simply does nothing, allowing the rest of the setup to proceed  #
#               without issues.                                                 #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
patch_user_zshrc() {
    local zshrc="$HOME/.zshrc"
    [[ -f "$zshrc" ]] || return 0

    # Plugins you want (with syntax-highlighting last)
    local plugins_line
    if is_ubuntu_2404_plus; then
        plugins_line="plugins=(git zsh-autosuggestions you-should-use zsh-bat zsh-z fzf extract command-not-found zsh-syntax-highlighting)"
    else
        plugins_line="plugins=(git zsh-autosuggestions you-should-use zsh-bat thefuck zsh-z fzf extract command-not-found zsh-syntax-highlighting)"
    fi

    local tmp
    tmp="$(mktemp_compat)"

    awk -v use_pywal="$USE_PYWAL" -v plugins_line="$plugins_line" '
      BEGIN {
        in_fetch = 0
        inserted = 0

        fetch_block =
          "# >>> BTZSH FETCH START\n" \
          "if command -v fastfetch >/dev/null 2>&1; then\n" \
          "  if [[ -r \"$HOME/images/arch-linux.png\" ]]; then\n" \
          "    fastfetch --logo-type chafa --logo \"$HOME/images/arch-linux.png\" --logo-width 32\n" \
          "  else\n" \
          "    fastfetch\n" \
          "  fi\n" \
          "elif command -v neofetch >/dev/null 2>&1; then\n" \
          "  neofetch\n" \
          "fi\n" \
          "# <<< BTZSH FETCH END"

        ls_line =
          "command -v lsd >/dev/null 2>&1 && alias ls='\''lsd -la'\'' || alias ls='\''ls -la'\''"
      }

      # 1) Remove any previously managed fetch block
      $0 ~ /^# >>> BTZSH FETCH START$/ { in_fetch=1; next }
      $0 ~ /^# <<< BTZSH FETCH END$/   { in_fetch=0; next }
      in_fetch==1 { next }

      # 2) Remove any existing fetch invocation lines (plain or with args)
      #    This prevents duplicates and keeps the block unique.
      $0 ~ /^[[:space:]]*(fastfetch|neofetch)([[:space:]].*)?$/ { next }

      # 3) Insert the managed fetch block right after the comment (if present)
      $0 ~ /^# Enable fastfetch/ && inserted==0 {
        print
        print fetch_block
        inserted=1
        next
      }

      # 4) Force consistent plugins line
      $0 ~ /^plugins=\(/ { print plugins_line; next }

      # 5) Make ls alias safe if lsd is missing
      $0 ~ /^alias ls=/ { print ls_line; next }

      # 6) Enable pywal lines only if user chose it
      use_pywal==1 && $0=="#(cat ~/.cache/wal/sequences &)" { print "(cat ~/.cache/wal/sequences &)"; next }
      use_pywal==1 && $0=="#cat ~/.cache/wal/sequences"     { print "cat ~/.cache/wal/sequences"; next }
      use_pywal==1 && $0=="#source ~/.cache/wal/colors-tty.sh" { print "source ~/.cache/wal/colors-tty.sh"; next }

      { print }

      END {
        # If we didn’t find the comment anchor, append the block once at end
        if (inserted==0) {
          print ""
          print fetch_block
        }
      }
    ' "$zshrc" > "$tmp" && mv "$tmp" "$zshrc"
}


#################################################################################
# is_ubuntu_2404_plus                                                           #
#################################################################################
# Description:  Checks if the current system is running Ubuntu 24.04 or later.  #
#               It reads the /etc/os-release file to determine the distribution #
#               ID and version. It checks if the ID is "ubuntu" and if the      #
#               VERSION_ID is 24.04 or higher. This is used to determine if     #
#               certain plugins (like thefuck) should be installed via          #
#               the package manager or not, as Ubuntu 24.04 has issues with     #
#               thefuck due to the removal of distutils. The function returns   #
#               0 (success) if the system is Ubuntu 24.04 or later,             #
#               and 1 (failure) otherwise. It also handles cases where          #
#               the /etc/os-release file is not readable or does not contain    #
#               the expected information, returning 1 in those cases as well.   #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - 0 if the system is Ubuntu 24.04 or later, 1 otherwise.        #
#################################################################################
is_ubuntu_2404_plus() {
    # Check if the system is running Ubuntu 24.04 or later by reading /etc/os-release
    [[ -r /etc/os-release ]] || return 1
    . /etc/os-release

    # Check if the ID is "ubuntu" and if the VERSION_ID is 24.04 or higher. The VERSION_ID is transformed by removing dots to allow for numeric comparison (e.g., "24.04" becomes "2404").
    [[ "$ID" == "ubuntu" ]] || return 1
    # VERSION_ID like "24.04" -> "2404"
    local v="${VERSION_ID//./}"
    [[ "$v" =~ ^[0-9]+$ ]] || return 1
    (( v >= 2404 ))
}


#################################################################################
# clean_up                                                                      #
#################################################################################
# Description:  Cleans up the installation files by removing the temporary      #
#                directory used for the installation process. It navigates      #
#                to the parent directory and then removes the                   #
#                "Bash-To-ZSH-Initialization" directory along with all its      #
#                contents. The function also shows a spinner during the cleanup #
#                process for better user experience, and provides feedback once #
#                the cleanup is complete. This ensures that any temporary files #
#                or directories created during the installation are removed,    #
#                leaving the user's system clean after the setup is finished.   #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
clean_up() {
    local script_dir
    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    echo -ne "Cleaning up..."
    run_quiet "Cleaning up" rm -rf "$script_dir"
}


#################################################################################
# main                                                                          #
#################################################################################
# Description:  Main function that orchestrates the entire installation process.#
#               It calls the various functions defined above in                 #
#               a logical order to perform the installation and setup of Zsh,   #
#               Oh My Zsh, plugins, and configuration.                          #
#               The main function ensures that each step is executed in         #
#               the correct sequence, starting with verifying                   #
#               root permissions, asking the user about pywal,                  #
#               detecting the package manager, installing Oh My Zsh,            #
#               installing plugins, moving configuration files,                 #
#               patching the user's .zshrc file, setting Zsh as the default     #
#               shell, and finally cleaning up installation files.              #
#                                                                               #
# Args:         - None                                                          #
# Returns:      - None                                                          #
#################################################################################
main() {
    verify_root_permissions
    ask_for_pywal
    detect_package_manager
    install_oh_my_zsh
    install_zsh_plugins "$PACKAGE_MANAGER"
    moving_config_files
    patch_user_zshrc
    set_zsh_default
    clean_up
}

# Run the main function with all script arguments
main "$@"
