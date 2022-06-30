;;; Directory Local Variables
;;; For more information see (info "(emacs) Directory Variables")

((nix-mode . ((compile-command . "if [[ $(uname -s) == 'Darwin' ]]; then darwin-rebuild switch; else home-manager switch; fi"))))
