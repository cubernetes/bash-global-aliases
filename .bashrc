alias make='compiledb make -j '
alias tmux='tmux -2 '
alias v='vim '
alias watch='watch '
alias bat='batcat '
alias cat='bat --decorations=never --paging=never '

alias agent='eval "$(ssh-agent -s)" && ssh-add '
alias dive='docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:latest '
alias jdt='ssh -t jd tmux a '
alias routes='ssh pi-local ip r show default '
alias routes1='ssh pi-local ping -c2 -Ieth1 1.1 | stdbuf -o0 grep --color=never "bytes from" '
alias routes2='ssh pi-local ping -c2 -Ieth2 1.1 | stdbuf -o0 grep --color=never "bytes from" '

alias gs='git status '
alias gp='git add -p '
alias gc='git commit -m '
alias gca='git commit -am '
alias ga='git add '
alias gb='git branch -va '
alias gd='git diff --word-diff=color '
alias gds='git diff --word-diff=color --staged '
alias gl='git log ' # --show-signature'
alias glo='git log --oneline ' # --show-signature'
alias gbc='git rebase --continue '
alias gt='git tree '
alias gsh='git show '
alias gm='git commit --amend '
alias gph='git push github HEAD '
alias gsw='git switch '
alias gswc='git switch -c '

alias G='| grep '
alias J='| jq . '
alias L='| less -SR '
alias C='| column -t -o" | " -s";" '
alias A='| awk '\''{printf $1}'\'' '
alias N='| cat -n '
alias CO='| sort | uniq -c | sort -nr '
alias cl='curl localhot:8080/'

_global_aliases () {
	[[ $COMP_CWORD -lt 0 ]] && { COMPREPLY=($(compgen -a)); return; } # completion on empty line -> show available aliases
	local cword="${COMP_WORDS[COMP_CWORD]}"
	local alias_word alias_expansion

	while IFS=$' =' read -r _ alias_word alias_expansion; do # 3-part structure: `alias foo='bar'`
		eval alias_expansion="$alias_expansion" # get rid of quotes, might not work in complex cases (control chars, newlines, missing quotes, ...)
		if [[ $alias_word == "$cword" ]]; then # linear search. when found -> populate COMPREPLY and return
			COMPREPLY=("$alias_expansion")
			return
		fi
	done < <(alias -p) # don't create while inside subshell!
}

complete -D -F _global_aliases -o nospace -o bashdefault -o default
complete -I -F _global_aliases -o nospace -o bashdefault -o default

declare -A _compfuncmap=() _compcommandmap=() _compoptionsmap=()

_compwrap () {
	_global_aliases "$@"
	if [[ ${#COMPREPLY} -lt 1 ]]; then
		if [[ -n "${_compfuncmap[$1]}" ]]; then
			"${_compfuncmap[$1]}" "$@"
		elif [[ -n "${_compcommandmap[$1]}" ]]; then
			mapfile -t COMPREPLY < <(COMP_LINE=$COMP_LINE COMP_POINT=$COMP_POINT COMP_TYPE=$COMP_TYPE "${_compcommandmap[$1]}" "$@")
		else
			COMPREPLY=($(eval compgen "${_compoptionsmap[$1]}" -- '"$2"'))
		fi
	fi
}

wrap_minus_F_completions () {
	declare -a parts=()
	while read -r -a parts; do
		declare _func=''
		declare -a new_parts=() names=()
		declare -i found_minus_F=0 i=0 option_needs_arg=0

		while [[ ${parts[i]} ]]; do
			case "${parts[i]}" in
				(-*F)
					found_minus_F=1
					;&
				(-*[oAGFWCXPS])
					option_needs_arg=1
					;&
				(-*)
					new_parts+=("${parts[i]}")
					;;
				(*)
					if [[ $option_needs_arg -eq 0 ]]; then
						new_parts+=("${parts[i]}")
						[[ $i -ne 0 ]] && names+=("${parts[i]}")
					elif [[ $found_minus_F -eq 1 ]]; then 
						_func=${parts[i]}
						found_minus_F=0
						new_parts+=(_compwrap)
						option_needs_arg=0
					else
						new_parts+=("${parts[i]}")
						option_needs_arg=0
					fi
					;;
			esac
			i=$((i + 1))
		done
		[[ $option_needs_arg -eq 1 ]] && { echo "Bad command, missing argument to option"; return 1; }

		for name in "${names[@]}"; do
			#shellcheck disable=SC2294
			eval complete -r -- "$name"
			eval "_command=$_command"
			_compfuncmap[$name]=$_func
		done

		#shellcheck disable=SC2294
		eval "${new_parts[@]}"
	done < <(complete | grep -Fv -e ' -F _compwrap' -e ' -D' | grep -F -- ' -F ')
}

wrap_minus_C_completions () {
	declare -a parts=()
	while read -r -a parts; do
		declare _command=''
		declare -a new_parts=() names=()
		declare -i found_minus_C=0 i=0 option_needs_arg=0

		while [[ ${parts[i]} ]]; do
			case "${parts[i]}" in
				(-*C)
					found_minus_C=1
					parts[i]=-F
					;&
				(-*[oAGFWCXPS])
					option_needs_arg=1
					;&
				(-*)
					new_parts+=("${parts[i]}")
					;;
				(*)
					if [[ $option_needs_arg -eq 0 ]]; then
						new_parts+=("${parts[i]}")
						[[ $i -ne 0 ]] && names+=("${parts[i]}")
					elif [[ $found_minus_C -eq 1 ]]; then 
						_command=${parts[i]}
						found_minus_C=0
						new_parts+=(_compwrap)
						option_needs_arg=0
					else
						new_parts+=("${parts[i]}")
						option_needs_arg=0
					fi
					;;
			esac
			i=$((i + 1))
		done
		[[ $option_needs_arg -eq 1 ]] && { echo "Bad command, missing argument to option"; return 1; }

		for name in "${names[@]}"; do
			#shellcheck disable=SC2294
			eval complete -r -- "$name"
			eval "_command=$_command"
			_compcommandmap[$name]=$_command
		done

		#shellcheck disable=SC2294
		eval "${new_parts[@]}"
	done < <(complete | grep -Fv -e ' -F _compwrap' -e ' -D' | grep -F -- ' -C ')
}

wrap_other_completions () {
	declare -a parts=()
	while read -r -a parts; do
		declare -a options=() names=()
		declare -i i=0 option_needs_arg=0

		while [[ ${parts[i]} ]]; do
			case "${parts[i]}" in
				(-*[oAGWXPS])
					option_needs_arg=1
					;&
				(-*)
					options+=("${parts[i]}")
					;;
				(*)
					if [[ $option_needs_arg -eq 0 ]]; then
						[[ $i -ne 0 ]] && names+=("${parts[i]}")
					else
						options+=("${parts[i]}")
						option_needs_arg=0
					fi
					;;
			esac
			i=$((i + 1))
		done
		[[ $option_needs_arg -eq 1 ]] && { echo "Bad command, missing argument to option"; return 1; }

		local OLDIFS=$IFS
		IFS=' '
		for name in "${names[@]}"; do
			#shellcheck disable=SC2294
			eval complete -r -- "$name"
			_compoptionsmap[$name]="${options[*]}"
		done
		IFS=$OLDIFS

		complete -F _compwrap -- "${names[@]}"

	done < <(complete | grep -Fv -e ' -F _compwrap' -e ' -D' -e ' -C' -e ' -F')
}

wrap_minus_F_completions
wrap_minus_C_completions
wrap_other_completions
