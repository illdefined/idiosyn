{ ... }: { config, lib, ... }: {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = lib.mkForce "catppuccin_mocha";

      editor = {
        rulers = [ 80 120 ];

        indent-guides = {
          render = true;
          character = "│";
        };

        auto-pairs = {
          "(" = ")";
          "[" = "]";
          "{" = "}";
          "\"" = "\"";
          "'" = "'";
          "`" = "`";
          "“" = "”";
          "‘" = "’";
          "„" = "“";
          "‚" = "‘";
        };

        whitespace = {
          render = {
            nbsp = "all";
            nnbsp = "all";
          };

          characters = {
            nbsp = "␣";
            nnbsp = "⍽";
          };
        };
      };

      keys = {
        normal = {
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
          Z = "replace_with_yanked";

          s = "paste_after";
          S = "paste_before";

          x = "extend_line_below";
          X = "extend_to_line_bounds";
          A-X = "shrink_to_line_bounds";

          e = "change_selection";
          A-e = "change_selection_noyank";

          N = "join_selections";
          A-N = "join_selections_space";

          ";" = "search_next";
          ":" = "search_prev";
        };

        insert = {
          "C-i" = "smart_tab";
          "C-S-i" = "insert_tab";
        };
      };
    };
  };
}
