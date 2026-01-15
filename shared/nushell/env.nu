# Nushell Environment Config File
#
# version = 0.83.1

def create_left_prompt [] {
    mut home = ""
    try {
        if $nu.os-info.name == "windows" {
            $home = $env.USERPROFILE
        } else {
            $home = $env.HOME
        }
    }

    let dir = ([
        ($env.PWD | str substring 0..($home | str length) | str replace --string $home "~"),
        ($env.PWD | str substring ($home | str length)..)
    ] | str join)

    let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
    let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
    let path_segment = $"($path_color)($dir)"

    $path_segment | str replace --all --string (char path_sep) $"($separator_color)/($path_color)"
}

def create_right_prompt [] {
    # create a right prompt in magenta with green separators and am/pm underlined
    let time_segment = ([
        (ansi reset)
        (ansi magenta)
        (date now | date format '%Y/%m/%d %r')
    ] | str join | str replace --all "([/:])" $"(ansi green)${1}(ansi magenta)" |
        str replace --all "([AP]M)" $"(ansi magenta_underline)${1}")

    let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
        (ansi rb)
        ($env.LAST_EXIT_CODE)
    ] | str join)
    } else { "" }

    ([$last_exit_code, (char space), $time_segment] | str join)
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
# $env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| " > " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| " : " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| " > " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = [
    # ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
]

# Directories to search for plugin binaries when calling register
$env.NU_PLUGIN_DIRS = [
    # ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

# Environment variables from zsh config
$env.EDITOR = "nvim"
$env.PAGER = "nvim-pager"
$env.BROWSER = "google-chrome-stable"

$env.CURL_CA_BUNDLE = "~/.local/ca-certificates/combined-ca-bundle.pem"

$env.XDG_CACHE_HOME = "~/.cache"
$env.XDG_CONFIG_HOME = "~/.config"
$env.XDG_DATA_HOME = "~/.local"
$env.XDG_RUNTIME_DIR = $env.TMPDIR?
$env.XDG_STATE_HOME = "~/.local/state"

$env.DENO_NO_UPDATE_CHECK = "1"

$env.DELTA_PAGER = "less -R"
$env.LESS = "--RAW-CONTROL-CHARS --LONG-PROMPT --ignore-case --no-init --quit-if-one-screen"

$env.GPG_TTY = (tty)

$env.EZA_COLORS = "di=34:ln=35:fi=0:ex=32:pi=0:so=0:bd=0:cd=0:or=0:su=0:sg=0:tw=0:ow=0:ur=0:uw=0:ux=0:ue=0:gr=0:gw=0:gx=0:tr=0:tw=0:tx=0:sn=0:sb=0:uu=0:gu=0:da=0:*=0"
$env.LS_COLORS = "di=34:ln=35:so=1;35:pi=1;33:ex=32:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;34:ow=1;33:"

$env.MANPAGER = "nvim +Man!"
$env.MANWIDTH = "100"

$env.READNULLCMD = $env.PAGER

$env.PATH = ($env.PATH | split row (char esep) | prepend [
    "~/bin"
    "~/.local/bin"
    "~/.cache/.bun/bin"
    "~/.cargo/bin"
    "~/.npm/bin"
    "~/go/bin"
] | path expand | where {|p| $p | path exists})

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')
