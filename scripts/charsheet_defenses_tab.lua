--
-- Character Sheet Defenses Tab
-- Handles Barrier and Tech Armor activation
--

-- Global function declarations
onBarrierActivate = nil;
activateBarrierFromXML = nil;

-- Barrier uses by class and level (resets on long rest)
local BARRIER_USES_BY_CLASS = {
    ["Vanguard"] = {
        [1] = 2,
        [2] = 2,
        [3] = 3,
        [4] = 3,
        [5] = 3,
        [6] = 4,
        [7] = 4,
        [8] = 4,
        [9] = 4,
        [10] = 4,
        [11] = 4,
        [12] = 5,
        [13] = 5,
        [14] = 5,
        [15] = 5,
        [16] = 5,
        [17] = 6,
        [18] = 6,
        [19] = 6,
        [20] = 6
    },
    ["Sentinel"] = {
        [1] = 2,
        [2] = 2,
        [3] = 3,
        [4] = 3,
        [5] = 3,
        [6] = 4,
        [7] = 4,
        [8] = 4,
        [9] = 4,
        [10] = 4,
        [11] = 4,
        [12] = 5,
        [13] = 5,
        [14] = 5,
        [15] = 5,
        [16] = 5,
        [17] = 6,
        [18] = 6,
        [19] = 6,
        [20] = 6
    },
    ["Adept"] = {
        [1] = 2,
        [2] = 2,
        [3] = 3,
        [4] = 3,
        [5] = 3,
        [6] = 4,
        [7] = 4,
        [8] = 4,
        [9] = 4,
        [10] = 4,
        [11] = 4,
        [12] = 4,
        [13] = 5,
        [14] = 5,
        [15] = 5,
        [16] = 5,
        [17] = 6,
        [18] = 6,
        [19] = 6,
        [20] = 6
    },
    ["Explorer"] = {
        [1] = 2,
        [2] = 2,
        [3] = 3,
        [4] = 3,
        [5] = 4,
        [6] = 4,
        [7] = 4,
        [8] = 4,
        [9] = 4,
        [10] = 5,
        [11] = 5,
        [12] = 5,
        [13] = 5,
        [14] = 5,
        [15] = 5,
        [16] = 5,
        [17] = 6,
        [18] = 6,
        [19] = 6,
        [20] = 6
    },
    ["MULTI"] = {
        [1] = 2,
        [2] = 2,
        [3] = 3,
        [4] = 3,
        [5] = 4,
        [6] = 4,
        [7] = 4,
        [8] = 4,
        [9] = 4,
        [10] = 5,
        [11] = 5,
        [12] = 5,
        [13] = 5,
        [14] = 5,
        [15] = 5,
        [16] = 5,
        [17] = 6,
        [18] = 6,
        [19] = 6,
        [20] = 6
    }
};

-- Barrier ticks by class and level
local BARRIER_TICKS_BY_CLASS = {
    ["Vanguard"] = {
        [1] = 3,
        [2] = 3,
        [3] = 3,
        [4] = 4,
        [5] = 4,
        [6] = 4,
        [7] = 5,
        [8] = 5,
        [9] = 5,
        [10] = 6,
        [11] = 6,
        [12] = 6,
        [13] = 7,
        [14] = 7,
        [15] = 7,
        [16] = 8,
        [17] = 8,
        [18] = 9,
        [19] = 9,
        [20] = 10
    },
    ["Sentinel"] = {
        [1] = 2,
        [2] = 2,
        [3] = 3,
        [4] = 3,
        [5] = 4,
        [6] = 4,
        [7] = 5,
        [8] = 5,
        [9] = 6,
        [10] = 6,
        [11] = 7,
        [12] = 7,
        [13] = 8,
        [14] = 8,
        [15] = 9,
        [16] = 9,
        [17] = 10,
        [18] = 10,
        [19] = 11,
        [20] = 11
    },
    ["Adept"] = {
        [1] = 2,
        [2] = 2,
        [3] = 3,
        [4] = 3,
        [5] = 3,
        [6] = 4,
        [7] = 4,
        [8] = 4,
        [9] = 4,
        [10] = 4,
        [11] = 4,
        [12] = 4,
        [13] = 5,
        [14] = 5,
        [15] = 5,
        [16] = 5,
        [17] = 6,
        [18] = 6,
        [19] = 6,
        [20] = 6
    },
    ["Explorer"] = {
        [1] = 3,
        [2] = 3,
        [3] = 3,
        [4] = 4,
        [5] = 4,
        [6] = 4,
        [7] = 5,
        [8] = 5,
        [9] = 5,
        [10] = 6,
        [11] = 6,
        [12] = 6,
        [13] = 7,
        [14] = 7,
        [15] = 8,
        [16] = 8,
        [17] = 8,
        [18] = 9,
        [19] = 9,
        [20] = 9
    },
    ["MULTI"] = {
        [1] = 3,
        [2] = 3,
        [3] = 3,
        [4] = 4,
        [5] = 4,
        [6] = 4,
        [7] = 5,
        [8] = 5,
        [9] = 5,
        [10] = 6,
        [11] = 6,
        [12] = 6,
        [13] = 7,
        [14] = 7,
        [15] = 7,
        [16] = 8,
        [17] = 8,
        [18] = 9,
        [19] = 9,
        [20] = 10
    },
}

