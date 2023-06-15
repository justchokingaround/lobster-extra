#!/bin/sh
set -e

config_file="$HOME/.config/lobster/lobster_config.txt"

[ -n "$XDG_DATA_HOME" ] && data_dir="$XDG_DATA_HOME/lobster" || data_dir="$HOME/.local/share/lobster"
[ -z "$histfile" ] && histfile="$data_dir/lobster_history.txt"

test_log_file="./test_log.txt"
[ -f "$test_log_file" ] && rm "$test_log_file"
if [ -f "/usr/local/bin/lobster-testing-version" ]; then
    echo "Please enter your password to remove the testing version of lobster currently installed..."
    sudo rm "/usr/local/bin/lobster-testing-version"
fi

cleanup() {
    mv "/tmp/$(basename "$config_file").bak" "$config_file" 2>/dev/null || true
    mv "/tmp/$(basename "$histfile").bak" "$histfile" 2>/dev/null || true
    # TODO use keep-testing-version flag
    rm "$PWD/lobster-testing-version" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

usage() {
    printf "
  Usage: %s [options] [arguments]

  Options:
    -h, --help
      Show this help message and exit

    -t, --test
      Specifies the number of the test to run (1-8)
      When using this option, the script will exit after the test is completed

    -k, --keep, --keep-testing-version
      Specifies that the testing version of lobster should not be removed after the test is completed, therefore allowing you to use the script normally by running lobster-testing-version

    -r, --raw, --raw-link, --url
        Use this option to pass the raw link of the lobster script you'd like to test

    -u, -U, --update
      Update the script

  Some example usages:
    ${0##*/} -t 3
    ${0##*/} -t 5 -k
    ${0##*/} -r https://raw.githubusercontent.com/justchokingaround/lobster/fix-subs/lobster.sh

" "${0##*/}"
}

backup() {
    if [ -f "$1" ]; then
        echo "Making a copy of the current $1 file..."
        mv "$1" "/tmp/$(basename "$1").bak"
        echo "A copy of the current $1 file has been made."
    fi
}

confirm() {
    while true; do
        printf "%s [Y/n]: " "$1"
        read -r choice
        case $choice in
            [Yy]* | "") return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

ask_for_upload() {
    if confirm "Would you like to upload this file to oshi.at for easily sharing it?"; then
        curl -s "https://oshi.at" -F f=@$test_log_file -F shorturl=1 | sed -nE "s@DL: (.*)@\1@p"
    fi
}

press_enter_to_continue() {
    printf "Press enter to continue...\n"
    read -r _useless
}

get_test_results() {
    if confirm "$1"; then
        echo "This test passed ✅"
        echo "$1 => passed ✅" >>"$test_log_file"
    else
        echo "This test failed ❌"
        echo "$1 => failed ❌" >>"$test_log_file"
    fi
}

checklist_completed() {
    if confirm "$1"; then
        printf "Add any comments you have about this test (leave blank otherwise): "
        read -r comments
        printf "\nComments: %s\n\n" "$comments" >>"$test_log_file"
        echo "Checklist for test $2 completed ✅" | tee -a "$test_log_file"
        echo "---------------------------------" | tee -a "$test_log_file"
        echo "|||||||||||||||||" | tee -a "$test_log_file"
        printf "\n" | tee -a "$test_log_file"
        return 0
    else
        return 1
    fi
}

checklist() {
    printf "\n\nTest checklist.\n" | tee -a "$test_log_file"
    echo "----------------------------------" | tee -a "$test_log_file"
    if [ "$1" != 4 ] && [ "$1" != 6 ]; then
        get_test_results "1. The video file is playing"
        if [ "$1" = 7 ]; then
            get_test_results "2. The subtitles are being displayed in Russian"
        else
            get_test_results "2. The subtitles are being displayed in English"
        fi
        get_test_results "3. The movie/episode title is being displayed (this can be checked with the toggle keybind Shift+I in mpv)"
    fi
    case "$1" in
        2)
            get_test_results "4. Image preview in fzf is working"
            get_test_results "5. There are several subtitles to choose from (this can be checked by using the keybind Shift+J in mpv)"
            ;;
        3)
            get_test_results "4. The next episode feature works from the 2nd episode to the 3rd episode of the 1st season"
            get_test_results "5. The next episode feature works from the 3rd episode to the 1st episode of the 2nd season"
            ;;
        4)
            get_test_results "1. The download feature works"
            ;;
        6)
            get_test_results "1. A json file is printed to the terminal"
            get_test_results "2. The video link is decrypted (it should end with .m3u8)"
            get_test_results "3. There are several subtitles files"
            ;;
        8)
            get_test_results "4. The video quality is 720p (use Shift+I in mpv to toggle information, then check that next to Native Resolution, it says 1290x720)"
            ;;
    esac
}

