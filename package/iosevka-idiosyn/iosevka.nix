{
  serifs = "sans";
  noCvSs = true;
  exportGlyphNames = true;
  buildTextureFeature = true;

  variants.design = {
    one = "no-base";
    two = "curly-neck-serifless";
    three = "two-arcs";
    four = "closed-non-crossing-serifless";
    five = "oblique-flat-serifless";
    six = "closed-contour";
    seven = "bend-serifless";
    eight = "two-circles";
    nine = "closed-contour";
    zero = "dotted";
    capital-a = "round-top-serifless";
    capital-b = "standard-serifless";
    capital-c = "serifless";
    capital-d = "standard-serifless";
    capital-e = "serifless";
    capital-f = "serifless";
    capital-g = "toothless-corner-serifless-hooked";
    capital-h = "serifless";
    capital-i = "short-serifed";
    capital-j = "flat-hook-serifless";
    capital-k = "curly-serifless";
    capital-l = "serifless";
    capital-m = "slanted-sides-hanging-serifless";
    capital-n = "standard-serifless";
    capital-p = "closed-serifless";
    capital-q = "crossing";
    capital-r = "curly-serifless";
    capital-s = "serifless";
    capital-t = "serifless";
    capital-u = "toothless-rounded-serifless";
    capital-v = "curly-serifless";
    capital-w = "curly-serifless";
    capital-x = "curly-serifless";
    capital-y = "curly-serifless";
    capital-z = "curly-serifless";
    a = "single-storey-earless-corner-tailed";
    b = "toothless-corner-serifless";
    c = "serifless";
    d = "toothless-corner-serifless";
    e = "flat-crossbar";
    f = "flat-hook-serifless";
    g = "single-storey-flat-hook-earless-corner";
    h = "straight-serifless";
    i = "serifed-flat-tailed";
    j = "flat-hook-serifed";
    k = "curly-serifless";
    l = "serifed-flat-tailed";
    m = "earless-corner-double-arch-serifless";
    n = "earless-corner-straight-serifless";
    p = "earless-corner-serifless";
    q = "earless-corner-straight-serifless";
    r = "earless-corner-serifless";
    s = "serifless";
    t = "flat-hook-asymmetric-short-neck";
    u = "toothless-corner-serifless";
    v = "curly-serifless";
    w = "curly-serifless";
    x = "curly-serifless";
    y = "curly-turn-serifless";
    z = "curly-serifless";
    capital-eszet = "flat-top-serifless";
    long-s = "flat-hook-tailed";
    eszet = "sulzbacher-serifless";
    lower-eth = "curly-bar";
    capital-thorn = "serifless";
    lower-thorn = "serifless";
    lower-alpha = "crossing";
    lower-beta = "standard";
    capital-gamma = "serifless";
    lower-gamma = "casual";
    capital-delta = "curly";
    lower-delta = "rounded";
    lower-iota = "serifed-semi-tailed";
    capital-lambda = "curly-serifless";
    lower-lambda = "curly";
    lower-mu = "toothless-corner-serifless";
    lower-nu = "casual";
    lower-xi = "rounded";
    lower-pi = "tailed";
    lower-tau = "flat-tailed";
    lower-upsilon = "casual-serifless";
    lower-phi = "cursive";
    lower-chi = "curly-serifless";
    lower-psi = "flat-top-serifless";
    cyrl-a = "single-storey-earless-rounded-serifless";
    cyrl-ve = "standard-serifless";
    cyrl-capital-zhe = "symmetric-connected";
    cyrl-zhe = "symmetric-connected";
    cyrl-capital-ze = "serifless";
    cyrl-ze = "serifless";
    cyrl-capital-ka = "curly-serifless";
    cyrl-ka = "curly-serifless";
    cyrl-el = "straight";
    cyrl-em = "flat-bottom-serifless";
    cyrl-capital-en = "serifless";
    cyrl-en = "serifless";
    cyrl-capital-er = "closed-serifless";
    cyrl-er = "earless-rounded-serifless";
    cyrl-capital-u = "curly-serifless";
    cyrl-u = "curly-serifless";
    cyrl-ef = "serifless";
    cyrl-che = "standard";
    cyrl-yeri = "round";
    cyrl-yery = "round-tailed";
    cyrl-capital-e = "serifless";
    cyrl-e = "serifless";
    cyrl-capital-ya = "curly-serifless";
    cyrl-ya = "standing-serifless";
    tittle = "round";
    diacritic-dot = "round";
    punctuation-dot = "round";
    braille-dot = "round";
    tilde = "low";
    asterisk = "penta-low";
    underscore = "high";
    caret = "low";
    ascii-grave = "straight";
    ascii-single-quote = "straight";
    paren = "flat-arc";
    brace = "straight";
    guillemet = "straight";
    number-sign = "upright";
    ampersand = "closed";
    at = "compact";
    dollar = "through";
    cent = "through";
    percent = "rings-continuous-slash";
    bar = "natural-slope";
    question = "smooth";
    pilcrow = "high";
    partial-derivative = "curly-bar";
    micro-sign = "toothless-corner-serifless";
    lig-ltgteq = "flat";
    lig-neq = "slightly-slanted";
    lig-equal-chain = "with-notch";
    lig-hyphen-chain = "with-notch";
    lig-plus-chain = "with-notch";
    lig-double-arrow-bar = "with-notch";
    lig-single-arrow-bar = "with-notch";
  };

  variants.italic = {
    e = "rounded";
    f = "flat-hook-tailed";
  };

  ligations = {
    inherits = "dlig";
    disables = [
      "brace-bar"
      "brack-bar"
    ];
  };

  widths = {
    Condensed = {
      shape = 500;
      menu = 3;
      css = "condensed";
    };

    Normal = {
      shape = 600;
      menu = 5;
      css = "normal";
    };
  };
}
