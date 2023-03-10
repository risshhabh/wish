#!/bin/sh

#** Wish C **#

#* Variables *#
# !! `realpath` Requires homebrew `coreutils` package
exe_dir=$(realpath -q ./target)  # Default executable path -- set with `-o` flag
src_dir=$(realpath -q ./src)     # Default code path
                                 # TODO cannot be set with a flag


if [[ ! -d ./src ]]
then
    echo "Fatal: No \$exe_dir in \$PWD; exit with error 1"
    exit 1
fi

start_pwd=`pwd -P`

case $1 in
    dependent|dependencies)
        bold=$(tput bold)
        norm=$(tput sgr0)
        echo "${bold}wish.sh MacOS dependencies${norm}"
        echo "       ${bold}Homebrew Coreutils${norm} @ https://formulae.brew.sh/formula/coreutils#default"
        echo "              Uses \`realpath\` to get absolute path of file"
        echo "              Install by running ${bold}\`brew install coreutils\`${norm}\n"
        echo "       ${bold}sharkdp/fd${norm} @ https://github.com/sharkdp/fd"
        echo "              Uses \`fd\` to search for files with C extensions"
        echo "              Install by running ${bold}\`brew install fd\`${norm}"
        echo "              Or alternatively, use \`for_file_search\` instead of \`fd_ext_search\`"
        echo "              \`check_comp_exists\` still requires \`fd\`\n"
        echo "       ${bold}nivekuil/rip${norm} @ https://gihub.com/nivekuil/rip"
        echo "              Uses \`rip\` to delete files,"
        echo "              Can use builtin \`rm\` by editing code\n"
        echo "       ${bold}wish.py${norm} @ $(realpath -q $(dirname $0)'/wish.py')"
        echo "              Uses Python to do some basic path manipulation"
        echo "              Make sure \`wish.py\` is located in the same folder as \`wish.sh\`."
        exit 0;;
    commands|command|cmds|cmd)
        bold=$(tput bold)
        norm=$(tput sgr0)
        echo "${bold}COMPILE${norm}: /usr/bin/g++ -fdiagnostics-color=always -std=c17 -pedantic-errors -Wall -Wextra -Weffc -Wsign-conversion \$LIBRARY \$INCLUDE -o \$EXEC_FILE -g \$SRC_FILE"
        echo "Where \$LIBRARY=\"-L/usr/local/global_libs/boost_1_81_0/stage/lib\""
        echo "  and \$INCLUDE=\"-I/usr/local/global_libs/boost_1_81_0\""
        exit 0;;
esac

# ? -h|--help)
print_help_page()
{
    bold=$(tput bold)
    norm=$(tput sgr0)
    echo "${bold}NAME${norm}"
    echo "       ${bold}wish${norm} - shorthand preconfigured C compile command.\n"
    echo "${bold}PROJECT FORMAT${norm}"
    echo "       wish assumes the pwd to have a code \`src/\` and executable output \`target/\` folder."
    echo "       The output folder can be changed with the ${bold}-o${norm} flag.\n"
    echo "${bold}COMMANDS${norm}"
    echo "       ${bold}-a, --all, --compile-all${norm}"
    echo "              Compile all C files in \$src_dir\n"
    echo "       ${bold}-c, --compile${norm}"
    echo "              Compile given argument, return error if it is not a C file\n"
    echo "       ${bold}-d, --delete${norm}"
    echo "              Delete executable via nivekuil/rip,"
    echo "              Return error if given argument is not an executable file\n"
    echo "       ${bold}-D, --delete-all${norm}"
    echo "              Delete all executables in \$exe_dir via nivekuil/rip\n"
    echo "       ${bold}-h, --help, help${norm}"
    echo "              Display help page\n"
    echo "       ${bold}-o, --output${norm} !! DO NOT USE"
    echo "              Location of output executable directory realtive to C file,"
    echo "              Default is \`../target/\`\n"
    echo ""
    echo "\nAs of the current version, the ${bold}-o${norm} flag must be placed before all other flags"
    echo "\`wish dependencies\` : see wish's dependencies"
    echo "\`wish command\`      : see compile command"
}

if [[ ! "$1" ]] # 0 args given
                # Technically saying `if there is not a $1`
then  # ? --help
    print_help_page
    exit 0
fi


# ? -a|--all)
fd_ext_search()
{
    cd $src_dir # Only search in $src_dir folder

    old_IFS=$IFS
    IFS=$'\n'  # Splits only by newlines, not spaces nor tabs
    c_files=($( fd -HIag -e c))  # sharkdp/fd
               # Makes array of all C files in $src_dir
    IFS=$old_IFS  # Reverts splits
    cd $start_pwd  # Go back out of $src_dir

    # BASH alternative that doesn't work in ZSH :'(
    # mapfile -t c_files < <( fd -HIag -e c)
}
# ?? If sharkdp/fd is not installed, match case for extensions
for_file_search()
{
    cd $src_dir
    for file in *
    do
        case "$file" in
            *.[Cc]) c_files+=($(realpath -q $file));;  # RegEx for case insensitivity
        esac
    done
    cd $start_pwd
}


