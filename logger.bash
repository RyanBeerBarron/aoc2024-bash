# Logger library in bash
# Makes a copy of stdout to keep logging even with command/process substitution and other redirections.
#
# Provides log_<level> function for each log type
# and LOG_<LEVEL> constants to define the logging level
#
# `LOG_LEVEL` is a mutable global variable to communicate LOG_LEVEL
#
# Usage:
# ```
# source logger.bash
# LOG_LEVEL="$LOG_WARN"
#
# log_info "foo bar" # Nothing logged
# log_warn "foo bar" # This is logged
# ```

exec {log_output}>&1

LOG_OFF=-1
LOG_FATAL=0
LOG_ERROR=1
LOG_WARN=2
LOG_INFO=3
LOG_DEBUG=4
LOG_TRACE=5
function __log ()
{
	local required_level="$1" color="$2" level_label="$3"
	local pid_label
	shift 3
	if (( LOG_LEVEL >= required_level)); then
		datetime=$(date "+%FT%T")

		if test -n "$pid";
			then pid_label="pid:$pid";
			else pid_label="main"
		fi
		printf '%b%-7s %-21s %-8s %s%b\n' "$color" "[$level_label]" "[$datetime]" "[$pid_label]" "$*" "\033[0m" >&"$log_output"
	fi
}

function log_fatal ()
{
	__log 0 "\033[31m" "FATAL" "$@"
	exit 1
}
function log_error ()
{
	__log 1 "\033[31m" "ERROR" "$@"

}
function log_warn ()
{
	__log 2 "\033[33m" "WARN" "$@"

}
function log_info ()
{
	__log 3 "\033[34m" "INFO" "$@"
}

function log_debug ()
{
	__log 4 "\033[32m" "DEBUG" "$@"
}

function log_trace ()
{
	__log 5 "\033[35m" "TRACE" "$@"
}
