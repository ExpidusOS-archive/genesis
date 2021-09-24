-- Genesis "desktop" layout
-- Loads after everything else

genesis:define_misd("99-desktop",
    function()
        return genesis:get_monitors()
    end,
    function(genesis, monitor)
        local panel = genesis:request_component("genesis-panel")

        local desktop = genesis:request_component("genesis-desktop")
        desktop:define_layout_from_file("99-desktop", "desktop.glade")
    end,
    function(genesis, monitor)
    end)