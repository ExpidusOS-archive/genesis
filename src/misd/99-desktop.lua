-- Genesis "desktop" layout
-- Loads after everything else

genesis:define_misd("99-desktop",
    function(genesis)
        return genesis:get_monitors()
    end,
    function(genesis, monitor)
        local desktop = genesis:request_component("genesis-desktop")
        desktop:export_objects("genesis_desktop")
        desktop:define_layout_from_file("desktop.glade")

        local desktop = genesis:request_component("genesis-panel")
        desktop:export_objects("genesis_panel", "genesis_dock")
        desktop:define_layout_from_file("panel.glade")
    end,
    function(genesis, monitor)
    end)