function onInit()
    -- Initialize the interface
    updateDefenseInterface();
end

function onClose()
    -- Clean up if needed
end

function updateDefenseInterface()
    ChatManager.SystemMessage("updateDefenseInterface called!");
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    -- Update Barrier section
    checkBarrier(nodeChar);
    
    -- Update Tech Armor section
    checkTechArmor(nodeChar);
end

function hasFeature(nodeChar, sFeatureName)
    -- Check if the character has the specified feature
    if not nodeChar then
        return false;
    end
    
    -- Look in features section
    local nodeFeatures = DB.findNode(DB.getPath(nodeChar) .. ".featurelist");
    if nodeFeatures then
        local aChildren = DB.getChildren(nodeFeatures);
        for _, nodeFeature in pairs(aChildren) do
            local sName = DB.getValue(nodeFeature, "name", "");
            if sName == sFeatureName then
                return true;
            end
        end
    end
    
    return false;
end

function checkBarrier(nodeChar)
    ChatManager.SystemMessage("checkBarrier called!");
    -- Update Barrier section
    local hasBarrier = hasFeature(nodeChar, "Barrier");
    ChatManager.SystemMessage("Has Barrier feature: " .. tostring(hasBarrier));
    
    if hasBarrier then
        -- Show barrier elements
        if self.barrier_title then 
            self.barrier_title.setVisible(true); 
        end
        if self.barrier_uses_label then 
            self.barrier_uses_label.setVisible(true);
        end
        
        -- Update barrier uses checkboxes
        updateBarrierUsesCheckboxes(nodeChar);
        
        if self.barrier_activate_test then 
            self.barrier_activate_test.setVisible(true);
            local nUses = getBarrierUses(nodeChar);
            self.barrier_activate_test.setEnabled(nUses > 0);
        end
    else
        ChatManager.SystemMessage("Character does not have Barrier feature - hiding all elements");
        -- Hide barrier elements
        if self.barrier_title then self.barrier_title.setVisible(false); end
        if self.barrier_uses_label then self.barrier_uses_label.setVisible(false); end
        if self.barrier_activate_test then self.barrier_activate_test.setVisible(false); end
        
        -- Hide all barrier use checkboxes
        for i = 1, 10 do
            local checkbox = self["barrier_use_" .. i];
            if checkbox then
                checkbox.setVisible(false);
            end
        end
    end
end

