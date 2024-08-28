{ ... }: { config, lib, ... }: {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      editor.auto-pairs = {
        "“" = "”";
        "‘" = "’";
        "„" = "“";
        "‚" = "‘";
      };

      editor.whitespace.render = {
        nbsp = "all";
        nnbsp = "all";
        tab = "all";
      };

      editor.whitespace.characters = {
        nbsp = "␣";
        nnbsp = "⍽";
        tab = "»";
        tabpad = "·";
      };

      keys.normal = {
        minus = "command_mode";

        r = "move_char_left";
        n = "move_visual_line_down";
        t = "move_visual_line_up";
        h = "move_char_right";

        p = "move_prev_word_start";
        w = "move_next_word_start";
        l = "move_next_word_end";
        P = "move_prev_long_word_start";
        W = "move_next_long_word_start";
        L = "move_next_long_word_end";

        z = "replace";
        Z = "zeplace_with_yanked";

        s = "paste_after";
        S = "paste_before";

        x = "extend_line_below";
        X = "extend_to_line_bounds";
        Alt-X = "shrink_to_link_bounds";

        e = "change_selection";
        Alt-e = "change_selection_noyank";

        N = "join_selections";
        Alt-N = "join_selections_space";

        semicolon = "search_next";
        colon = "search_prev";
      };
    };
  };
}
