# Function for the fish shell that gets the current git branch + if a merge/rebase etc. is in progress (port of GIt's __git_ps1); adapted to work for newer versions of fish (e.g. 2.2.0)

function __git_ps1
  set -l g (git rev-parse --git-dir ^/dev/null)
  if [ -n "$g" ]
    set -l r ""
    set -l b ""

    if [ -d "$g/rebase" ]
      if [ -f "$g/rebase/rebasing" ]
        set r "|REBASE"
      else if [ -f "$g/rebase/applying" ]
        set r "|AM"
      else
        set r "|AM/REBASE"
      end

      set b (git symbolic-ref HEAD ^/dev/null)
    else if [ -f "$g/rebase-merge/interactive" ]
      set r "|REBASE-i"
      set b (cat "$g/rebase-merge/head-name")
    else if [ -d "$g/rebase-merge" ]
      set r "|REBASE-m"
      set b (cat "$g/rebase-merge/head-name")
    else if [ -f "$g/MERGE_HEAD" ]
      set r "|MERGING"
      set b (git symbolic-ref HEAD ^/dev/null)
    else
      if [ -f "$g/BISECT_LOG" ]
        set r "|BISECTING"
      end

      set b (git symbolic-ref HEAD ^/dev/null)
      if [ -z $b ]
        set b (git describe --exact-match HEAD ^/dev/null)
        if [ -z $b ]
          set b (cut -c1-7 "$g/HEAD")
          set b "$b..."
        end
      end
    end

    if not test $argv
        set argv "%s"
    end

    set b (echo $b | sed -e 's|^refs/heads/||')

    printf $argv "$b$r" ^/dev/null
  end
end

function fish_prompt
  printf '%s@%s:[%s](%s)⋊> ' (whoami) (hostname) (prompt_pwd) (__git_ps1)
end