function checkTechArmor(nodeChar)
    -- Update Tech Armor section
    local hasTechArmor = hasFeature(nodeChar, "Tech Armor");

    if hasTechArmor then
        -- Show tech armor elements
        if self.techarmor_frame then self.techarmor_frame.setVisible(true); end
        if self.techarmor_title then self.techarmor_title.setVisible(true); end
        if self.techarmor_uses_label then self.techarmor_uses_label.setVisible(true); end
        if self.techarmor_uses then 
            self.techarmor_uses.setVisible(true);
            local nUses = getTechArmorUsesForClass(nodeChar);
            if nUses then
                self.techarmor_uses.setValue(nUses);
            else
                self.techarmor_uses.setValue(0);
            end
        end
        if self.techarmor_activate then 
            self.techarmor_activate.setVisible(true);
            local nUses = getTechArmorUsesForClass(nodeChar);
            self.techarmor_activate.setEnabled(nUses and nUses > 0);
        end
    else
        -- Hide tech armor elements
        if self.techarmor_frame then self.techarmor_frame.setVisible(false); end
        if self.techarmor_title then self.techarmor_title.setVisible(false); end
        if self.techarmor_uses_label then self.techarmor_uses_label.setVisible(false); end
        if self.techarmor_uses then self.techarmor_uses.setVisible(false); end
        if self.techarmor_activate then self.techarmor_activate.setVisible(false); end
    end
end

function getBarrierTicksForClass(nodeChar)
    -- Get the character's class and level to determine barrier ticks
    if not nodeChar then
        return 0;
    end
    
    local nodeClasses = DB.findNode(DB.getPath(nodeChar) .. ".classes");
    if not nodeClasses then
        return 0;
    end
    
    local maxTicks = 0;
    local vanguardLevel = 0;
    local adeptLevel = 0;
    local sentinelLevel = 0;
    local explorerLevel = 0;
    
    -- Check each class and collect levels
    for _, nodeClass in pairs(DB.getChildren(nodeClasses)) do
        local className = DB.getValue(nodeClass, "name", "");
        local classLevel = DB.getValue(nodeClass, "level", 0);
        
        if className == "Vanguard" then
            vanguardLevel = classLevel;
        elseif className == "Adept" then
            adeptLevel = classLevel;
        elseif className == "Sentinel" then
            sentinelLevel = classLevel;
        elseif className == "Explorer" then
            explorerLevel = classLevel;
        end
        
        -- Get ticks for this individual class
        if BARRIER_TICKS_BY_CLASS[className] and BARRIER_TICKS_BY_CLASS[className][classLevel] then
            local classTicks = BARRIER_TICKS_BY_CLASS[className][classLevel];
            if classTicks > maxTicks then
                maxTicks = classTicks;
            end
        end
    end
    
    -- Check if we have multiple barrier classes (need MULTI calculation)
    local barrierClassCount = 0;
    if vanguardLevel > 0 then barrierClassCount = barrierClassCount + 1; end
    if adeptLevel > 0 then barrierClassCount = barrierClassCount + 1; end
    if sentinelLevel > 0 then barrierClassCount = barrierClassCount + 1; end
    if explorerLevel > 0 then barrierClassCount = barrierClassCount + 1; end
    
    if barrierClassCount >= 2 then
        -- Calculate MULTI class level
        local multiLevel = vanguardLevel + math.floor(adeptLevel / 2) + math.floor(sentinelLevel / 2);
        if multiLevel < 1 then multiLevel = 1; end
        
        -- Get MULTI class ticks
        if BARRIER_TICKS_BY_CLASS["MULTI"] and BARRIER_TICKS_BY_CLASS["MULTI"][multiLevel] then
            local multiTicks = BARRIER_TICKS_BY_CLASS["MULTI"][multiLevel];
            if multiTicks > maxTicks then
                maxTicks = multiTicks;
            end
        end
    end
    
    return maxTicks;
end

function getBarrierUses(nodeChar)
    -- Calculate barrier uses from class and level - just take the highest from each class
    if not nodeChar then
        ChatManager.SystemMessage("getBarrierUses: No character node");
        return 0;
    end
    
    local nodeClasses = DB.findNode(DB.getPath(nodeChar) .. ".classes");
    if not nodeClasses then
        ChatManager.SystemMessage("getBarrierUses: No classes node found");
        return 0;
    end
    
    local maxUses = 0;
    
    -- Check each class and take the highest uses
    for _, nodeClass in pairs(DB.getChildren(nodeClasses)) do
        local className = DB.getValue(nodeClass, "name", "");
        local classLevel = DB.getValue(nodeClass, "level", 0);
        
        ChatManager.SystemMessage("getBarrierUses: Found class " .. className .. " level " .. classLevel);
        
        -- Get uses for this individual class
        if BARRIER_USES_BY_CLASS[className] and BARRIER_USES_BY_CLASS[className][classLevel] then
            local classUses = BARRIER_USES_BY_CLASS[className][classLevel];
            ChatManager.SystemMessage("getBarrierUses: " .. className .. " level " .. classLevel .. " gives " .. classUses .. " uses");
            if classUses > maxUses then
                maxUses = classUses;
            end
        else
            ChatManager.SystemMessage("getBarrierUses: No uses found for " .. className .. " level " .. classLevel);
        end
    end
    
    ChatManager.SystemMessage("getBarrierUses: Returning maxUses=" .. maxUses);
    return maxUses;
