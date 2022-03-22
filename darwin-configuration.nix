{ config, pkgs, ... }:

{
  imports = [
    <home-manager/nix-darwin> # Import my home-manager setup
    ./pam.nix # Import the sudo Touch ID setup
  ];

  # Nix setup options
  nix = {
    package = pkgs.nix;
    extraOptions = ''
      system = aarch64-darwin
      extra-platforms = aarch64-darwin x86_64-darwin
      experimental-features = nix-command flakes
    '';
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment = {
    loginShell = "${pkgs.zsh}/bin/zsh -l";
    variables = {
      SHELL = "${pkgs.zsh}/bin/zsh";
      LANG = "en_GB.UTF-8";
    };
    systemPackages = [ pkgs.vim ];
  };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Indexing tool and command-not-found helper
  programs.nix-index.enable = true;

  # User setup
  users.users.elken = {
    name = "elken";
    home = "/Users/elken";
    shell = pkgs.zsh;
  };

  # Load home manager and prefer user packages in home-manager
  home-manager.useUserPackages = true;
  home-manager.users.elken = import ./home.nix;

  # Homebrew settings
  homebrew = {
    brewPrefix = "/opt/homebrew/bin";
    enable = true;
    autoUpdate = true;
    cleanup = "zap";

    global = {
      brewfile = true;
      noLock = true;
    };

    taps = [
      "homebrew/core"
      "homebrew/cask"
      "homebrew/cask-versions"
      "d12frosted/emacs-plus"
    ];

    brews = [ "pinentry-mac" "php" "bitwarden-cli" "tectonic" "pdfpc" ];

    casks = [
      "firefox"
      "docker"
      "alfred"
      "flutter"
      "iterm2"
      "rectangle"
      "slack"
      "dash"
      "1password"
      "postman"
      "microsoft-teams"
      "android-studio"
    ];
    extraConfig = ''
      brew "emacs-plus@28", args: ["with-native-comp", "with-xwidgets", "with-modern-doom3-icon", "with-mailutils"], restart_service: :changed
    '';
  };

  # Enable Touch ID for sudo commands
  security.pam.enableSudoTouchIdAuth = true;

  # Settings
  system = {
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    defaults = {
      dock = {
        autohide = true;
        showhidden = true;
        mru-spaces = false;
      };

      finder = {
        AppleShowAllExtensions = true;
        QuitMenuItem = true;
        FXEnableExtensionChangeWarning = false;
      };

      NSGlobalDomain = {
        AppleKeyboardUIMode = 3;
        ApplePressAndHoldEnabled = false;
        _HIHideMenuBar = false;
        InitialKeyRepeat = 20;
        KeyRepeat = 1;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.swipescrolldirection" = false;
      };
    };
  };
}
