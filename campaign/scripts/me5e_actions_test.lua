-- ME5e Actions Test Script
-- Simple test functionality for the actions tab

function testBioticPower()
    local sMessage = "Testing Biotic Power functionality!";
    ChatManager.SystemMessage(sMessage);
    
    -- Update test counter
    updateTestCounter();
end

function testTechPower()
    local sMessage = "Testing Tech Power functionality!";
    ChatManager.SystemMessage(sMessage);
    
    -- Update test counter
    updateTestCounter();
end

function testCombatPower()
    local sMessage = "Testing Combat Power functionality!";
    ChatManager.SystemMessage(sMessage);
    
    -- Update test counter
    updateTestCounter();
end

function updateTestCounter()
    -- Simple counter update for testing
    local nCounter = DB.getValue("charsheet.me5e.test_counter", 0) or 0;
    nCounter = nCounter + 1;
    DB.setValue("charsheet.me5e.test_counter", "number", nCounter);
    
    -- Update the display
    local sCounterText = "Test Counter: " .. nCounter;
    local label = self.test_counter_label;
    if label then
        label.setValue(sCounterText);
    end
end

function onInit()
    -- Initialize test counter if it doesn't exist
    if not DB.getValue("charsheet.me5e.test_counter") then
        DB.setValue("charsheet.me5e.test_counter", "number", 0);
    end
end
