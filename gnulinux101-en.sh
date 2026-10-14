#!/usr/bin/env bash
# Linux101: a Bash-based training terminal isolated from the real system.
set -u
export LC_ALL=C.UTF-8
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
STATE_DIR="$SCRIPT_DIR/.linux101-en"
LEVEL=1
DONE=0
INPUT=/dev/null
TOKENS=()
PASSWORDS=()
OP=$'\x1f'
QSTAR=$'\x1e'

say() { printf '%s\n' "$*"; }
fail() { say "Error: $*" >&2; return 1; }

# Single-file distribution: the guide is embedded.
help_text() {
    cat <<'LINUX101_HELP'
# GNU/Linux 101 — Command guide

In this controlled training terminal, /home/user and ~ refer to your
in-game home directory. Your real user files are not used.
help: guide | task: current task | exit: quit
password word: advance to the next level using the password you found
hardreset: reset the game world and return to level 1 (passwords are kept)
flashback x: restart a previously completed level x
rewind: restart the current level (passwords are kept)

## pwd
Shows the full path of your current directory. It normally works even
when the prompt hides your location; the game disables it in level 10.

## ls
Lists directory contents: ls or ls /home/user.
ls -a also shows hidden entries whose names start with a dot.
ls -l: type/permissions, link count, owner, group, size, date, and name.
ls -l file.md: details of the specified file only.
The type and permissions field has 10 characters; a following . or +
is not part of this field.

## cd
Changes directory: cd subdirectory, cd .., cd ~. With no argument, cd
goes to your home directory. . is the current directory; .. is its parent.
Paths starting with / are absolute; other paths are relative to your
current directory. Quote names containing spaces:
cd "lesson notes". Names are case-sensitive.

## cat
Displays text files: cat notes.md or cat one.md two.md.
A missing or unreadable file produces an error and a failure exit status.

## mkdir
mkdir new: creates a directory. mkdir -p new/sub/deep also creates
missing parent directories. Creating a directory does not enter it.

## touch
touch notes.md: creates an empty file if it does not exist. It does not
erase an existing file's contents; it updates its timestamps.

## cp
cp source.md target.md: copies a file. cp source.md .. copies it to the
parent directory with the same name. The source stays in place.
The game uses basic file copying.

## mv
mv old.md new.md: renames a file. mv document.md subdirectory/: moves it.
A moved file no longer exists at its old location.

## rm
rm unwanted.md: deletes a file. It normally does not go to a recycle bin.
The game only uses file deletion; do not try to delete . or .. directories.

## less
less notes.md: displays long text with scrolling. Navigate with the
up/down arrow keys; press q to quit. It does not edit files.
It runs in secure mode in the game.

## find
Searches a directory tree, including subdirectories:
find . -name "notes.md"
find . -name "*deniz*"
find . -type f
-name matches names; -type f selects regular files. The starting point
can be . or an absolute directory path. Quote the pattern so that find,
rather than the shell, interprets the * character.

## grep
grep "word" notes.md: shows matching lines; matching is case-sensitive.
It also filters text received through a pipe. Filtering filenames and
searching file contents are different operations.

## echo
echo "Hello": prints text. Quotes are optional for a single word.
echo Hello and echo "Hello" are equivalent. Advanced shell features
such as variable expansion are not used in the game.

## nano
nano notes.md: a text editor. Press Ctrl+O to save, Enter to confirm the
filename, and Ctrl+X to exit. The game uses restricted mode; you must
create the file first. Opening other programs or files is restricted.

## man
man sudo: displays a manual page; press q to quit. The game uses fixed
training texts. man -k "file" searches for a keyword in manual titles
and descriptions; this is not the same as searching a full manual page.

## Operators
| : Passes standard output on the left to the command on the right:
ls | grep "notes".
> : Writes to a file; OVERWRITES existing contents:
echo "Hello" > greeting.md
>> : APPENDS to a file, keeping its previous contents:
echo "New line" >> greeting.md
&& : Runs the second command if the first succeeds: cd notes && ls.
|| : Runs the second command if the first fails:
cat missing.md || echo "Could not read"
* : Matches zero or more characters: ls note*.
A quoted or escaped asterisk is a literal character:
ls "note*" does not search for a pattern; find . -name "note*" passes
the pattern to find. A normal * pattern does not include hidden files;
use ls -a to see them. Write operators outside quotes;
echo "a | b" only prints text. A pipe does not carry standard error
messages; you may also see the first command's error before the || message.

## sudo
On a real system, runs a command as another user (usually the administrator);
authorization may be required. In the game, it is accepted only for the
apt simulation and does not ask for an administrator password.

## apt
Package management on Debian and its derivatives:
sudo apt install package1 package2 : installs packages
sudo apt remove package1 : removes a package
sudo apt list : lists packages
sudo apt update : retrieves current package information from repositories
sudo apt upgrade : installs available updates for installed packages
update alone does not update programs. All of this is simulated in the
game; no packages are installed, removed, or updated on the real system.

## chmod
Changes permissions: chmod +x script, chmod -x script.
ls -l example: -rwxr--rw-. The first character is the type:
- for a file, d for a directory. The following groups of three are for
the owner, group, and others, respectively.
r: read | w: write | x: execute | -: no permission.
For directories, r lists names, w changes entries, and x allows entering;
an operation may require more than one permission.
Numeric values are r=4, w=2, x=1; add them within each group of three:
rwx=7, r-x=5, r--=4, -wx=3, --x=1, rw-=6.
chmod 531 file is an example: owner r-x, group -wx, others --x.
Any three-digit permission value can be used as needed for the task.
The file type character is not included in the numeric permission value.

## chown
chown eyub one.md two.md three.md: changes ownership.
On a real system, transferring ownership to another user normally requires
administrator privileges. It is simulated in the game: the real file
owner does not change, and no privileges or password are requested.

## Game rules
Passwords are normally five-letter English words. Levels using the
type/permissions field or a word from the manual are exceptions.
In levels 14–15, alternative attempts to modify files restart that level;
reading, listing, and viewing help are not penalized.
In level 18, an incorrect method of changing directory is rejected.
Differences in quotes or spacing do not matter; the required operations
and operators do. When you reopen the game, your current level is rebuilt
from scratch. hardreset returns progress to level 1 and rebuilds the game
world. Completed levels are recorded and can be replayed with flashback.
flashback and rewind discard unfinished file operations in the current
level. hardreset also clears the record of completed levels.
LINUX101_HELP
}

