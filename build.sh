#!/bin/sh

# build.sh: contains some utils for the building of new releases for the Solar Project.
# this will touch some important files and other misc. stuff to run the game as it is
# intended. More info, run "-h" option.
_VERSION="1.0"
LOVE_ZIP_INCLUDE_FILES="./sol ./game ./main.lua ./README.md ./LICENSE ./build.sh"
BUILD_LOG="./build/log" ;
NO_COLOR="\e[0m"
COLOR_RED="\e[31m"
COLOR_BLUE="\e[36m"
COLOR_PURPLE="\e[35m"

# _die(): die :)
_die(){
    echo "[build.sh die()]: $1" ; exit -1
}

# run_cmd(): wrapper for running commands.
run_cmd(){
    _COMMAND=$1 ; printf "${COLOR_PURPLE}[build.sh]${NO_COLOR}: running command: ${COLOR_BLUE}\"$_COMMAND\"${NO_COLOR} ... "
    $_COMMAND >> $BUILD_LOG ; if [[ $? != 0 ]]; then
        printf "failed.\n" ; _die "failed to run command: \"$_COMMAND\"!"
    else
        printf "done!\n"
    fi
}

# check_dirs(): check if the building directory is there.
check_dirs(){
    [[ -e "./build" ]] || mkdir ./build
}

# create_love_package(): creates a new love package.
create_love_package(){
    check_dirs
    LOVE_SOLAR_BUILD_FILE="./build/solar-build.love"
    LOVE_SOLAR_PAST_BUILD_FILE="./build/solar-pastbuild.love"
    LOVE_ZIP_LOG_TARGET="./build/zip-cmd.log"
    if [[ -e "$LOVE_SOLAR_BUILD_FILE" ]]; then
        [[ -e "$LOVE_SOLAR_PAST_BUILD_FILE" ]] && run_cmd "rm $LOVE_SOLAR_PAST_BUILD_FILE"
        run_cmd "mv $LOVE_SOLAR_BUILD_FILE $LOVE_SOLAR_PAST_BUILD_FILE"
    fi
    run_cmd "zip -9 -r $LOVE_SOLAR_BUILD_FILE $LOVE_ZIP_INCLUDE_FILES"
}

# main
echo "build.sh $(date): begun!" > $BUILD_LOG
echo -e "${COLOR_PURPLE}[build.sh]${NO_COLOR}: Solar Engine's build tool $_VERSION"
if [[ "$#" == 0 ]]; then
    echo -e "some options you can run: "
    echo -e "\tpackage:                 builds a new solar-build.love file."
    exit 0
else
    for arg in "$@"; do
        case $arg in
            package)
                create_love_package
                ;;
            *)
                echo "[!] invalid option: $arg"
                exit -1
                ;;
        esac
    done
fi