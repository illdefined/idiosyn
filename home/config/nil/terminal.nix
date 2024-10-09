{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  mdless = pkgs.mdcat + /bin/mdless;
  mpv = lib.getExe config.programs.mpv.package;
  xdg-open = pkgs.xdg-utils + /bin/xdg-open;
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  programs.eza.extraOptions = lib.mkAfter [ "--hyperlink" ];

  programs.kitty = {
    enable = true;
    settings = {
      disable_ligatures = "cursor";

      cursor_blink_interval = 0;

      scrollback_lines = 65536;
      scrollback_fill_enlarged_window = true;

      enable_audio_bell = false;

      close_on_child_death = true;

      clear_all_shortcuts = true;

      # Mouse
      click_interval = "0.2";
    };

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+s" = "paste_from_selection";
      "shift+insert" = "paste_from_selection";
      "ctrl+up" = "scroll_line_up";
      "ctrl+down" = "scroll_line_down";
      "ctrl+page_up" = "scroll_page_up";
      "ctrl+page_down" = "scroll_page_down";
      "shift+page_up" = "scroll_page_up";
      "shift+page_down" = "scroll_page_down";
      "ctrl+home" = "scroll_home";
      "ctrl+end" = "scroll_end";
      "ctrl+print_screen" = "show_scrollback";

      "ctrl+equal" = "change_font_size current 0";
      "ctrl+plus" = "change_font_size current +1";
      "ctrl+minus" = "change_font_size current -1";

      "ctrl+shift+u" = "kitten unicode_input";
    };

    extraConfig = let
      mouse = {
        "left click ungrabbed" = "mouse_handle_click selection prompt";
        "ctrl+left click ungrabbed" = "mouse_handle_click link";

        "left press ungrabbed" = "mouse_selection normal";
        "shift+left press ungrabbed" = "mouse_selection line";
        "ctrl+left press ungrabbed" = "mouse_selection rectangle";

        "left doublepress ungrabbed" = "mouse_selection word";
        "left triplepress ungrabbed" = " mouse_selection line";
      } |> lib.mapAttrsToList (n: v: "mouse_map ${n} ${v}\n")
        |> lib.concatStrings;
    in ''
      clear_all_mouse_actions yes
      ${mouse}
    '';
  };

  xdg.configFile."kitty/open-actions.conf".text = ''
    protocol file
    mime image/*
    action launch --type overlay kitten icat --hold -- "$FILE_PATH"

    protocol file
    mime text/markdown
    action launch --type overlay ${mdless} -- "$FILE_PATH"

    protocol file
    mime text/*
    action launch --type overlay $EDITOR -- "$FILE_PATH"

    protocol file
    mime video/*
    action launch --type background ${mpv} -- "$FILE_PATH"

    protocol file
    mime audio/*
    action launch --type overlay ${mpv} -- "$FILE_PATH"

    protocol
    action launch --type background ${xdg-open} "$FILE_PATH"
  '';
}