# ? -c|--compile)
check_comp_exists() {
    if [ -d "$1" ]
    then
        echo "error: Expected file, instead got directory"
        exit 1
    elif [ ! -f "$1" ]
    then
        echo "error: Expected file, instead got: $1"
        exit 1
    fi

    case "$1" in  # First make sure it is C file
        # *.[Cc][Pp][Pp]|*.[Cc][Xx][Xx]|*.[Cc][Cc]) true;;  # RegEx for case insensitivity -- C++
        *.[Cc]) true;;  # RegEx for case insensitivity -- C
        *)
            echo "error: Expected C file, got: $1"
            exit 1;;
    esac

    # Test if $1 is inside $src_dir
    fd_ext_search  # Get all C files in $src_dir
    if [[ "${c_files[@]}" =~ "$1" ]]
    then
        c_files=($(realpath -q "$1"))
    fi
}


# ? -d|--delete)
rip_save()
{
    if [[ ! "$1" ]]
    then
        echo "error: No file given"
        exit 1
    elif [ -d $1 ]
    then
        echo "error: Expected file, got directory"
        exit 1
    elif [[ ! -x "$1" ]]
    then
        echo "error: Expected executable, got $1"
        exit 1
    else
        rip_file=$(realpath -q "$1")
    fi
}


# ? -o|--output)
set_exe_out_dir()
{
    if [[ ! "$1" ]]  # Check if $1 exists
    then
        echo "error: No directory given"
        exit 1
    elif [ ! -d $1 ]  # Check if $1 is not dir
    then
        echo "error: Cannot set output executable directory: no such directory"
        exit 1
    fi
    exe_dir=$(realpath -q "$1")
}


# https://rowannicholls.github.io/bash/intro/passing_arguments.html
while [[ "$#" -gt 0 ]]
do
case $1 in
    -a|--all|--compile-all)
        fd_ext_search  #-> c_files: arr[str: abspath]
        shift;;
    -c|--compile)
        check_comp_exists "$2"  #-> c_files -> arr[str: abspath], len == 1
        shift;;  # $2 -> $1
    -d|--delete)
        rip_save "$2" #-> rip_file -> str: abspath
        shift;;
    -D|--delete-all)
        rip_file=true  #-> if [rip_file = true] then rip $exe_dir ; mkdir -p $exe_dir
        shift;;
    -h|--help|help)
        print_help_page
        exit 0;;
    # -o|--output)
    #     echo "In -o flag"
    #     set_exe_out_dir "$2"
    #     shift;;
    *)
        echo "error: Unknown parameter passed: $1"
        exit 1;;
esac
shift
done

# Finish delete commands
if [ "$rip_file" = true ]
then
    read -p "Really delete all executables? (y/N) " confirm
    confirm_code=("Y" "y")

    if [[ "${confirm_code[@]}" =~ "$confirm" ]]
    then
        rip $exe_dir
        mkdir -p $exe_dir
    fi
elif [[ $rip_file ]]  # Else if there is $rip_file that is not `true`,
then                  # Delete that $rip_file
    rip "${rip_file}"
fi


# Finish compile commands

## METHOD
# Goal is to go from $src_dir/path/to/file.c -> $exe_dir/path/to/file
#
# 1. goto $src_dir
# 2. get relpath of file.c; ./path/to/file.c
# 3. goto $exe_dir
# 4. mkdir -p ./path/to
# 5. compile_command $src_dir/path/to/file.c -o ./path/to/file
## METHOD

#! Return error when C file not in $src_dir (should not happen)
if [[ $c_files ]]  # If $c_files is not empty
then

    # LIBRARY="-L/usr/local/global_libs/boost_1_81_0/stage/lib"
    # INCLUDE="-I/usr/local/global_libs/boost_1_81_0"
    pypath="$(dirname $0)/wish.py"

    for c_file in "${c_files[@]}"
    do
        relfile=$(python3 $pypath "1" $c_file $src_dir)  # 1,2

        cd $exe_dir # 3

        mkdir -p $(dirname $relfile) # 4

        cd $(realpath -q $(dirname $relfile))  # cd into folder where executable will be made

        /usr/bin/gcc -fdiagnostics-color=always -std=c17 -pedantic-errors -Wall -Wextra -Wsign-conversion -o $(python3 $pypath "2" $c_file) $c_file  # 5

        cd $start_pwd
    done
fi
