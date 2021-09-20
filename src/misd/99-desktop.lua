-- Genesis "desktop" layout
-- Loads after everything else

genesis:define_misd("desktop",
    function()
        return genesis:get_monitors()
    end,
    function(genesis, monitor)
    end,
    function(genesis, monitor)
    end)