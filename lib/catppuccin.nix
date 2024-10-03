{ catppuccin-palette, ... }:

catppuccin-palette + /palette.json
|> builtins.readFile
|> builtins.fromJSON