test_template() {
    echo "|||||||||||||||||" | tee -a "$test_log_file"
    case "$1" in
        1) echo "This test is designed to test a movie with one subtitle track" | tee -a "$test_log_file" ;;
        2) echo "This test is designed to test a movie with multiple subtitle tracks and the image preview feature in fzf" | tee -a "$test_log_file" ;;
        3) echo "This test is designed to test a tv show with multiple seasons and episodes, as well as the next episode feature" | tee -a "$test_log_file" ;;
        4) echo "This test is designed to test the download feature" | tee -a "$test_log_file" ;;
        5) echo "This test is designed to test the rofi feature (without image preview)" | tee -a "$test_log_file" ;;
        6) echo "This test is designed to test the json output feature" | tee -a "$test_log_file" ;;
        7) echo "This test is designed to test the subtitle language feature" | tee -a "$test_log_file" ;;
        8) echo "This test is designed to test the quality feature" | tee -a "$test_log_file" ;;
    esac
    echo "Running test $1..." | tee -a "$test_log_file"
    echo "Running: $2" | tee -a "$test_log_file"
    case "$1" in
        3)
            echo "Select the 2nd episode of the 1st season"
            echo "Test out the next episode feature, after you get the prompt (on episode completion it will ask you to continue, choose Yes)"
            echo "The next episode feature should be tested twice (from 2nd episode to 3rd and from 3rd episode to 1st episode of the 2nd season)"
            press_enter_to_continue
            ;;
    esac
    $2
    checklist "$1"
}

test_completion() {
    printf "\n"
    while :; do
        if checklist_completed "Are you done with this test's checklist? (Choosing no will let you run this test again)" "$1"; then
            break
        else
            printf "\nTest %s has been reset.\n" "$1" | tee -a "$test_log_file"
            test_template "$1" "$2"
        fi
    done
}

run_test() {
    test_template "$1" "$2"
    test_completion "$1" "$2"
}

execute_test() {
    case $1 in
        1) run_test "1" "lobster-testing-version fight club" ;;
        2) run_test "2" "lobster-testing-version a silent voice -i" ;;
        3) run_test "3" "lobster-testing-version sherlock" ;;
        4) run_test "4" "lobster-testing-version rick and morty -d" ;;
        5) run_test "5" "lobster-testing-version weathering --rofi with you" ;;
        6) run_test "6" "lobster-testing-version -j blade runner 2049" ;;
        7) run_test "7" "lobster-testing-version -l russian wolf of wall street" ;;
        8) run_test "8" "lobster-testing-version shawshank redemption -q 720" ;;
    esac
}

update_script() {
    which_lobster_tests="$(command -v lobster-tests)"
    [ -z "$which_lobster_tests" ] && echo "Can't find lobster-tests in PATH"
    [ -z "$which_lobster_tests" ] && exit 1
    update=$(curl -s "https://raw.githubusercontent.com/justchokingaround/lobster-extra/master/lobster-tests.sh" || exit 1)
    update="$(printf '%s\n' "$update" | diff -u "$which_lobster_tests" -)"
    if [ -z "$update" ]; then
        send_notification "Script is up to date :)"
    else
        if printf '%s\n' "$update" | patch "$which_lobster_tests" -; then
            send_notification "Script has been updated!"
        else
            send_notification "Can't update for some reason!"
        fi
    fi
    exit 0
}

# TODO: add a test for rofi with image preview

while [ $# -gt 0 ]; do
    case "$1" in
        --)
            shift
            lobster="$*"
            break
            ;;
        -h | --help)
            usage && exit 0
            ;;
        -k | --keep | --keep-testing-version)
            keep_testing_version=1
            shift
            ;;
        -t | --test)
            test_number="$2"
            shift 2
            ;;
        -r | --raw | --raw-link | --url)
            raw_link="$2"
            shift 2
            ;;
        -u | -U | --update)
            update_script
            ;;
        *)
            lobster="$1"
            shift
            ;;
    esac
done

if [ -n "$lobster" ]; then
    test -f "$PWD/$lobster" || echo "Can't find lobster in $PWD/"
    echo "Making sure lobster is executable..."
    chmod +x "$lobster"
    echo "Please enter your password to create a symlink to lobster-testing-version in /usr/local/bin/"
    sudo ln -sf "$PWD/$lobster" "/usr/local/bin/lobster-testing-version"
    echo "Symlink created!"
else
    if [ -z "$raw_link" ]; then
        raw_link="https://raw.githubusercontent.com/justchokingaround/lobster/dev/lobster.sh"
        branch="dev"
    else
        branch=$(printf "%s" "$raw_link" | sed -E 's/.*\/(.*)\/.*/\1/')
    fi
    echo "Getting lobster-testing-version from the $branch branch..."
    curl -s "$raw_link" >lobster-testing-version || exit 1
    chmod +x lobster-testing-version
    echo "Please enter your password to create a symlink to lobster-testing-version in /usr/local/bin/"
    sudo ln -sf "$PWD/lobster-testing-version" "/usr/local/bin/lobster-testing-version"
    echo "Symlink created!"
fi

echo "DISCLAIMER: If you press enter when prompted for a yes/no answer, the answer will be yes."
press_enter_to_continue
backup "$config_file"
backup "$histfile"
if [ -n "$test_number" ]; then
    execute_test "$test_number"
    ask_for_upload
    exit 0
fi

for i in 1 2 3 4 5 6 7 8; do
    execute_test "$i"
done
ask_for_upload
