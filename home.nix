{ config, lib, pkgs, ... }:

with import <nixpkgs> { };
with builtins;
with lib;
with lib.strings;
with lib.filesystem;

let
  nixpkgs-tars = "https://github.com/NixOS/nixpkgs/archive/";
  unstable = import (fetchTarball
    "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz");
  filesDir = (toPath ./files); # Shorthand variable to easily access files
  link = config.lib.file.mkOutOfStoreSymlink;
in rec {

  # Sorry not sorry Stallman
  nixpkgs.config = {
    allowUnfree = true;
    # Needed for an issue on darwin
    packageOverrides = pkgs: {
      pr158737 = import (fetchTarball
        "${nixpkgs-tars}60b5f837cac1c5a7f3fac221bf50191bbfac01f6.tar.gz") {
          config = config.nixpkgs.config;
        };
    };
  };

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = getEnv "USER";
  home.homeDirectory = getEnv "HOME";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Setup fonts
  fonts.fontconfig.enable = true;

  # List of packages for the user
  home.packages = with pkgs;
    [
      (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
      asciinema
      bat
      black
      cachix
      cargo
      cask
      clippy
      cmake
      comma
      coreutils
      curl
      delta
      emacs-all-the-icons-fonts
      exa
      exercism
      fasd
      fd
      gh
      git
      gnupg
      graphviz
      isync
      jq
      keychain
      kotlin-language-server
      lazydocker
      lazygit
      msmtp
      (nerdfonts.override { fonts = [ "Iosevka" ]; })
      nodePackages.bash-language-server
      nodePackages.vscode-json-languageserver
      nodePackages.typescript-language-server
      nodePackages.vls
      niv
      nixfmt
      nodejs
      overpass
      pandoc
      p7zip
      python
      (ripgrep.override { withPCRE2 = true; })
      rnix-lsp
      rust-analyzer
      rustc
      rustfmt
      sbcl
      shellcheck
      spicetify-cli
      sqlite
      stylua
      unrar
      unzip
      wget
      xsel
      yarn
      yaml-language-server
      yq
    ] ++ optionals stdenv.isDarwin [
      cocoapods
      git-lfs
      jdk17_headless
      maven
      m-cli
      php80Packages.phpcbf
      php80Packages.composer
      pr158737.mysql80
      terminal-notifier
    ] ++ optionals stdenv.isLinux [
      arandr
      dmenu
      docker
      dunst
      firefox
      libnotify
      lutris
      mangohud
      networkmanagerapplet
      nitrogen
      picom
      ranger
      siji
      tectonic
    ];

  # Enable XDG directories
  xdg = {
    enable = true;

    configHome = "${home.homeDirectory}/.config";
    dataHome = "${home.homeDirectory}/.local/share";
    cacheHome = "${home.homeDirectory}/.cache";
  };

  # Automatically run config for a directory/project
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.direnv.enable
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # Better cat
  programs.bat = {
    enable = true;
    config = { theme = "Nord"; };
  };

  # Handle GPG/SSH keys across different sessions
  programs.keychain = {
    enable = true;
    enableZshIntegration = true;
    # Load every key in .ssh
    keys = map (s: baseNameOf (replaceStrings [ ".pub" ] [ "" ] (toString s)))
      (filter (s: hasSuffix "pub" s) (listFilesRecursive ~/.ssh));
  };

  # Configure LS_COLORS
  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = (readFile "${filesDir}/.dir_colors");
  };

  # Basic git config
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "Ellis Kenyő";
    userEmail =
      if stdenv.isDarwin then "ellis@coreblue.co.uk" else "me@elken.dev";
    signing.signByDefault = false;
    signing.key =
      if stdenv.isDarwin then "394969D41ABB2A3F" else "298BE5D997EBAA02";
    # Delta is /kinda/ nice
    delta = {
      enable = true;
      options = {
        syntax-theme = "Nord";
        line-numbers = true;
        side-by-side = true;
      };
    };
    aliases = {
      co = "checkout";
      cl = "clone";
      br = "branch";
    };
    extraConfig = {
      "diff \"org\"".xfuncname = "^(\\*+ +.*)$";
      init.defaultBranch = "master";
      init.templatedir = "${xdg.configHome}/git/templates";
      github.user = "elken";
    };
  };

  # Zuper Shell Hacker
  programs.zsh = rec {
    enable = true;
    autocd = true;
    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;

    shellAliases = rec {
      cat = "bat";
      ls = "exa --git --icons";
      ll = "${shellAliases.ls} -l";
      la = "${shellAliases.ls} -al";
      make = "make -j `expr $(nproc) + 1` -l$(nproc)";
      c = "clear";
      q = "exit";
      diff = "diff -rupN";
      pbc = "pbcopy";
      pbp = "pbpaste";
      _ = "sudo";
      http-serve = "python -m http.server";

      # Git aliases
      g = "git";
      gwd = "git diff --no-ext-diff";
      gwr = "git reset --soft";
      gws = "git status --short";

      # Nix aliases
      hsw = "home-manager switch";

      # TODO: Remove me after https://github.com/NixOS/nixpkgs/pull/173468 is revoled
      cask =
        "EMACS=/nix/store/syydi42dblldm6djjrixw18k8k29qanw-emacs-28.1/bin/emacs ${pkgs.cask}/bin/cask";
      spicetify = "spicetify-cli";
      art = "artisan";
      sail = "./vendor/bin/sail";
    } // (if stdenv.isDarwin then {
      hsw = "darwin-rebuild switch";
    } else {
      pbcopy = "xsel --clipboard --input";
      pbpaste = "xsel --clipboard --output";
    });

    history = {
      size = 50000;
      save = 500000;
      # Put the ZSH history into the same directory as the configuration.
      # Also, the path must be absolute, relative paths just make new directories
      # wherever you're working from.
      path = let inherit (config.home) homeDirectory;
      in "${homeDirectory}/${dotDir}/history";
      extended = true;
      ignoreDups = true;
      share = true;
    };

    sessionVariables = rec {
      LANG = "en_GB.UTF-8";
      LC_ALL = "en_GB.UTF-8";

      NVIM_TUI_ENABLE_TRUE_COLOR = 1;

      BROWSER = if stdenv.isDarwin then "open" else "xdg-open";

      # use the same nixpkgs for the rest of the system as we use here
      NIX_PATH =
        "$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels\${NIX_PATH:+:$NIX_PATH}";

      EDITOR = "e";
      VISUAL = "v";
      PAGER = "less";
      GIT_EDITOR = EDITOR;

      XDG_CONFIG_HOME = xdg.configHome;
      XDG_CACHE_HOME = xdg.cacheHome;
      XDG_DATA_HOME = xdg.dataHome;

      PATH = concatStringsSep ":" ([
        "${pkgs.jdk17}/bin"
        "$HOME/bin"
        "/usr/local/share/dotnet"
        "$HOME/.composer/vendor/bin"
        "$HOME/.emacs.doom/bin"
        "$HOME/.emacs.d/bin"
        "$HOME/.config/emacs/bin"
        "$HOME/.cargo/bin"
        "$HOME/.local/bin"
        "$HOME/.config/yarn/global/node_modules/.bin"
        "$HOME/.dwm/bin"
        "$HOME/.dotnet/tools"
        "$HOME/spicetify-cli"
        "$HOME/.spicetify"
        "$HOME/.luarocks/bin"
        "$HOME/.config/chemacs/doom/bin"
      ] ++ optionals pkgs.stdenv.isDarwin [
        "/opt/homebrew/bin"
        "$HOME/Library/Android/sdk/platform-tools"
        "$HOME/Library/Android/sdk/build-tools"
        "$HOME/Library/Android/sdk/cmdline-tools/latest/bin"
        "$HOME/.pub-cache/bin"
      ] ++ [ "$PATH" ]);

      TERM = "xterm-256color";

      LESS = "-F -g -i -M -R -S -w -X -z-4";

      ZSH_AUTOSUGGEST_USE_ASYNC = 1;

      PULSE_LATENCY_MSEC = 120;

      JAVA_HOME = pkgs.jdk17;
    } // (if stdenv.isDarwin then {
      ANDROID_HOME = "~/Library/Android/sdk";
    } else
      { });

    initExtraFirst = ''
      typeset -gU cdpath fpath mailpath path
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      # Initialization code that may require console input (password prompts, [y/n]
      # confirmations, etc.) must go above this block, everything else may go below.
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Completion settings
      source ${config.xdg.configHome}/zsh/completion.zsh
      fpath=(${config.xdg.configHome}/zsh/plugins/zsh-completions/src \
             ${config.xdg.configHome}/zsh/vendor-completions \
             ${config.xdg.configHome}/zsh/plugins/mac-zsh-completions/completions \
             $fpath)
      export GPG_TTY=$(tty)
      export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

      function mkdcd() {
        mkdir -p $1 && cd $1
      }
    '';

    initExtra = ''
      # Nix setup (environment variables, etc.)
      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
        . ~/.nix-profile/etc/profile.d/nix.sh
      fi

      if [ "$INSIDE_EMACS" = 'vterm' ]; then
        . ${config.xdg.configHome}/zsh/vterm.zsh
      fi

      # PHP Artisan helper
      . ${config.xdg.configHome}/zsh/artisan.zsh

      # Notifier for done/failed commands
      . ${config.xdg.configHome}/zsh/notifyosd.zsh

      # Powerlevel10k config
      . ${config.xdg.configHome}/zsh/p10k.zsh


      # Bindings
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      bindkey -M emacs '\e[1;5D' backward-word
      bindkey -M emacs '\e[1;5C' forward-word
      bindkey -M emacs '\e[3~' delete-char
      bindkey -M emacs "^P" history-substring-search-up
      bindkey -M emacs "^N" history-substring-search-down

      export XDG_DATA_DIRS=$HOME/.nix-profile/share:$XDG_DATA_DIRS
    '' + (if pkgs.stdenv.isDarwin then ''
      # Include iterm2 shell integrations
      if [ -e $HOME/.iterm2_shell_integration.zsh ]; then
        . $HOME/.iterm2_shell_integration.zsh
      fi
    '' else
      "");

    plugins = with pkgs;
      [
        {
          name = "zsh-syntax-highlighting";
          src = fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-syntax-highlighting";
            rev = "0.6.0";
            sha256 = "hH4qrpSotxNB7zIT3u7qcog51yTQr5j5Lblq9ZsxuH4=";
          };
          file = "zsh-syntax-highlighting.zsh";
        }
        {
          name = "zsh-abbrev-alias";
          src = fetchFromGitHub {
            owner = "momo-lab";
            repo = "zsh-abbrev-alias";
            rev = "637f0b2dda6d392bf710190ee472a48a20766c07";
            sha256 = "8xC4DdMMuN7WOyO5eB/bL9QdwYu9OYmYJ8Pcy6tVSps=";
          };
          file = "abbrev-alias.plugin.zsh";
        }
        {
          name = "zsh-autopair";
          src = fetchFromGitHub {
            owner = "hlissner";
            repo = "zsh-autopair";
            rev = "34a8bca0c18fcf3ab1561caef9790abffc1d3d49";
            sha256 = "wd/6x2p5QOSFqWYgQ1BTYBUGNR06Pr2viGjV/JqoG8A=";
          };
          file = "autopair.zsh";
        }
        {
          name = "powerlevel10k";
          src = fetchFromGitHub {
            owner = "romkatv";
            repo = "powerlevel10k";
            rev = "f07d7baea36010bfa74708844d404517ea6ac473";
            sha256 = "5WeEu2VKpOxRtQEeP2DAH1nDi0158No4tlmEXs8gCAg=";
          };
          file = "powerlevel10k.zsh-theme";
        }
        {
          name = "zsh-history-substring-search";
          src = fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-history-substring-search";
            rev = "4abed97";
            sha256 = "8kiPBtgsjRDqLWt0xGJ6vBBLqCWEIyFpYfd+s1prHWk=";
          };
          file = "zsh-history-substring-search.zsh";
        }
        {
          name = "zsh-autosuggestions";
          src = fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-autosuggestions";
            rev = "a411ef3";
            sha256 = "KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
          };
          file = "zsh-autosuggestions.zsh";
        }
        {
          name = "zsh-completions";
          src = fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-completions";
            rev = "55d07cc";
            sha256 = "Rp4yXJoAGUq6GfcvOMCKWzxRMjLMBfmTBJkfVsq8P1w=";
          };
        }
      ] ++ optionals stdenv.isDarwin [{
        name = "mac-zsh-completions";
        src = fetchFromGitHub {
          owner = "scriptingosx";
          repo = "mac-zsh-completions";
          rev = "303f25c";
          sha256 = "06mEWuZsfTLNKodqHGTxiakZf0MvWsvoSvnt2IW/Nkk=";
        };
      }];
  };

  # The best IDE in the world, just lacks a good text editor
  # programs.emacs = {
  #   enable = stdenv.isLinux;
  #   package = (pkgs.emacsNativeComp.override { withXwidgets = true; });
  #   extraPackages = epkgs: with epkgs; [ vterm emacsql-sqlite pdf-tools ];
  # };

  # Mostly Linux things below

  # Extra files
  home.file = {
    "bin/e".source = "${filesDir}/bin/e";
    "bin/v".source = "${filesDir}/bin/v";
  };

  xdg.configFile = {
    "git/ignore".source = "${filesDir}/git/ignore";
    "chemacs/profiles.el".source = "${filesDir}/.emacs-profiles.el";
    "zsh/vendor-completions".source = with pkgs;
      runCommandNoCC "vendored-zsh-completions" { } ''
        mkdir -p $out
        ${fd}/bin/fd -t f '^_[^.]+$' \
          ${escapeShellArgs home.packages} \
          | xargs -0 -I {} bash -c '${ripgrep}/bin/rg -0l "^#compdef" $@ || :' _ {} \
          | xargs -0 cp -t $out/
      '';

  }
  # Load all plugins in the ZSH folder in files
    // (mapAttrs' (name: file:
      nameValuePair "zsh/${name}" { source = "${filesDir}/zsh/${name}"; })
      (builtins.readDir ./files/zsh)) // (if stdenv.isDarwin then {
        "iterm2/com.googlecode.iterm2.plist".source =
          link "${filesDir}/com.googlecode.iterm2.plist";
      } else
        { });
}
