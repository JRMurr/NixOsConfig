{ pkgs, osConfig, ... }:
let
  gcfg = osConfig.myOptions.graphics;
  gitpkg = if gcfg.enable then pkgs.gitFull else pkgs.git;
in
{
  programs.git = {
    enable = true;
    package = gitpkg;
    signing = {
      key = "~/.ssh/id_ed25519";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "John Murray";
        email = "5672686+JRMurr@users.noreply.github.com";
      };
      alias = {
        a = "add";
        ai = "add -i";
        c = "commit";
        ca = "commit --amend";
        can = "commit --amend --no-edit";
        co = "checkout";
        cob = "checkout -b";
        d = "difftool --dir-diff";
        r = "rebase";
        ri = "rebase -i";
        s = "status";
        undo = "reset HEAD~";
        yoink = "pull";
        yeet = "push";
        gh = "!open $(fish -c git_repo_url)";
        lb = "!git reflog show --pretty=format:'%gs ~ %gd' --date=relative | grep 'checkout:' | grep -oE '[^ ]+ ~ .*' | awk -F~ '!seen[$1]++' | head -n 10 | awk -F' ~ HEAD@{' '{printf(\"  \\033[33m%s: \\033[37m %s\\033[0m\\n\", substr($2, 1, length($2)-1), $1)}'";
        tmp = "!git add -A && git commit --no-verify -m 'tmp'";
        scary = "!git fetch && git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)";
        forget = "update-index --skip-worktree";
        remember = "update-index --no-skip-worktree";
        destroy = "!git push -d origin $@ && git branch -d";
        gone = "!git remote prune origin; git branch --merged | grep -Ev \\\"(\\\\*|master)\\\" | xargs git branch -d";
        l = "log --first-parent --oneline --decorate";
        lo = "log --first-parent --format=\"%C(yellow bold)%h %C(blue)%an %C(reset)%s\"";
        lg = "log --oneline --decorate --graph --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)'";
        # Rebase workflow https://softwaredoug.com/blog/2022/11/09/idiot-proof-git-aliases.html
        mainbranch = "!git remote show origin | sed -n '/HEAD branch/s/.*: //p'";
        synced = "!git pull origin $(git mainbranch) --rebase";
        update = "!git pull origin $(git rev-parse --abbrev-ref HEAD) --rebase";
        squash = "!git rebase -v -i $(git mainbranch)";
        publish = "push origin HEAD --force-with-lease";
        pub = "publish";
        com = "!git checkout $(git mainbranch)";
        rbm = "!git fetch origin && git rebase origin/$(git mainbranch)";
        mm = "!git fetch origin && git merge origin/$(git mainbranch)";
      };
      gpg.format = "ssh";
      core.editor = "code --wait";
      pager.branch = false;
      pull.ff = "only";
      push.autoSetupRemote = true;
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
    };
  };

  programs.lazygit = {
    enable = true;
  };

  # programs.gpg = {
  #   enable = true;
  #   mutableTrust = false;
  #   mutableKeys = false;
  # };

  # services.gpg-agent = { enable = true; };
}
