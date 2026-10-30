-- {{ name }} palette for Hyprland. Usage: local c = require("theme.colors")
-- Values are Hyprland color strings: "rgba(RRGGBBAA)".
return {
    crust    = "{{ crust | rgba }}",
    mantle   = "{{ mantle | rgba }}",
    base     = "{{ base | rgba }}",
    surface0 = "{{ surface0 | rgba }}",
    surface1 = "{{ surface1 | rgba }}",
    surface2 = "{{ surface2 | rgba }}",
    overlay  = "{{ overlay | rgba }}",
    subtext  = "{{ subtext | rgba }}",
    text     = "{{ text | rgba }}",
    bright   = "{{ bright | rgba }}",

    red      = "{{ red | rgba }}",
    orange   = "{{ orange | rgba }}",
    yellow   = "{{ yellow | rgba }}",
    green    = "{{ green | rgba }}",
    cyan     = "{{ cyan | rgba }}",
    blue     = "{{ blue | rgba }}",
    purple   = "{{ purple | rgba }}",
    pink     = "{{ pink | rgba }}",

    shadow   = "{{ crust | rgba:0.6 }}",
}
