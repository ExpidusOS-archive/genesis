-- Genesis "mobile" layout
-- Overridable but high priority

genesis:define_misd("80-mobile",
    function()
        if genesis:get_device().device_type == "phone" then
            return { genesis:get_monitors()[1] }
        end
        return {}
    end,
    function(genesis, monitor)
        local desktop = genesis:request_component("genesis-desktop")
        desktop:define_layout_from_file("80-mobile", "desktop.glade")

        local panel = genesis:request_component("genesis-panel")
    end,
    function(genesis, monitor)
    end)