# Logger library in bash
# Makes a copy of stdout to keep logging even with command/process substitution and other redirections.
#
# Provides log_<level> function for each log type
# and LOG_<LEVEL> constants to define the logging level
#
# `LOG_LEVEL` is a mutable global variable to communicate LOG_LEVEL
# It can be set while invoking the script. Allowing to control logging level without modifying the script.
#
#
# Usage:
# ```
# source logger.bash
# : {LOG_LEVEL;="$LOG_WARN"}
#
# log_info "foo bar" # Nothing logged
# log_warn "foo bar" # This is logged
# ```

exec {log_output}>&1
test -t "${log_output}"
__isatty="$?"
# echo "__isatty=$__isatty"

LOG_OFF=-1
LOG_FATAL=0
LOG_ERROR=1
LOG_WARN=2
LOG_INFO=3
LOG_DEBUG=4
LOG_TRACE=5
# TODO: Add ability to log to stdout and to a file at same time. With and without escape codes
function __log ()
{
	local required_level="$1" color="$2" level_label="$3"
	local core_label source_label footer out
	local funcname=${FUNCNAME[2]} sourcename=${BASH_SOURCE[2]} line=${BASH_LINENO[1]}
	shift 3
	if (( LOG_LEVEL >= required_level)); then
		datetime=$(date "+%FT%T")

		if test -n "${core:-}";
			then printf -v core_label 'core:%2d' "$core";
			else core_label="main"
		fi
		if test "${sourcename:0:1}" = '/' && (( ${#sourcename} > 30 )); then
			shorten_path "$sourcename"
			sourcename="$out"
		fi
		source_label="$sourcename:$funcname:$line"
		if ((__isatty == 0 )); then
			printf -v level_label '%b%b%b%-5s%b' "$BOLD" "$INVERTED" "$color" "$level_label" "$RESET"
			printf -v datetime '%b%b%-19s%b' "$ITALIC" "$color" "$datetime" "$RESET"
			printf -v core_label '%b%b%-7s%b' "$ITALIC" "$color" "$core_label" "$RESET"
			printf -v source_label '%b%s%b' "$UNDERLINE" "$source_label" "$RESET"; printf -v source_label '%b%-40s' "$color" "$source_label"
			footer="$RESET"
		fi
		printf -v headers '%s | %s | %s | %s |' "$level_label" "$datetime" "$core_label" "$source_label"
		printf '%s %b%b\n' "$headers" "$*" "$footer" >&"$log_output"
	fi
}

function log_fatal ()
{
	__log 0 "$RED_FG" "FATAL" "$@"
	exit 1
}
function log_error ()
{
	__log 1 "$RED_FG" "ERROR" "$@"

}
function log_warn ()
{
	__log 2 "$YELLOW_FG" "WARN" "$@"

}
function log_info ()
{
	__log 3 "$BLUE_FG" "INFO" "$@"
}

function log_debug ()
{
	__log 4 "$GREEN_FG" "DEBUG" "$@"
}

function log_trace ()
{
	__log 5 "$MAGENTA_FG" "TRACE" "$@"
}
