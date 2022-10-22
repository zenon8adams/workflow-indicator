#!/usr/bin/env fish
# name: Github workflow status indicator
# author: Adesina Meekness

function fish_prompt --description 'Write out the prompt'
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l last_command (history | head -1) # Get the last command
    set -l last_pipestatus $pipestatus
    set -l normal  (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status red

# Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix '$'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix '#'
    end

    if not set -q __fish_git_prompt_show_informative_status
        set -g __fish_git_prompt_show_informative_status 1
    end
    if not set -q __fish_git_prompt_hide_untrackedfiles
        set -g __fish_git_prompt_hide_untrackedfiles 1
    end
    if not set -q __fish_git_prompt_color_branch
        set -g __fish_git_prompt_color_branch magenta --bold
    end
    if not set -q __fish_git_prompt_showupstream
        set -g __fish_git_prompt_showupstream informative
    end
    if not set -q __fish_git_prompt_color_dirtystate
        set -g __fish_git_prompt_color_dirtystate blue
    end
    if not set -q __fish_git_prompt_color_stagedstate
        set -g __fish_git_prompt_color_stagedstate yellow
    end
    if not set -q __fish_git_prompt_color_invalidstate
        set -g __fish_git_prompt_color_invalidstate red
    end
    if not set -q __fish_git_prompt_color_untrackedfiles
        set -g __fish_git_prompt_color_untrackedfiles $fish_color_normal
    end
    if not set -q __fish_git_prompt_color_cleanstate
        set -g __fish_git_prompt_color_cleanstate green --bold
    end

#   Write pipestatus
#   If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

#   Detect if we are in a vcs environment
    set -l vcs_prompt (fish_vcs_prompt)
    set github (git config remote.origin.url | grep "github")
    if test -n $github && test -n "$vcs_prompt" # Tags are only supported for GitHub
		git log > /dev/null 2>&1
#		Check to know if there exists any commit in this branch
		if test $status -eq 0
			set head_sha (git rev-parse HEAD)
			set track_file (echo $PREFIX)/tmp/$head_sha/.status
			set diff 0
		    if test -O $track_file
		        set status_info (cat $track_file | head -1)
		        set conclusion (cat $track_file | tail -n +2 | head -1)
				set epoch (cat $track_file | tail -n +3 | head -1)
		        if test -z "$epoch"
		            set epoch 0
		        end
		        test (math (date +%s) - $epoch) -gt 30 # Pool every 30 seconds for changes in status
		        set diff (echo $status)
		    end
#       	query workflow status information
		    test "$conclusion" = "success"
		    set conclusion_is_success (echo $status)
#      		check if last command executed is a git commmand that accesses the online provider
		   echo $last_command | grep -E "git\s*(push|pull|ls-remote|fetch)" > /dev/null
		   set last_command_queries_git (echo $status)
		   if test $last_command_queries_git -eq 0 || test $conclusion_is_success -eq 1 && test $diff -eq 0
		        set token (cat ~/.git-credentials 2>&1 | sed -n -e 's/^.\+:\(.\+\)@.\+$/\1/p')
		        set repo_link (git config remote.origin.url | sed -n -e 's/^.\+\/\(.\+\/.\+\)\.git$/\1/p')
		        set response (curl -s -H "Accept: application/vnd.github+json" \
		                              -H "Authorization: Bearer $token" \
		                              https://api.github.com/repos/$repo_link/actions/runs\?head_sha=$head_sha 2>&1)
				set status_info  (echo $response | grep -Eoh "\"status\s*\":\s*\"([^\"]+)\"" \
		                               		| sed -ne "s/^\s*.\+:\s*\"\(.\+\)\s*\"\$/\1/p")
				set conclusion (echo $response | grep -Eoh "\"conclusion\s*\":\s*\"([^\"]+)\"" \
			                              	   |  sed -ne "s/^\s*.\+:\s*\"\(.\+\)\s*\"\$/\1/p")
#           Write status and epoch back to tracker.
				mkdir -p (echo $PREFIX)/tmp/$head_sha/
		        echo "$status_info"  > $track_file
				echo "$conclusion"  >> $track_file
		        echo (date +%s) >> $track_file
		    end

#           JediTerm emulator does not have a good support for unicode.
            echo $TERMINAL_EMULATOR | grep "JediTerm" > /dev/null
            set is_jediterm (echo $status)
                which luit > /dev/null          # Luit provides better support for non-unicode compliant terminals
            set has_luit    (echo $status)
            set in_progress_indicator "🟤"
            set success_indicator     "🟢"
            set failure_indicator     "🔴"
            set unknown_indicator     "⚫"
            if test $is_jediterm -eq 0
                set in_progress_indicator  (set_color brown)"⏺`$normal"
                set unknown_indicator      (set_color black)"⏺`$normal"
                set success_indicator      (set_color green)"⏺`$normal"
                set failure_indicator      (set_color   red)"⏺`$normal"
            end

#			Update vcs indicator
            if test "$status_info" = "in_progress"
                set vcs_prompt "$vcs_prompt"$in_progress_indicator
            else if test "$status_info" = "completed" && test "$conclusion" = "success"
                set vcs_prompt "$vcs_prompt"$success_indicator
            else if test "$conclusion" = "failure" || test "$conclusion" = "cancelled"
                set vcs_prompt "$vcs_prompt"$failure_indicator
            else
                set vcs_prompt "$vcs_prompt"$unknown_indicator
		    end
		end
    end
    echo -n -s (prompt_login)' ' (set_color $color_cwd) (prompt_pwd) \
                $normal $vcs_prompt $normal $prompt_status $suffix " "
end
