-- Layer rules for the shell surfaces (Quickshell, rofi).
-- Namespaces: "rice-bar" (bar + its dropdowns), "rice-notifications" (popups), "rice-sky"
-- (wallpaper), "rice-screensaver" (idle overlay), "rofi".

-- Frosted glass behind the Orbit Glass bar and its dropdown panels. ignore_alpha keeps blur
-- off the fully transparent parts of the bar window (between pills).
hl.layer_rule({ name = "bar-blur", match = { namespace = "^rice-bar$" },
                blur = true, blur_popups = true, ignore_alpha = 0.1 })

-- rofi's surface covers the whole output; ignore_alpha limits blur to the panel itself.
hl.layer_rule({ name = "rofi-blur", match = { namespace = "^rofi$" },
                blur = true, ignore_alpha = 0.1, animation = "popin 92%" })

-- The sky redraws a few times a second while animating; never animate or blur the layer.
hl.layer_rule({ name = "sky-static", match = { namespace = "^rice-sky$" }, no_anim = true })

-- Notification popups: the same frosted glass as the bar.
hl.layer_rule({ name = "notifications-blur", match = { namespace = "^rice-notifications$" },
                blur = true, ignore_alpha = 0.1, animation = "slide right" })

-- Screensaver: fade in over the desktop; opaque, so no blur.
hl.layer_rule({ name = "screensaver-fade", match = { namespace = "^rice-screensaver$" }, animation = "fade" })
