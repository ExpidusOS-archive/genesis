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
    end,
    function(genesis, monitor)
    end)