end

function updateBarrierUsesCheckboxes(nodeChar)
    -- Update the barrier uses checkboxes based on character's max uses and current uses
    local maxUses = getBarrierUses(nodeChar);
    local currentUses = DB.getValue(nodeChar, "barrier_uses", maxUses);
    
    ChatManager.SystemMessage("updateBarrierUsesCheckboxes: maxUses=" .. maxUses .. ", currentUses=" .. currentUses);
    
    -- Show/hide labels based on max uses
    for i = 1, 10 do
        local label = self["barrier_use_" .. i];
        if label then
            ChatManager.SystemMessage("Box " .. i .. ": maxUses=" .. maxUses .. ", i=" .. i .. ", i<=maxUses=" .. tostring(i <= maxUses));
            if i <= maxUses then
                label.setVisible(true);
                -- Fill left to right: Label shows ■ if this use has been spent (i <= maxUses - currentUses), □ if available
                local spentUses = maxUses - currentUses;
                if i <= spentUses then
                    label.setValue("■");
                else
                    label.setValue("□");
                end
                ChatManager.SystemMessage("Box " .. i .. ": visible, value=" .. (i <= spentUses and "■" or "□"));
            else
                label.setVisible(false);
                ChatManager.SystemMessage("Box " .. i .. ": hidden");
            end
        else
            ChatManager.SystemMessage("Box " .. i .. ": not found");
        end
    end
end

function updateBarrierUses()
    -- Called when a button is clicked - update the barrier_uses field
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    local maxUses = getBarrierUses(nodeChar);
    local spentUses = 0;
    
    -- Count pressed labels (spent uses)
    for i = 1, maxUses do
        local label = self["barrier_use_" .. i];
        if label and label.getValue() == "■" then
            spentUses = spentUses + 1;
        end
    end
    
    -- Update the barrier_uses field
    local remainingUses = maxUses - spentUses;
    DB.setValue(nodeChar, "barrier_uses", "number", remainingUses);
    
    -- Update button state
    if self.barrier_activate_test then
        self.barrier_activate_test.setEnabled(remainingUses > 0);
    end
end

function toggleBarrierUse(nUseIndex)
    -- Called when a specific barrier use box is clicked
    ChatManager.SystemMessage("toggleBarrierUse called for box " .. nUseIndex);
    
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        ChatManager.SystemMessage("No character node found");
        return;
    end
    
    local label = self["barrier_use_" .. nUseIndex];
    if not label then
        ChatManager.SystemMessage("Label " .. nUseIndex .. " not found");
        return;
    end
    
    local currentValue = label.getValue();
    ChatManager.SystemMessage("Box " .. nUseIndex .. " current value: " .. currentValue);
    
    -- Toggle the box
    if currentValue == "□" then
        label.setValue("■");
        ChatManager.SystemMessage("Box " .. nUseIndex .. " set to ■");
    else
        label.setValue("□");
        ChatManager.SystemMessage("Box " .. nUseIndex .. " set to □");
    end
    
    -- Update the barrier_uses field
    updateBarrierUses();
end

function getTechArmorUsesForClass(nodeChar)
    -- Get the character's class and level to determine tech armor uses
    if not nodeChar then
        return 0;
    end
    
    -- Get all classes
    local nodeClasses = DB.findNode(DB.getPath(nodeChar) .. ".classes");
    if not nodeClasses then
        return 0;
    end
    
    local aChildren = DB.getChildren(nodeClasses);
    local nTotalUses = 0;
    
    for _, nodeClass in pairs(aChildren) do
        local sClassName = DB.getValue(nodeClass, "name", "");
        
        if sClassName then
            -- Only Sentinel class gets tech armor uses (2 uses)
            if sClassName == "Sentinel" then
                nTotalUses = nTotalUses + 2;
            end
        end
    end
    
    return nTotalUses;
