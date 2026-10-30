-- Layer rules for the shell surfaces (Quickshell, rofi).
-- Namespaces: "rice-bar" (bar + its dropdowns), "rice-sky" (wallpaper), "rofi".

-- Frosted glass behind the Orbit Glass bar and its dropdown panels. ignore_alpha keeps blur
-- off the fully transparent parts of the bar window (between pills).
hl.layer_rule({ name = "bar-blur", match = { namespace = "^rice-bar$" },
                blur = true, blur_popups = true, ignore_alpha = 0.1 })

-- rofi's surface covers the whole output; ignore_alpha limits blur to the panel itself.
hl.layer_rule({ name = "rofi-blur", match = { namespace = "^rofi$" },
                blur = true, ignore_alpha = 0.1, animation = "popin 92%" })

-- The sky redraws ~10x/s; never animate or blur it.
hl.layer_rule({ name = "sky-static", match = { namespace = "^rice-sky$" }, no_anim = true })
