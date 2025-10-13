--
-- Mass Effect 5e Defenses Window Manager
-- Adds a button to open the Character Defenses window
--

function onInit()
    -- Register a handler for when character sheets are opened
    if Session.IsHost then
        DB.addHandler("charsheet.*.features", "onChildAdded", onFeatureAdded);
        DB.addHandler("charsheet.*.features", "onChildDeleted", onFeatureChanged);
        DB.addHandler("charsheet.*.features", "onChildUpdate", onFeatureChanged);
    end
end

function onClose()
    if Session.IsHost then
        DB.removeHandler("charsheet.*.features", "onChildAdded", onFeatureAdded);
        DB.removeHandler("charsheet.*.features", "onChildDeleted", onFeatureChanged);
        DB.removeHandler("charsheet.*.features", "onChildUpdate", onFeatureChanged);
    end
end

function onFeatureAdded(nodeFeature)
    onFeatureChanged(nodeFeature);
end

function onFeatureChanged(nodeFeature)
    -- Check if this feature is one we care about
    local sFeatureName = DB.getValue(nodeFeature, "name", "");
    if sFeatureName == "Barrier" or sFeatureName == "Tech Armor" or sFeatureName == "Tactical Cloak" then
        -- Find the character sheet and add/update the defenses button
        local nodeChar = nodeFeature.getParent().getParent();
        addDefensesButton(nodeChar);
    end
end

function addDefensesButton(nodeChar)
    if not nodeChar then
        return;
    end
    
    -- Get the character sheet window
    local sCharID = DB.getPath(nodeChar);
    local wCharSheet = Interface.findWindow("charsheet", sCharID);
    
    if wCharSheet then
        -- Check if we already have a defenses button
        if not wCharSheet.defenses_button then
            -- Create the button (we'll need to add this to the character sheet XML)
            -- For now, we'll create a simple way to open the window
            addDefensesButtonToSheet(wCharSheet);
        end
    end
end

function addDefensesButtonToSheet(wCharSheet)
    -- This is a placeholder - we'll need to modify the character sheet XML
    -- to include a button that calls openDefensesWindow
end

function openDefensesWindow(nodeChar)
    -- Open the Character Defenses window
    if not nodeChar then
        return;
    end
    
    local sCharID = DB.getPath(nodeChar);
    local wDefenses = Interface.openWindow("charsheet_defenses", sCharID);
    
    if wDefenses then
        wDefenses.bringToFront();
    end
end

-- Global function to be called from character sheet
function ME5eDefensesOpen(nodeChar)
    openDefensesWindow(nodeChar);
end