end

onBarrierActivate = function()
    ChatManager.SystemMessage("onBarrierActivate called!");
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    -- Get barrier ticks for this character's class
    local nTicks = getBarrierTicksForClass(nodeChar);
    if nTicks <= 0 then
        return;
    end

    ChatManager.SystemMessage("Barrier ticks: " .. nTicks);
    
    -- Use the function from the combat script
    if ME5eCombat and ME5eCombat.activateBarrier then
        Debug.console("Calling ME5eCombat.activateBarrier");
        local bSuccess = ME5eCombat.activateBarrier(nodeChar, nTicks);
        if bSuccess then
            updateDefenseInterface();
        end
    end
end

activateBarrierFromXML = function()
    ChatManager.SystemMessage("activateBarrierFromXML called!");
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        ChatManager.SystemMessage("No character node found!");
        return;
    end

    ChatManager.SystemMessage("Character node found: " .. nodeChar.getNodeName());

    -- Get barrier ticks for this character's class
    local nTicks = getBarrierTicksForClass(nodeChar);
    if nTicks <= 0 then
        ChatManager.SystemMessage("No barrier ticks available!");
        return;
    end

    ChatManager.SystemMessage("Barrier ticks: " .. nTicks);
    
    -- Check current barrier value    
    local nodeCT = ActorManager.getCTNode(nodeChar);
    local currentBarrier = DB.getValue(nodeCT, "barrier", 0);
    ChatManager.SystemMessage("Current barrier: " .. currentBarrier);
    
    -- If current barrier equals the ticks we would give, don't use a barrier use
    if currentBarrier >= nTicks then
        ChatManager.SystemMessage("Character already has full barrier (" .. currentBarrier .. " >= " .. nTicks .. "). Not using barrier use.");
        return;
    end

    -- Check if we have uses remaining
    local nUses = getBarrierUses(nodeChar);
    if nUses == 0 or nUses < 0 then
        ChatManager.SystemMessage("No barrier uses remaining!");
        return;
    end

    ChatManager.SystemMessage("Barrier uses available: " .. nUses);

    -- Use the function from the combat script
    if ME5eCombat and ME5eCombat.activateBarrier then
        ChatManager.SystemMessage("Calling ME5eCombat.activateBarrier");
        local bSuccess = ME5eCombat.activateBarrier(nodeChar, nTicks);
        if bSuccess then
            ChatManager.SystemMessage("Barrier activated successfully!");
            
            -- Mark a barrier use as spent by checking the appropriate checkbox
            local currentUses = DB.getValue(nodeChar, "barrier_uses", 0);
            local maxUses = getBarrierUses(nodeChar);
            local spentUses = maxUses - currentUses;
            
            -- Press the next unpressed label
            if spentUses < maxUses then
                local label = self["barrier_use_" .. (spentUses + 1)];
                if label then
                    label.setValue("■");
                end
            end
            
            updateDefenseInterface();
            
            -- Refresh combat tracker to show updated barrier value
            if nodeCT then
                -- Force refresh by updating the field again
                local currentBarrier = DB.getValue(nodeChar, "barrier", 0);
                DB.setValue(nodeCT, "barrier", "number", currentBarrier);
                ChatManager.SystemMessage("Combat tracker refreshed!");
            end
        else
            ChatManager.SystemMessage("Barrier activation failed!");
        end
    else
        ChatManager.SystemMessage("Error: ME5eCombat.activateBarrier not found!");
    end
end

function onTechArmorActivate()
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    -- Check if we have uses remaining
    local nUses = getTechArmorUses(nodeChar);
    if nUses <= 0 then
        return;
    end
    
    -- Use the function from the combat script
    if ME5eCombat and ME5eCombat.activateTechArmor then
        local bSuccess = ME5eCombat.activateTechArmor(nodeChar);
        if bSuccess then
            updateDefenseInterface();
        end
    end
end