# User input is never executed through eval, source, or bash -c.
tokenize() {
    TOKENS=()
    local text=$1 word='' quote='' active=0 c next i
    [[ $text != *"$OP"* && $text != *"$QSTAR"* ]] || { fail 'Unsupported control character.'; return 1; }
    for ((i=0; i<${#text}; i++)); do
        c=${text:i:1}
        if [[ $quote == "'" ]]; then
            if [[ $c == "'" ]]; then quote=''
            elif [[ $c == '*' ]]; then word+=$QSTAR
            else word+=$c; fi
        elif [[ $quote == '"' ]]; then
            if [[ $c == '"' ]]; then
                quote=''
            elif [[ $c == '\' && ( ${text:i+1:1} == '"' || ${text:i+1:1} == '\' ) ]]; then
                ((i+=1)); word+=${text:i:1}
            elif [[ $c == '*' ]]; then word+=$QSTAR
            else word+=$c
            fi
        else
            case "$c" in
                "'"|'"') quote=$c; active=1 ;;
                '\')
                    ((i+=1))
                    ((i<${#text})) || { fail 'Incomplete escape sequence.'; return 1; }
                    if [[ ${text:i:1} == '*' ]]; then word+=$QSTAR
                    else word+=${text:i:1}; fi
                    active=1 ;;
                ' '|$'\t')
                    if ((active)); then TOKENS+=("$word"); word=''; active=0; fi ;;
                '|'|'&'|'>')
                    if ((active)); then TOKENS+=("$word"); word=''; active=0; fi
                    next=${text:i+1:1}
                    if [[ $next == "$c" ]]; then TOKENS+=("$OP$c$c"); ((i+=1))
                    elif [[ $c == '&' ]]; then fail 'A single & is not supported.'; return 1
                    else TOKENS+=("$OP$c")
                    fi ;;
                ';'|'<'|'`') fail 'This symbol is not part of the training commands.'; return 1 ;;
                *) word+=$c; active=1 ;;
            esac
        fi
    done
    [[ -z $quote ]] || { fail 'Unclosed quote.'; return 1; }
    if ((active)); then TOKENS+=("$word"); fi
}

# Validate the entire line before execution; a command preceding a missing
# right-hand side must not modify files or directories.
validate_tokens() {
    local need_command=1 redirected=0 token i
    for ((i=0; i<${#TOKENS[@]}; i++)); do
        token=${TOKENS[i]}
        case "$token" in
            "$OP|"|"$OP&&"|"$OP||")
                ((need_command == 0)) || { fail 'Missing command.'; return 1; }
                [[ $token != "$OP|" || $redirected == 0 ]] || { fail 'Redirection must come after the pipe.'; return 1; }
                need_command=1; redirected=0 ;;
            "$OP>"|"$OP>>")
                ((need_command == 0 && redirected == 0)) || { fail 'Invalid redirection.'; return 1; }
                ((i+1<${#TOKENS[@]})) || { fail 'Missing redirection target.'; return 1; }
                [[ -n ${TOKENS[i+1]} && ${TOKENS[i+1]} != "$OP"* ]] || { fail 'Missing redirection target.'; return 1; }
                ((i+=1)); redirected=1 ;;
            *)
                ((redirected == 0)) || { fail 'Redirection must be at the end of the command.'; return 1; }
                need_command=0 ;;
        esac
    done
    ((need_command == 0)) || { fail 'Missing command.'; return 1; }
}

virtual_path() {
    local p=$1
    if [[ $p == "$ROOT" ]]; then printf '/'
    else printf '%s' "${p#"$ROOT"}"
    fi
}

strip_paths() {
    local line
    while IFS= read -r line || [[ -n $line ]]; do
        printf '%s\n' "${line//"$ROOT"/}"
    done
}

# Map absolute training paths to the physical game world; reject all paths
# escaping the world, including those using .. or symbolic links.
resolve() {
    local p=${1-} resolved
    [[ -n $p ]] || { fail 'A file or directory name cannot be empty.'; return 1; }
    p=${p//$QSTAR/*}
    case "$p" in
        '~') p="$HOME_GAME" ;;
        '~/'*) p="$HOME_GAME/${p:2}" ;;
        /*) p="$ROOT$p" ;;
        *) p="$CWD/$p" ;;
    esac
    resolved=$(realpath -m -- "$p") || return 1
    [[ $resolved == "$ROOT" || $resolved == "$ROOT/"* ]] || {
        fail 'You cannot leave the game world.'; return 1;
    }
    printf '%s' "$resolved"
}

# Expand * only in path arguments for file operations.
# Pass find and grep patterns unchanged to their respective commands.
expand_paths() {
    PATH_ARGS=()
    local arg p match
    local -a matches
    for arg in "$@"; do
        p=$(resolve "$arg") || return 1
        if [[ $arg == *'*'* ]]; then
            # In partially quoted patterns, only unquoted asterisks expand;
            # [*] represents a literal asterisk for compgen.
            p=$(resolve "${arg//$QSTAR/[*]}") || return 1
            mapfile -t matches < <(compgen -G "$p")
            ((${#matches[@]})) || { fail "No match: $arg"; return 1; }
            for match in "${matches[@]}"; do
                p=$(realpath -m -- "$match")
                [[ $p == "$ROOT/"* ]] || return 1
                PATH_ARGS+=("$p")
            done
        else PATH_ARGS+=("$p")
        fi
    done
}

auth_manual() {
    cat <<'EOF'
SUDO(8)                     Training manual page                     SUDO(8)

NAME
    sudo - run a command as another user

SYNOPSIS
    sudo command

DESCRIPTION
    On a real system, sudo checks the authorization policy.
    authentication checks normally precede privileged commands.
    This game does not require administrator privileges or change system packages.

NOTES
    This fixed training text provides the same result across distributions.
    Final authentication verification is described here.
EOF
}

manual() {
    local name=$1
    if [[ $name == sudo ]]; then auth_manual
    elif [[ $name == -k ]]; then
        cat <<'MAN_INDEX'
pwd (1) - show the working directory path
ls (1) - list files and directories
cd (1) - change the working directory
cat (1) - display file contents
mkdir (1) - create a directory
touch (1) - create an empty file or update its timestamps
cp (1) - copy files
mv (1) - move or rename files
rm (1) - delete files
less (1) - display text with scrolling
find (1) - search for files and directories
grep (1) - display matching lines
echo (1) - print text
nano (1) - edit text files
man (1) - display command help
sudo (8) - run a command as another user
apt (8) - manage packages
chmod (1) - change file permissions
chown (1) - change file ownership
MAN_INDEX
    else
        help_text | awk -v heading="## $name" '
            /^## / { printing=($0 == heading); if (printing) found=1 }
            printing { print }
            END { if (!found) exit 1 }
        ' || { fail "Manual page not found: $name"; return 1; }
    fi
}

dispatch() {
    local cmd=${1:-} p destination option='' pattern status mode index
    shift || return 1
    local -a options=()
    case "$cmd" in
        pwd)
            (($# == 0)) || return 1
            if ((LEVEL == 10)); then say 'It is not that easy this time :)'
            else virtual_path "$CWD"; printf '\n'; fi ;;
        cd)
            (($# <= 1)) || return 1
            if (($# == 0)); then p=$HOME_GAME
            else p=$(resolve "$1") || return 1
            fi
            [[ -d $p ]] || { fail 'Directory not found.'; return 1; }
            [[ -x $p ]] || { fail 'You do not have permission to enter this directory.'; return 1; }
            CWD=$p
            if ((LEVEL == 8)) && [[ $CWD == "$TARGET" ]]; then
                touch -- "$TARGET/${PASSWORDS[LEVEL-1]}" || return 1
                REVEALED=1
            fi ;;
        ls)
            if [[ ${1:-} == -l || ${1:-} == -a ]]; then options+=("$1"); shift; fi
            for p in "$@"; do [[ $p != -* ]] || { fail 'Only ls, ls -l, and ls -a are supported.'; return 1; }; done
            if (($#)); then expand_paths "$@" || return 1
            else expand_paths . || return 1; fi
            # Do not expose absolute physical game paths in the terminal.
            command ls --color=never "${options[@]}" -- "${PATH_ARGS[@]}" 2> "$STATE_DIR/error" |
                strip_paths
            status=${PIPESTATUS[0]}
            if ((status)); then strip_paths < "$STATE_DIR/error" >&2; fi
            return "$status" ;;
        cat|less|nano)
            (($# > 0)) || { fail 'Specify a filename.'; return 1; }
            expand_paths "$@" || return 1
            for p in "${PATH_ARGS[@]}"; do
                [[ ! -d $p ]] || { fail 'Choose a text file.'; return 1; }
            done
            if [[ $cmd == cat ]]; then
                command cat -- "${PATH_ARGS[@]}" 2> "$STATE_DIR/error"
                status=$?
                if ((status)); then say 'cat: Could not read the file.' >&2; fi
                return "$status"
            elif [[ $cmd == less ]]; then
                (($# == 1)) && [[ -f ${PATH_ARGS[0]} ]] || return 1
                if [[ -t 0 && -t 1 ]]; then
                    LESSSECURE=1 LESSHISTFILE=- LESSOPEN='' command less -- "${PATH_ARGS[0]}"
                    status=$?
                else
                    command cat -- "${PATH_ARGS[0]}"; status=$?
                fi
                if ((status == 0 && LEVEL == 10)) && [[ ${PATH_ARGS[0]} == "$TASK_DIR/readme.txt" ]]; then
                    write_noise "$TASK_DIR/less.txt" 90
                    printf 'Kitchen note: broth; the password you are looking for: %s\n' "${PASSWORDS[LEVEL-1]}" >> "$TASK_DIR/less.txt"
                    write_noise "$TASK_DIR/less.txt" 60 append
                    REVEALED=1
                    say 'You closed the file. less.txt has been created.'
                fi
                return "$status"
            else
                (($# == 1)) || return 1
                [[ -t 0 ]] || { fail 'nano requires an interactive terminal.'; return 1; }
                # Restricted nano: opening other files, shell access, and external writes are disabled.
                command nano --restricted -- "${PATH_ARGS[0]}"
            fi ;;
        mkdir|touch|cp|mv|rm)
            if [[ $cmd == mkdir && ${1:-} == -p ]]; then options=(-p); shift; fi
            (($#)) || return 1
            for p in "$@"; do [[ $p != -* ]] || { fail 'This option is not in the training list.'; return 1; }; done
            expand_paths "$@" || return 1
            for ((index=0; index<${#PATH_ARGS[@]}; index++)); do
                p=${PATH_ARGS[index]}
                if [[ ( $p == "$ROOT" || $p == "$HOME_GAME" || $HOME_GAME == "$p/"* ) &&
                      ( $cmd == rm || ( $cmd == mv && $index -lt $((${#PATH_ARGS[@]}-1)) ) ) ]]; then
                    fail 'The game root cannot be deleted or moved.'; return 1
                fi
                if [[ $cmd == mv && $index -lt $((${#PATH_ARGS[@]}-1)) &&
                      ( $CWD == "$p" || $CWD == "$p/"* ) ]]; then
                    fail 'Leave the directory you want to move first.'; return 1
                fi
            done
            if [[ ( $cmd == cp || $cmd == mv ) && ${#PATH_ARGS[@]} -ge 2 ]]; then
                destination=${PATH_ARGS[${#PATH_ARGS[@]}-1]}
                if [[ -d $destination ]]; then
                    for ((index=0; index<${#PATH_ARGS[@]}-1; index++)); do
                        p=$(realpath -m -- "$destination/$(basename -- "${PATH_ARGS[index]}")") || return 1
                        [[ $p == "$ROOT/"* ]] || { fail 'The destination file is outside the game world.'; return 1; }
                    done
                fi
            fi
            command "$cmd" "${options[@]}" -- "${PATH_ARGS[@]}" 2> "$STATE_DIR/error"
            status=$?
            if [[ $status == 0 && $cmd == rm && $LEVEL == 7 && ! -e $TARGET ]]; then
                for p in "${PATH_ARGS[@]}"; do
                    if [[ $p == "$TARGET" ]]; then TARGET_DELETED=1; fi
                done
            fi
            ((status == 0)) || fail "$cmd could not be completed; check the paths and permissions."
            return "$status" ;;
        find)
            (($# == 3)) || { fail 'Usage: find . -name "pattern" or find . -type f'; return 1; }
            p=$(resolve "$1") || return 1
            [[ -d $p ]] || return 1
            option=$2; pattern=${3//$QSTAR/*}
            [[ $option == -name || ( $option == -type && $pattern == f ) ]] || return 1
            if [[ $1 == . ]]; then
                (cd -- "$CWD" && command find . "$option" "$pattern")
            else
                command find "$p" "$option" "$pattern" | strip_paths
                return "${PIPESTATUS[0]}"
            fi ;;
        grep)
            (($# >= 1)) || return 1
            pattern=${1//$QSTAR/*}; shift
            if (($#)); then
                expand_paths "$@" || return 1
                command grep -- "$pattern" "${PATH_ARGS[@]}" 2> "$STATE_DIR/error" | strip_paths
                status=${PIPESTATUS[0]}
                if ((status > 1)); then strip_paths < "$STATE_DIR/error" >&2; fi
                return "$status"
            else command grep -- "$pattern" < "$INPUT"
            fi ;;
        echo) p=$*; printf '%s\n' "${p//$QSTAR/*}" ;;
        man)
            if [[ ${1:-} == -k && $# == 2 ]]; then manual -k | command grep -i -- "$2"
            elif (($# == 1)); then
                if [[ -t 1 && -t 0 ]]; then manual "$1" | LESSSECURE=1 LESSHISTFILE=- command less
                else manual "$1"; fi
            else return 1; fi ;;
        chmod)
            (($# >= 2)) || return 1
            mode=$1; shift
            [[ $mode == +x || $mode == -x || $mode =~ ^[0-7]{3}$ ]] || { fail 'Use a three-digit permission value, +x, or -x.'; return 1; }
            expand_paths "$@" || return 1
            command chmod -- "$mode" "${PATH_ARGS[@]}" ;;
        chown)
            (($# >= 2)) && [[ $1 == eyub ]] || { fail 'The ownership target in this game is eyub.'; return 1; }
            shift
            expand_paths "$@" || return 1
            for p in "${PATH_ARGS[@]}"; do [[ -f $p ]] || return 1; done
            for p in "${PATH_ARGS[@]}"; do printf '%s\n' "$p" >> "$STATE_DIR/owners"; done
            say 'Ownership has been transferred to user eyub within the game.' ;;
        sudo)
            [[ ${1:-} == apt ]] || { fail 'Only the training apt operations are simulated.'; return 1; }
            shift
            case "${1:-}" in
                install|remove) (($# >= 2)) || return 1 ;;
                list|update|upgrade) (($# == 1)) || return 1 ;;
                *) return 1 ;;
            esac
            say "[Simulation] apt $* succeeded. The real system was not changed." ;;
        *) fail "This command is not supported in the game: $cmd. Type help for the guide."; return 1 ;;
    esac
}

dispatch_stage() {
    # As in Bash, cd and similar commands in a pipe do not change the main working directory.
    if ((PIPE_SUBSHELL)); then (dispatch "$@")
    else dispatch "$@"; fi
}

# Syntax: pipeline -> redirection; && and || short-circuit from left to right.
run_pipeline() {
    local -a words=("$@") part=()
    local out='' operator='' token i=0 stage=0 result=0 previous=/dev/null
    local capture="$STATE_DIR/pipe.$BASHPID"
    local PIPE_SUBSHELL=0
    for token in "${words[@]}"; do [[ $token != "$OP|" ]] || PIPE_SUBSHELL=1; done
    for ((i=0; i<${#words[@]}; i++)); do
        token=${words[i]}
        if [[ $token == "$OP>" || $token == "$OP>>" ]]; then
            [[ -z $out && $((i+2)) -eq ${#words[@]} ]] || { fail 'Redirection must be at the end of the line.'; return 1; }
            operator=${token#"$OP"}
            out=$(resolve "${words[i+1]}") || return 1
            [[ $out != "$ROOT" && $out != "$HOME_GAME" ]] || return 1
            break
        fi
    done
    if [[ -n $out ]]; then words=("${words[@]:0:i}"); fi
    for ((i=0; i<=${#words[@]}; i++)); do
        if ((i == ${#words[@]})); then token="$OP|"; else token=${words[i]}; fi
        if [[ $token == "$OP|" ]]; then
            ((${#part[@]})) || { fail 'Missing pipeline command.'; return 1; }
            INPUT=$previous
            if ((i < ${#words[@]})); then
                dispatch_stage "${part[@]}" > "$capture.$stage"
                result=$?; previous="$capture.$stage"; ((stage+=1))
            elif [[ $operator == '>' ]]; then
                dispatch_stage "${part[@]}" > "$out"; result=$?
            elif [[ $operator == '>>' ]]; then
                dispatch_stage "${part[@]}" >> "$out"; result=$?
            else
                # Record only the last stage's output sent to the terminal.
                # Preserve the real TTY connection for interactive programs.
                if ((LEVEL == 16)) && [[ ${part[0]} != nano && ${part[0]} != less && ${part[0]} != man ]]; then
                    dispatch_stage "${part[@]}" > "$STATE_DIR/stdout-stage"
                    result=$?
                    cat "$STATE_DIR/stdout-stage" >> "$STATE_DIR/terminal-output"
                    cat "$STATE_DIR/stdout-stage"
                else dispatch_stage "${part[@]}"; result=$?
                fi
            fi
            part=()
        else part+=("$token")
        fi
    done
    INPUT=/dev/null
    for ((i=0; i<stage; i++)); do command rm -f -- "$capture.$i"; done
    return "$result"
}

run_tokens() {
    local -a part=()
    local token condition='' result=0 i
    for ((i=0; i<=${#TOKENS[@]}; i++)); do
        if ((i == ${#TOKENS[@]})); then token="$OP&&"; else token=${TOKENS[i]}; fi
        if [[ $token == "$OP&&" || $token == "$OP||" ]]; then
            ((${#part[@]})) || { fail 'Missing conditional command.'; return 1; }
            if [[ -z $condition || ( $condition == '&&' && $result == 0 ) || ( $condition == '||' && $result != 0 ) ]]; then
                run_pipeline "${part[@]}"; result=$?
            fi
            condition=${token#"$OP"}; part=()
        else part+=("$token")
        fi
    done
    return "$result"
}

matches() {
    local -a expected=("$@")
    local i
    ((${#TOKENS[@]} == ${#expected[@]})) || return 1
    for ((i=0; i<${#expected[@]}; i++)); do
        case "${expected[i]}" in
            '|'|'&&'|'||'|'>'|'>>') expected[i]="$OP${expected[i]}" ;;
        esac
        [[ ${TOKENS[i]//$QSTAR/*} == "${expected[i]}" ]] || return 1
    done
}

random_name() {
    local n
    n=$(od -An -N8 -tx1 /dev/urandom | tr '0123456789' 'ghijklmnop')
    n=${n//[[:space:]]/}
    printf 'd%s' "${n:0:8}"
}
make_random_dir() {
    local p="$1/$(random_name)"
    while [[ -e $p ]]; do p="$1/$(random_name)"; done
    mkdir -- "$p" || return 1
    printf '%s' "$p"
}
write_noise() {
    local file=$1 count=$2 i
    [[ ${3:-} == append ]] || : > "$file"
    for ((i=1; i<=count; i++)); do printf 'Note %03d: This line is a daily work log entry.\n' "$i" >> "$file"; done
}

decoy_files() {
    local directory=$1 count=$2 extension=${3:-md} i
    for ((i=1; i<=count; i++)); do
        printf 'This file is a practice record; it is not the target file.\n' > "$directory/record_${i}.$extension"
    done
}

setup_level() {
    # Rebuild only the world created and marked by the application.
    [[ -f "$STATE_DIR/.linux101-state" ]] || { fail 'The game world marker is missing.'; return 1; }
    ROOT="$STATE_DIR/world"
    # The player may have removed directory access with chmod. find makes
    # each directory accessible before descending, without following symlinks.
    if [[ -d $ROOT && ! -L $ROOT ]]; then
        chmod u+rwx -- "$ROOT" || { DONE=1; fail 'Could not restore game world access.'; return 1; }
        find "$ROOT" -type d -exec chmod u+rwx -- '{}' ';' || { DONE=1; fail 'Could not restore directory permissions.'; return 1; }
    fi
    command rm -rf -- "$ROOT" || { DONE=1; fail 'Could not clean up the old game world.'; return 1; }
    command mkdir -p -- "$ROOT/home/user" || { DONE=1; fail 'Could not create the game world.'; return 1; }
    HOME_GAME="$ROOT/home/user"
    CWD="$HOME_GAME"
    TARGET=''
    REVEALED=0
    TARGET_DELETED=0
    : > "$STATE_DIR/owners"
    local pass=${PASSWORDS[LEVEL-1]} i j p q d leaf index=0
    local -a branches next
    case "$LEVEL" in
        1)
            mkdir -p "$HOME_GAME/Welcome"; CWD="$HOME_GAME/Welcome"
            touch "$HOME_GAME/$pass"; mkdir "$HOME_GAME/Documents"
            decoy_files "$HOME_GAME" 12 txt
            for ((i=1; i<=8; i++)); do mkdir "$HOME_GAME/archive_$i"; done ;;
        2) mkdir "$HOME_GAME/directory_1"; printf '%s\n' "$pass" > "$HOME_GAME/directory_1/password.txt" ;;
        3) touch "$HOME_GAME/borg.md"; chmod 716 "$HOME_GAME/borg.md" ;;
        4)
            mkdir -p "$HOME_GAME/clues/start" "$HOME_GAME/hello_friend"
            CWD="$HOME_GAME/clues/start"
            say 'The password you are looking for is inside /home/user/hello_friend/kerman.txt.' > "$HOME_GAME/clues/directions.txt"
            say "$pass" > "$HOME_GAME/hello_friend/kerman.txt" ;;
        5) mkdir "$HOME_GAME/gazisiber" ;;
        6)
            mkdir -p "$HOME_GAME/main_directory/subdirectory"; CWD="$HOME_GAME/main_directory"
            say 'GNU/Linux file copying exercise.' > "$CWD/copyme.md"
            cp "$CWD/copyme.md" "$STATE_DIR/copy-original" ;;
        7)
            mkdir "$HOME_GAME/hidden"; CWD="$HOME_GAME/hidden"
            say 'Hidden file to delete.' > "$CWD/.hidden.md"
            decoy_files "$CWD" 30
            for ((i=1; i<=12; i++)); do mkdir "$CWD/archive_$i"; done
            TARGET="$CWD/.hidden.md" ;;
        8)
            mkdir -p "$HOME_GAME/forest/room"; CWD="$HOME_GAME/forest/room"
            TARGET="$CWD/forest/subsubdir" ;;
        9)
            mkdir -p "$HOME_GAME/directory/$(random_name)/$(random_name)"
            CWD="$HOME_GAME/directory"
            leaf=$(find "$CWD" -mindepth 2 -maxdepth 2 -type d)
            TARGET="$leaf/moveme.md"
            say 'Moving task: move this file next to deniz.md.' > "$CWD/moveme.md"
            cp "$CWD/moveme.md" "$STATE_DIR/move-original"
            say 'This is the target directory.' > "$leaf/deniz.md"
            for ((i=1; i<=40; i++)); do
                p=$(make_random_dir "$CWD"); q=$(make_random_dir "$p")
                decoy_files "$q" 4
            done ;;
        10)
            mkdir -p "$HOME_GAME/$(random_name)/$(random_name)"
            CWD=$(find "$HOME_GAME" -mindepth 2 -maxdepth 2 -type d)
            write_noise "$CWD/readme.txt" 100 ;;
        11)
            branches=("$HOME_GAME")
            for ((i=1; i<=5; i++)); do
                next=()
                for p in "${branches[@]}"; do
                    for ((j=1; j<=3; j++)); do
                        if ((i == 3 && index == 0 && j == 1)); then
                            q="$p/topcuoglu"; mkdir "$q"
                        else q=$(make_random_dir "$p")
                        fi
                        next+=("$q")
                        decoy_files "$q" 2
                    done
                    ((index+=1))
                done
                # Reset index to select the first topcuoglu branch at depth three.
                branches=("${next[@]}"); index=0
            done
            TARGET=$(find "$HOME_GAME" -type d -name topcuoglu)
            say "$pass" > "$TARGET/deniz.md"
            for p in "${branches[@]}"; do say 'This file does not contain the password you are looking for.' > "$p/deniz.md"; done ;;
        12)
            mkdir "$HOME_GAME/haystack"; CWD="$HOME_GAME/haystack"
            mkdir "$CWD/sdjedipsa"
            say "$pass" > "$CWD/sdjedipsa/jjddenizq.txt"
            decoy_files "$CWD/sdjedipsa" 4 txt
            for ((i=1; i<=499; i++)); do
                p=$(make_random_dir "$CWD")
                decoy_files "$p" 5 txt
                if ((i % 5 == 0)); then say 'Wrong directory: no password here.' > "$p/deniz_notes.txt"; fi
            done ;;
        13)
            mkdir "$HOME_GAME/search"; CWD="$HOME_GAME/search"
            for ((i=1; i<=500; i++)); do
                p=$(make_random_dir "$CWD")
                if ((i == 237)); then
                    write_noise "$p/hello.md" 80
                    printf 'gazisiber training password: %s\n' "$pass" >> "$p/hello.md"
                    write_noise "$p/hello.md" 70 append
                else
                    q=$(make_random_dir "$p")
                    decoy_files "$q" 3
                fi
            done ;;
        14)
            mkdir "$HOME_GAME/redirection"; CWD="$HOME_GAME/redirection"
            # Exactly 10,000 ASCII characters: 100 lines, including newlines.
            for ((i=0; i<100; i++)); do
                p=$(od -An -N64 -tx1 /dev/urandom); p=${p//[[:space:]]/}
                printf '%s\n' "${p:0:99}"
            done > "$CWD/looong.md" ;;
        15)
            mkdir -p "$HOME_GAME/boom" "$HOME_GAME/list"; CWD="$HOME_GAME/list"
            say '# Previously recorded paths — keep this line.' > "$CWD/path.md"
            cp "$CWD/path.md" "$STATE_DIR/path-original"
            for ((i=0; i<60; i++)); do
                p="$HOME_GAME/boom/$(random_name)/$(random_name)"; mkdir -p "$p"
                if ((i % 2 == 0)); then touch "$p/yunus.md"; else touch "$p/other.md"; fi
                decoy_files "$p" 3
            done ;;
        16)
            mkdir "$HOME_GAME/listing"; CWD="$HOME_GAME/listing"
            touch "$HOME_GAME/murat_systemd.md" "$HOME_GAME/murat_systemd_notes.md" "$HOME_GAME/murat_network.md" "$HOME_GAME/other_systemd.md"
            for ((i=1; i<=40; i++)); do
                touch "$HOME_GAME/murat_note_$i.md" "$HOME_GAME/archive_murat_$i.md" "$HOME_GAME/other_note_$i.md"
            done ;;
        17) mkdir "$HOME_GAME/condition"; CWD="$HOME_GAME/condition" ;;
        18) mkdir "$HOME_GAME/chain"; CWD="$HOME_GAME/chain" ;;
        19|20) mkdir "$HOME_GAME/packages"; CWD="$HOME_GAME/packages" ;;
        21)
            mkdir "$HOME_GAME/permissions"; CWD="$HOME_GAME/permissions"
            touch "$CWD/start.md" "$CWD/notes.md" "$CWD/read.md"
            decoy_files "$CWD" 40
            chmod 644 "$CWD/"*.md; chmod +x "$CWD/start.md"
            TARGET="$CWD/start.md" ;;
        22)
            mkdir "$HOME_GAME/ownership"; CWD="$HOME_GAME/ownership"
            touch "$CWD/one.md" "$CWD/two.md" "$CWD/three.md" ;;
        23)
            mkdir "$HOME_GAME/permissions"; CWD="$HOME_GAME/permissions"
            touch "$CWD/file.c"; chmod 644 "$CWD/file.c" ;;
        24) PASSWORDS[23]=verification ;;
        25) PASSWORDS[24]=broth ;;
    esac
    TASK_DIR=$CWD
    chmod 700 "$STATE_DIR"
    save_level "$LEVEL"
}

save_level() {
    printf '%s\n' "$1" > "$STATE_DIR/level.tmp" &&
        mv -f -- "$STATE_DIR/level.tmp" "$STATE_DIR/level" || {
            DONE=1; fail 'Could not save the level.'; return 1;
        }
}

mark_completed() {
    local -a entries=()
    [[ ! -f "$STATE_DIR/completed" ]] || mapfile -t entries < "$STATE_DIR/completed"
    if grep -Fxq -- "$LEVEL" "$STATE_DIR/completed" 2>/dev/null; then return 0; fi
    printf '%s\n' "${entries[@]}" "$LEVEL" > "$STATE_DIR/completed.tmp" &&
        mv -f -- "$STATE_DIR/completed.tmp" "$STATE_DIR/completed" || {
            DONE=1; fail 'Could not write the completion record.'; return 1;
        }
}

show_task() {
    printf '\n════════════ Level %s / 25 ════════════\n' "$LEVEL"
    case "$LEVEL" in
        1) say 'You are in ~/Welcome. Go to ~ and list its contents. The password is the name of one of the files shown in the listing.'; say 'Commands: cd, ls' ;;
        2) say 'The password you are looking for is in /home/user/directory_1/password.txt.'; say 'Command: cat' ;;
        3) say 'For this level, the password is the first 10-character type and permissions field in the permission details of /home/user/borg.md. Any following . or + is not part of the password.'; say 'Command: ls -l' ;;
        4) say 'Find out which directory you are in, then go to its parent directory and look inside the text file there.'; say 'Commands: pwd, cd, ls, cat' ;;
        5) say 'Create a file named distro.txt in /home/user/gazisiber and use nano to write debian inside it. When you finish, the password will appear in the terminal.'; say 'Commands: cd, touch, nano' ;;
        6) say 'Your current directory contains a file named copyme.md. Copy it to the parent directory and the existing subdirectory to see your password in the terminal.'; say 'From this level onward, commands are no longer shown. You can type help for the guide.' ;;
        7) say 'There is a hidden file in your current directory. Delete it to see your password in the terminal.' ;;
        8) say 'Your current directory is hidden from you. Find out its name, then create a subdirectory with the same name as its parent directory. Inside that subdirectory, create another subdirectory named subsubdir. When you enter subsubdir, a file with the same name as your password will appear.' ;;
        9) say 'Your current directory contains moveme.md. Move it to the directory containing deniz.md, then look inside the moved file to find your password.' ;;
        10) say 'Open and close readme.txt using the command that displays file contents with scrolling via the up and down arrow keys. A file named less.txt will then appear. Your password is somewhere inside it. Hint: the line containing the password also contains broth.' ;;
        11) say 'One of the files named deniz.md under /home/user contains your password. The file you need is inside a directory named topcuoglu.' ;;
        12) say 'Your current directory has 500 subdirectories. Your password is in a file whose name contains deniz, inside one of the directories whose name contains edip.' ;;
        13) say 'Your current directory has 500 subdirectories. Of these, 499 contain another directory, while one contains hello.md. Your password is on one of the lines in that file. Hint: the line containing the password also contains gazisiber.' ;;
        14) say 'Your current directory contains looong.md. Write all its contents to a new file named hello.md. The password will appear in the terminal. You must combine the command that reads the file with the output redirection operator. Trying another method restarts this level.' ;;
        15) say 'Find the paths of all yunus.md files under /home/user/boom and append them to path.md. Keep its existing contents. Use the search command together with the append operator. Trying another method restarts this level. The password will appear in the terminal.' ;;
        16) say 'In the parent directory, list the filenames that start with murat and contain systemd. Pass the listing output to the filtering command. The output must contain only the full paths of the two matching files; the correct operation reveals the password in the terminal.' ;;
        17) say 'Enter a command that prints Failed in the terminal when it cannot read the nonexistent file iexist.md in your current directory. Entering the answer in the terminal is enough.' ;;
        18) say 'First, create a directory named nowiexist in your current directory. Then, on a single command line, list its contents if changing into it succeeds. The name of the automatically created file is the password. If you use the wrong method for the second step, your input will be rejected.' ;;
        19) say 'How do you install the cowsay and btop packages on a single command line using the package manager used by Debian?' ;;
        20) say 'On a single command line, first retrieve current package information from repositories, then install available updates for installed packages.' ;;
        21) say 'Find the file in your current directory that you have permission to execute, and remove its execute permission.' ;;
        22) say 'You own three files in your current directory. Transfer ownership of all three to user eyub. The password will automatically appear in the terminal. No administrator privileges or password are requested.' ;;
        23) say 'Set the permissions of file.c, which you own, to rwxr--rw-.' ;;
        24) say 'The word immediately following the last occurrence of authentication in the sudo manual page is your password. Filter the manual page to show matching lines. This level is an exception to the five-letter English password rule.' ;;
        25) say 'Thank you for taking part in this training and making it this far. If you want to improve your technical knowledge of GNU/Linux, learn new things, and get involved in this field, we welcome you to the Free Software and Linux Team. Well done! Your password is: broth.' ;;
    esac
}

reveal() {
    if ((REVEALED == 0)); then
        printf '\nYour password: %s\n' "${PASSWORDS[LEVEL-1]}"
        say 'To advance: password <password-you-found>'
        REVEALED=1
    fi
}

check_completion() {
    local p mode ok=1
    case "$LEVEL" in
        5)
            p="$HOME_GAME/gazisiber/distro.txt"
            if [[ -f $p ]] && [[ $(cat "$p") == debian ]]; then reveal; fi ;;
        6)
            if cmp -s "$STATE_DIR/copy-original" "$HOME_GAME/copyme.md" &&
               cmp -s "$STATE_DIR/copy-original" "$HOME_GAME/main_directory/subdirectory/copyme.md" &&
               cmp -s "$STATE_DIR/copy-original" "$HOME_GAME/main_directory/copyme.md"; then reveal; fi ;;
        7) if ((TARGET_DELETED)) && [[ ! -e $TARGET ]]; then reveal; fi ;;
        9)
            if [[ ! -e "$HOME_GAME/directory/moveme.md" ]] && cmp -s "$STATE_DIR/move-original" "$TARGET"; then
                say "${PASSWORDS[LEVEL-1]}" > "$TARGET"
                say 'The file has been moved to the right place. Look inside it.'
            fi ;;
        14)
            if [[ $CWD == "$TASK_DIR" ]] && matches cat looong.md '>' hello.md && cmp -s "$TASK_DIR/looong.md" "$TASK_DIR/hello.md"; then reveal; fi ;;
        15)
            if [[ $CWD == "$TASK_DIR" ]] && matches find /home/user/boom -name yunus.md '>>' path.md; then
                { cat "$STATE_DIR/path-original"; find "$HOME_GAME/boom" -name yunus.md | strip_paths; } > "$STATE_DIR/path-expected"
                if cmp -s "$TASK_DIR/path.md" "$STATE_DIR/path-expected"; then reveal; fi
            fi ;;
        16)
            if [[ $(wc -l < "$STATE_DIR/terminal-output") -eq 2 ]] &&
               grep -Fxq '/home/user/murat_systemd.md' "$STATE_DIR/terminal-output" &&
                grep -Fxq '/home/user/murat_systemd_notes.md' "$STATE_DIR/terminal-output"; then reveal; fi ;;
        17) if matches cat iexist.md '||' echo Failed && [[ ! -e "$CWD/iexist.md" ]]; then reveal; fi ;;
        18)
            if matches cd nowiexist '&&' ls && [[ $CWD == "$HOME_GAME/chain/nowiexist" ]]; then REVEALED=1; fi ;;
        19) if matches sudo apt install cowsay btop || matches sudo apt install btop cowsay; then reveal; fi ;;
        20) if matches sudo apt update '&&' sudo apt upgrade; then reveal; fi ;;
        21)
            if [[ -f $TARGET ]]; then
                mode=$(stat -c %a "$TARGET")
                if (( (8#$mode & 0111) == 0 )); then reveal; fi
            fi ;;
        22)
            for p in one.md two.md three.md; do
                grep -Fxq -- "$HOME_GAME/ownership/$p" "$STATE_DIR/owners" || ok=0
            done
            if ((ok)); then reveal; fi ;;
        23) if [[ $(stat -c %a "$HOME_GAME/permissions/file.c" 2>/dev/null) == 746 ]]; then reveal; fi ;;
    esac
}

guard_method() {
    local token risky=0 command_position=1 has_cd=0
    if ((LEVEL == 14 || LEVEL == 15)); then
        if ((LEVEL == 14)) && matches cat looong.md '>' hello.md; then return 0; fi
        if ((LEVEL == 15)) && matches find /home/user/boom -name yunus.md '>>' path.md; then return 0; fi
        for token in "${TOKENS[@]}"; do
            case "$token" in
                "$OP>"|"$OP>>") risky=1 ;;
                "$OP|"|"$OP&&"|"$OP||") command_position=1 ;;
                *)
                    if ((command_position)); then
                        case "$token" in cp|mv|rm|touch|mkdir|nano|chmod|chown) risky=1 ;; esac
                        command_position=0
                    fi ;;
            esac
        done
        if ((risky)); then
            say 'Incorrect solution method. Only this level has been restarted.'
            setup_level || return 1
            show_task; return 1
        fi
    elif ((LEVEL == 18)); then
        for token in "${TOKENS[@]}"; do
            case "$token" in
                "$OP|"|"$OP&&"|"$OP||") command_position=1 ;;
                *)
                    if ((command_position)); then
                        [[ $token != cd ]] || has_cd=1
                        command_position=0
                    fi ;;
            esac
        done
        if ((has_cd)); then
            matches cd nowiexist '&&' ls || { fail 'You must combine changing directory and listing with a success condition.'; return 1; }
        fi
        if matches cd nowiexist '&&' ls; then
            [[ $CWD == "$TASK_DIR" && -d "$TASK_DIR/nowiexist" ]] || { fail 'First, create nowiexist in the starting directory.'; return 1; }
            [[ -x "$TASK_DIR/nowiexist" ]] || { fail 'You do not have permission to enter this directory.'; return 1; }
            touch "$TASK_DIR/nowiexist/${PASSWORDS[LEVEL-1]}" || return 1
        fi
    fi
}

attempt_password() {
    ((${#TOKENS[@]} == 2)) || { say 'Usage: password <password-you-found>'; return; }
    if [[ ${TOKENS[1]} != "${PASSWORDS[LEVEL-1]}" ]]; then say 'Incorrect password. Try again.'; return; fi
    case "$LEVEL" in
        5|6|7|14|15|16|17|18|19|20|21|22|23)
            ((REVEALED)) || { say "You must complete this level's task first."; return; } ;;
        8) ((REVEALED)) && [[ -f "$TARGET/${PASSWORDS[LEVEL-1]}" ]] || { say 'You must enter the correct subsubdir directory first.'; return; } ;;
        9) [[ -f $TARGET ]] && [[ $(cat "$TARGET") == "${PASSWORDS[LEVEL-1]}" ]] || { say 'You must complete the moving task first.'; return; } ;;
        10) ((REVEALED)) && [[ -f "$TASK_DIR/less.txt" ]] || { say 'You must complete the viewing task first.'; return; } ;;
    esac
    mark_completed || return 1
    if ((LEVEL == 25)); then
        save_level 26 || return 1
        DONE=1
        say 'Congratulations! You have completed all 25 levels. Keep enjoying free software!'
    else
        say 'Correct password! Moving on to the next level.'
        ((LEVEL+=1)); setup_level || return 1
        show_task
    fi
}

process_line() {
    local line=$1 status
    : > "$STATE_DIR/terminal-output"
    tokenize "$line" || return
    ((${#TOKENS[@]})) || return
    validate_tokens || return
    case "${TOKENS[0]}" in
        hardreset)
            ((${#TOKENS[@]} == 1)) || { say 'Usage: hardreset'; return; }
            LEVEL=1
            DONE=0
            setup_level || return 1
            : > "$STATE_DIR/completed"
            say 'The game has been reset. You are back at level 1.'
            show_task
            return ;;
        flashback)
            if ((${#TOKENS[@]} != 2)) || [[ ! ${TOKENS[1]:-} =~ ^([1-9]|1[0-9]|2[0-5])$ ]]; then
                say 'Usage: flashback <1-25>'
                return
            fi
            if [[ ! -f "$STATE_DIR/completed" ]] || ! grep -Fxq -- "${TOKENS[1]}" "$STATE_DIR/completed"; then
                say 'You have not completed this level yet. flashback only opens completed levels.'
                return
            fi
            LEVEL=${TOKENS[1]}
            DONE=0
            setup_level || return 1
            say "You have returned to completed level $LEVEL."
            show_task
            return ;;
        rewind)
            ((${#TOKENS[@]} == 1)) || { say 'Usage: rewind'; return; }
            DONE=0
            setup_level || return 1
            say "Level $LEVEL has been restarted."
            show_task
            return ;;
        leveljump)
            if ((${#TOKENS[@]} != 2)) || [[ ! ${TOKENS[1]:-} =~ ^([1-9]|1[0-9]|2[0-5])$ ]]; then
                say 'Usage: leveljump <1-25>'
                return
            fi
            LEVEL=${TOKENS[1]}
            DONE=0
            setup_level || return 1
            show_task
            return ;;
        exit|quit)
            ((${#TOKENS[@]} == 1)) || { say 'Usage: exit'; return; }
            DONE=1; say 'Your progress has been saved. See you next time!'; return ;;
        task)
            ((${#TOKENS[@]} == 1)) || { say 'Usage: task'; return; }
            show_task; return ;;
        help)
            ((${#TOKENS[@]} == 1)) || { say 'Usage: help'; return; }
            if [[ -t 0 && -t 1 ]]; then help_text | LESSSECURE=1 LESSHISTFILE=- command less
            else help_text; fi
            return ;;
        password) attempt_password; return ;;
    esac
    guard_method || return
    run_tokens; status=$?
    if ((status == 0)); then check_completion; fi
}

init_state() {
    local fresh=$1
    mkdir -p -- "$STATE_DIR" || { fail 'Could not create the save directory.'; return 1; }
    STATE_DIR=$(realpath -- "$STATE_DIR")
    [[ $STATE_DIR != / && $STATE_DIR != "$SCRIPT_DIR" ]] || { fail 'Invalid save directory.'; return 1; }
    local file value index finished=0
    for file in .linux101-state passwords level completed owners error lock level.tmp completed.tmp copy-original move-original path-original path-expected terminal-output stdout-stage; do
        if [[ -L "$STATE_DIR/$file" || ( -e "$STATE_DIR/$file" && ! -f "$STATE_DIR/$file" ) ]]; then
            fail "Corrupt save: $file must be a regular file."; return 1
        fi
    done
    [[ ! -L "$STATE_DIR/world" ]] || { fail 'Corrupt save: the game world cannot be a symbolic link.'; return 1; }
    if [[ ! -f "$STATE_DIR/.linux101-state" ]]; then
        [[ -z $(find "$STATE_DIR" -mindepth 1 -maxdepth 1 -print -quit) ]] || {
            fail 'The save directory is not empty and does not belong to this game.'; return 1;
        }
        touch "$STATE_DIR/.linux101-state"
    fi
    chmod 700 "$STATE_DIR" || return 1
    exec {STATE_LOCK_FD}> "$STATE_DIR/lock" || return 1
    flock -n "$STATE_LOCK_FD" || { fail 'This save is being used by another game session.'; return 1; }
    if ((fresh == 0)) && [[ ! -f "$STATE_DIR/passwords" &&
        ( -e "$STATE_DIR/level" || -e "$STATE_DIR/completed" || -e "$STATE_DIR/world" ) ]]; then
        fail 'Corrupt save: password record missing; use --new for a new game.'; return 1
    fi
    if ((fresh)) || [[ ! -f "$STATE_DIR/passwords" ]]; then
        local -a pool=(broth ocean paper books cloth lemon berry spice fizzy steam plate soaps dough straw seeds cloud drops woods story tales eager steel brass acorn pears)
        mapfile -t PASSWORDS < <(printf '%s\n' "${pool[@]}" | shuf)
        PASSWORDS[2]='-rwx--xrw-'; PASSWORDS[23]=verification; PASSWORDS[24]=broth
        printf '%s\n' "${PASSWORDS[@]}" > "$STATE_DIR/passwords" || return 1
        : > "$STATE_DIR/completed" || return 1
        LEVEL=1
    else
        mapfile -t PASSWORDS < "$STATE_DIR/passwords"
        read -r LEVEL < "$STATE_DIR/level" || { fail 'Could not read the level record; use --new to start over.'; return 1; }
        [[ $LEVEL =~ ^([1-9]|1[0-9]|2[0-6])$ && ${#PASSWORDS[@]} -eq 25 ]] || { fail 'Corrupt save; use --new to start over.'; return 1; }
        [[ ${PASSWORDS[2]} == '-rwx--xrw-' && ${PASSWORDS[23]} == verification && ${PASSWORDS[24]} == broth ]] || {
            fail 'Corrupt save: invalid passwords for special levels.'; return 1;
        }
        for ((index=0; index<25; index++)); do
            ((index == 2 || index == 23)) && continue
            value=${PASSWORDS[index]}
            [[ $value =~ ^[[:alpha:]]{5}$ ]] || { fail 'Corrupt save: passwords must have five letters.'; return 1; }
        done
        if [[ ! -f "$STATE_DIR/completed" ]]; then
            # Older saves did not track completion history. During migration,
            # treat all levels before the saved level as completed.
            : > "$STATE_DIR/completed"
            local previous
            for ((previous=1; previous<LEVEL; previous++)); do
                printf '%s\n' "$previous" >> "$STATE_DIR/completed"
            done
        fi
        while IFS= read -r value || [[ -n $value ]]; do
            [[ $value =~ ^([1-9]|1[0-9]|2[0-5])$ ]] || { fail 'Corrupt save: invalid completed-level list.'; return 1; }
        done < "$STATE_DIR/completed"
    fi
    if ((LEVEL == 26)); then
        LEVEL=25; finished=1
        say 'This game has been completed. Use flashback to replay levels or hardreset to start over.'
    fi
    setup_level || return 1
    # Simply reopening a completed game does not undo its completion record.
    if ((finished)); then save_level 26 || return 1; fi
    return 0
}

main() {
    local fresh=0 line dependency status
    while (($#)); do
        case "$1" in
            --new) fresh=1; shift ;;
            --state-dir)
                (($# >= 2)) || { fail 'Missing save directory.'; return 1; }
                STATE_DIR=$2; shift 2 ;;
            --help|-h)
                say 'Usage: bash gnulinux101-en.sh [--new] [--state-dir DIRECTORY]'
                say 'In-game: task, help, password <word>, flashback <level>, rewind, hardreset, exit'; return ;;
            *) fail "Unknown option: $1"; return 1 ;;
        esac
    done
    for dependency in realpath od shuf stat cmp find grep sed awk less nano flock; do
        command -v "$dependency" >/dev/null || { fail "Required program not found: $dependency"; return 1; }
    done
    umask 022
    if init_state "$fresh"; then :
    else
        status=$?
        if ((status == 2)); then return 0; fi
        return "$status"
    fi
    say 'GNU/Linux 101 — Terminal Game'
    say 'This is a controlled training terminal; no packages are installed on the real system.'
    say 'Your home directory: /home/user. Guide: help | Current task: task | Quit: exit'
    say 'Type hardreset to start over: the current game world is reset and you return to level 1.'
    say 'Use flashback <level> to replay a completed level; use rewind to restart the current level.'
    say 'Passwords are meaningful five-letter English words (example: broth).'
    say 'Exceptions: level 3 uses the 10-character file type/permissions field; level 24 uses a word from the manual.'
    say 'Enter the password you found as password <word>; for example: password broth.'
    say 'Your current level is saved; reopening the game rebuilds that level from scratch.'
    show_task
    while ((DONE == 0)); do
        if [[ -t 0 ]]; then
            if ((LEVEL == 4 || LEVEL == 8 || LEVEL == 10)); then printf 'player:???$ '
            else printf 'player:%s$ ' "$(virtual_path "$CWD")"; fi
        fi
        IFS= read -r line || [[ -n $line ]] || break
        process_line "$line"
    done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
