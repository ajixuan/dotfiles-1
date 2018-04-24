#!/usr/bin/env bash

set -e
set -o pipefail
set -u

run_script_test() {
    local test_script="${1:-}"
    if [ "${test_script}" = '' ]; then
        printf '%s: error: missing test script\n' "${0}" >&2
        return 1
    fi

    log_and_run "${test_script}"
    return 0
}

run_vim_test() {
    local need_vimrc=false
    local test_script=
    for arg in "${@}"; do
        case "${arg}" in
            --need-vimrc)
                need_vimrc=true
                ;;
            *)
                if [ "${test_script}" = '' ]; then
                    test_script="${arg}"
                else
                    printf '%s: error: unrecognized argument: %s\n' "${0}" "${arg}" >&2
                    return 1
                fi
                ;;
        esac
    done
    if [ "${test_script}" = '' ]; then
        printf '%s: error: missing test script\n' "${0}" >&2
        return 1
    fi

    local log_file_path="$(mktemp /tmp/vim-test-sh.XXXXXX)"
    local script_args=(
        # Fix some situations where the UI could hang waiting for user input.
        -c 'set nomore'
        -S "${test_script}"
    )
    if ! "${need_vimrc}"; then
        run_vim_with_log_file "${log_file_path}" -N -u NONE "${script_args[@]}"
    fi
    run_vim_with_log_file "${log_file_path}" "${script_args[@]}"
    return 0
}

run_vim_with_log_file() {
    local log_file_path="${1}"
    shift
    local vim_args=("${@}")

    # Clear the log file.
    printf '' >"${log_file_path}"

    # Log test output to a file. Also, tell the test framework to :cqall! on
    # failure.
    # TODO(strager): Escape the log file properly.
    vim_args+=(--cmd "set verbosefile=${log_file_path}")

    local vim_status=0
    log_and_run vim "${vim_args[@]}" || vim_status="${?}"

    cat "${log_file_path}" >&2
    printf '\n' >&2

    return "${vim_status}"
}

log_and_run() {
    local command=("${@}")
    (
        printf '$'
        printf ' %q' "${command[@]}"
        printf '\n'
    ) >&2
    if "${command[@]}"; then
        :
    else
        local status="${?}"
        printf '%s: error: command failed with status %d\n' "${0}" "${status}" >&2
        return "${status}"
    fi
    return 0
}

run_script_test vim/vim/autoload/strager/test_flow_jq.sh
run_vim_test --need-vimrc vim/vim/autoload/strager/test_flow.vim
run_vim_test --need-vimrc vim/vim/autoload/strager/test_tag.vim
run_vim_test --need-vimrc vim/vim/test/test_c_make_ninja.vim
run_vim_test --need-vimrc vim/vim/test/test_color_column.vim
run_vim_test --need-vimrc vim/vim/test/test_format.vim
run_vim_test vim/vim/autoload/strager/test_buffer.vim
run_vim_test vim/vim/autoload/strager/test_exception.vim
run_vim_test vim/vim/autoload/strager/test_file.vim
run_vim_test vim/vim/autoload/strager/test_function.vim
run_vim_test vim/vim/autoload/strager/test_list.vim
run_vim_test vim/vim/autoload/strager/test_messages.vim
run_vim_test vim/vim/autoload/strager/test_move_file.vim
run_vim_test vim/vim/autoload/strager/test_path.vim
run_vim_test vim/vim/autoload/strager/test_project.vim
run_vim_test vim/vim/autoload/strager/test_vim.vim
run_vim_test vim/vim/test/test_js_make_flow.vim
printf 'All tests passed!\n' >&2
