--
-- Mass Effect 5e Options
-- Heat handling system options
--

function onInit()
    registerME5eOptions();
end

function registerME5eOptions()
    -- Heat Handling Option
    OptionsManager.registerOptionData({
        sKey = "ME5E_HEAT_HANDLING",
        sGroupRes = "me5e_option_header",
        sNameRes = "me5e_option_heat_handling",
        tCustom = {
            labelsres = "me5e_option_thermal_clips|me5e_option_venting",
            values = "thermal_clips|venting",
            default = "thermal_clips"
        }
    });
end

-- Function to get the current heat handling mode
function getHeatHandlingMode()
    return OptionsManager.getOption("ME5E_HEAT_HANDLING");
end

-- Function to check if thermal clips are enabled
function isThermalClipsEnabled()
    return getHeatHandlingMode() == "thermal_clips";
end

-- Function to check if venting is enabled
function isVentingEnabled()
    return getHeatHandlingMode() == "venting";
end