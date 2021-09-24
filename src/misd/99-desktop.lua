-- Genesis "desktop" layout
-- Loads after everything else

genesis:define_misd("90-desktop",
    function()
        return genesis:get_monitors()
    end,
    function(genesis, monitor)
        local desktop = genesis:request_component("genesis-desktop")
        desktop:define_layout_from_file("desktop", "desktop.glade")

        local panel = genesis:request_component("genesis-panel")
    end,
    function(genesis, monitor)
    end)