-- Genesis "desktop" layout
-- Loads after everything else

genesis:define_misd("desktop",
    function()
        return genesis:get_monitors()
    end,
    function(genesis, monitor)
        local desktop = genesis:request_component("genesis-desktop")
        desktop:define_layout("desktop", "<?xml version=\"1.0\" encoding=\"UTF-8\"?><interface><object class=\"GtkButton\" id=\"genesis_desktop\"><property name=\"label\" translatable=\"yes\">button</property><property name=\"use-action-appearance\">False</property><property name=\"visible\">True</property><property name=\"can-focus\">True</property><property name=\"receives-default\">True</property></object></interface>")
    end,
    function(genesis, monitor)
    end)