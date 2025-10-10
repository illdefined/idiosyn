{ ... }: { config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    (rust-bin.selectLatestNightlyWith (toolchain: toolchain.default))
  ];

  xdg.configFile."rustfmt/rustfmt.toml".source = (pkgs.formats.toml { }).generate "rustfmt.toml" {
    edition = "2024";

    # indentation
    hard_tabs = true;
    indent_style = "Block";
    imports_indent = "Block";

    # lines
    newline_style = "Unix";
    max_width = 120;
    use_small_heuristics = "Default";

    # brace style
    brace_style = "PreferSameLine";
    control_brace_style = "AlwaysSameLine";

    # spacing
    space_after_colon = true;
    space_before_colon = false;
    spaces_around_ranges = false;
    type_punctuation_density = "Wide";

    # line continuation
    empty_item_single_line = true;
    binop_separator = "Front";
    trailing_comma = "Vertical";

    # condensation
    condense_wildcard_suffixes = true;
    use_try_shorthand = true;

    # imports
    reorder_imports = true;
    group_imports = "StdExternalCrate";
    imports_layout = "Mixed";
    imports_granularity = "Module";

    # functions
    fn_params_layout = "Tall";
    fn_single_line = true;
    where_single_line = true;
    reorder_impl_items = true;

    # literals
    hex_literal_case = "Lower";
    float_literal_trailing_zero = "Always";
  };
}
