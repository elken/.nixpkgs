self: super:
{
  papirus-icon-theme = super.papirus-icon-theme.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ self.curl ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/icons
      mv {,e}Papirus* $out/share/icons
      for theme in $out/share/icons/*; do
        gtk-update-icon-cache $theme
        local color="nordic"
        local size prefix file_path file_name symlink_path
        local -a sizes=(22x22 24x24 32x32 48x48 64x64)
        local -a prefixes=("folder-$color" "user-$color")

        for size in ''${sizes[@]}"; do
          for prefix in ''${prefixes[@]}"; do
            for file_path in "$theme/$size/places/$prefix"{-*,}.svg; do
              [ -f "$file_path" ] || continue  # is a file
              [ -L "$file_path" ] && continue  # is not a symlink

              file_name=''${file_path##*/}"
              symlink_path=''${file_path/-$color/}"  # remove color suffix

              ln -sf "$file_name" "$symlink_path" || {
                fatal "Fail to create '$symlink_path' symlink"
              }
            done
          done
        done
      done
      runHook postInstall
    '';
  });
}
