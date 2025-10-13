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
    -- Update Barrier section
    local hasBarrier = hasFeature(nodeChar, "Barrier");
    
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
        if self.techarmor_title then self.techarmor_title.setVisible(true); end
        if self.techarmor_uses_label then self.techarmor_uses_label.setVisible(true); end
        if self.techarmor_activate_test then 
            self.techarmor_activate_test.setVisible(true);
            local nUses = getTechArmorUses(nodeChar);
            self.techarmor_activate_test.setEnabled(nUses > 0);
        end
        
        -- Update tech armor use checkboxes
        updateTechArmorUsesCheckboxes(nodeChar);
    else
        -- Hide tech armor elements
        if self.techarmor_title then self.techarmor_title.setVisible(false); end
        if self.techarmor_uses_label then self.techarmor_uses_label.setVisible(false); end
        if self.techarmor_activate_test then self.techarmor_activate_test.setVisible(false); end
        
        -- Hide all tech armor use boxes
        for i = 1, 2 do
            local label = self["techarmor_use_" .. i];
            if label then
                label.setVisible(false);
            end
        end
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
        return 0;
    end
    
    local nodeClasses = DB.findNode(DB.getPath(nodeChar) .. ".classes");
    if not nodeClasses then
        return 0;
    end
    
    local maxUses = 0;
    
    -- Check each class and take the highest uses
    for _, nodeClass in pairs(DB.getChildren(nodeClasses)) do
        local className = DB.getValue(nodeClass, "name", "");
        local classLevel = DB.getValue(nodeClass, "level", 0);
              
        -- Get uses for this individual class
        if BARRIER_USES_BY_CLASS[className] and BARRIER_USES_BY_CLASS[className][classLevel] then
            local classUses = BARRIER_USES_BY_CLASS[className][classLevel];
            if classUses > maxUses then
                maxUses = classUses;
            end
        end
    end
    
    return maxUses;
end

function updateBarrierUsesCheckboxes(nodeChar)
    -- Update the barrier uses checkboxes based on character's max uses and current uses
    local maxUses = getBarrierUses(nodeChar);
    local currentUses = DB.getValue(nodeChar, "barrier_uses", maxUses);
       
    -- Show/hide labels based on max uses
    for i = 1, 10 do
        local label = self["barrier_use_" .. i];
        if label then
            if i <= maxUses then
                label.setVisible(true);
                -- Fill left to right: Label shows ■ if this use has been spent (i <= maxUses - currentUses), □ if available
                local spentUses = maxUses - currentUses;
                if i <= spentUses then
                    label.setValue("■");
                else
                    label.setValue("□");
                end
            else
                label.setVisible(false);
            end
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
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    local label = self["barrier_use_" .. nUseIndex];
    if not label then
        return;
    end
    
    local currentValue = label.getValue();
    
    -- Toggle the box
    if currentValue == "□" then
        label.setValue("■");
    else
        label.setValue("□");
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
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    -- Get barrier ticks for this character's class
    local nTicks = getBarrierTicksForClass(nodeChar);
    if nTicks <= 0 then
        return;
    end
   
    -- Use the function from the combat script
    if ME5eCombat and ME5eCombat.activateBarrier then
        local bSuccess = ME5eCombat.activateBarrier(nodeChar, nTicks);
        if bSuccess then
            updateDefenseInterface();
        end
    end
end

activateBarrierFromXML = function()
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end

    -- Get barrier ticks for this character's class
    local nTicks = getBarrierTicksForClass(nodeChar);
    if nTicks <= 0 then
        return;
    end
   
    -- Check current barrier value    
    local nodeCT = ActorManager.getCTNode(nodeChar);
    local currentBarrier = DB.getValue(nodeCT, "barrier", 0);
    
    -- If current barrier equals the ticks we would give, don't use a barrier use
    if currentBarrier >= nTicks then
        ChatManager.SystemMessage("Character already has full barrier (" .. currentBarrier .. " >= " .. nTicks .. "). Not using barrier use.");
        return;
    end

    -- Check if we have uses remaining
    local nUses = getBarrierUses(nodeChar);
    if nUses == 0 or nUses < 0 then
        return;
    end

    -- Use the function from the combat script
    if ME5eCombat and ME5eCombat.activateBarrier then
        local bSuccess = ME5eCombat.activateBarrier(nodeChar, nTicks);
        if bSuccess then            
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
            end
        end
    end
end

-- Tech Armor Functions
function getTechArmorUses(nodeChar)
    -- Tech armor is only available to Sentinel class, always 2 uses
    if not nodeChar then
        return 0;
    end
    
    local nodeClasses = DB.findNode(DB.getPath(nodeChar) .. ".classes");
    if not nodeClasses then
        return 0;
    end
    
    -- Check if character has Sentinel class
    for _, nodeClass in pairs(DB.getChildren(nodeClasses)) do
        local className = DB.getValue(nodeClass, "name", "");
        if className == "Sentinel" then
            return 2;
        end
    end
    
    return 0;
end

function getTechArmorHP(nodeChar)
    -- Calculate tech armor HP as (Sentinel level + INT modifier) x 2
    if not nodeChar then
        return 0;
    end
    
    local nodeClasses = DB.findNode(DB.getPath(nodeChar) .. ".classes");
    if not nodeClasses then
        return 0;
    end
    
    local sentinelLevel = 0;
    for _, nodeClass in pairs(DB.getChildren(nodeClasses)) do
        local className = DB.getValue(nodeClass, "name", "");
        if className == "Sentinel" then
            sentinelLevel = DB.getValue(nodeClass, "level", 0);
            break;
        end
    end
    
    if sentinelLevel == 0 then
        return 0;
    end
    
    -- Get INT modifier
    local intScore = DB.getValue(nodeChar, "abilities.intelligence.score", 10);
    local intModifier = math.floor((intScore - 10) / 2);
    
    local techArmorHP = (sentinelLevel + intModifier) * 2;
    
    return techArmorHP;
end

function updateTechArmorUsesCheckboxes(nodeChar)
    -- Update the tech armor uses checkboxes based on character's max uses and current uses
    local maxUses = getTechArmorUses(nodeChar);
    local currentUses = DB.getValue(nodeChar, "techarmor_uses", maxUses);
       
    -- Show/hide labels based on max uses (only 2 boxes)
    for i = 1, 2 do
        local label = self["techarmor_use_" .. i];
        if label then
            if i <= maxUses then
                label.setVisible(true);
                -- Fill left to right: Label shows ■ if this use has been spent (i <= maxUses - currentUses), □ if available
                local spentUses = maxUses - currentUses;
                if i <= spentUses then
                    label.setValue("■");
                else
                    label.setValue("□");
                end
            else
                label.setVisible(false);
            end
        end
    end
end

function updateTechArmorUses()
    -- Called when a button is clicked - update the techarmor_uses field
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    local maxUses = getTechArmorUses(nodeChar);
    local spentUses = 0;
    
    -- Count spent uses
    for i = 1, maxUses do
        local label = self["techarmor_use_" .. i];
        if label and label.getValue() == "■" then
            spentUses = spentUses + 1;
        end
    end
    
    -- Update the techarmor_uses field
    local remainingUses = maxUses - spentUses;
    DB.setValue(nodeChar, "techarmor_uses", "number", remainingUses);
    
    -- Update button state
    if self.techarmor_activate_test then
        self.techarmor_activate_test.setEnabled(remainingUses > 0);
    end
end

function toggleTechArmorUse(nUseIndex)
    -- Called when a specific tech armor use box is clicked    
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    local label = self["techarmor_use_" .. nUseIndex];
    if not label then
        return;
    end
    
    local currentValue = label.getValue();
    
    -- Toggle the box
    if currentValue == "□" then
        label.setValue("■");
    else
        label.setValue("□");
    end
    
    -- Update the techarmor_uses field
    updateTechArmorUses();
end

activateTechArmorFromXML = function()
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end

    -- Get tech armor HP for this character
    local nTechArmorHP = getTechArmorHP(nodeChar);
    if nTechArmorHP <= 0 then
        return;
    end
    
    -- Check current tech armor HP value    
    local nodeCT = ActorManager.getCTNode(nodeChar);
    local currentTechArmorHP = DB.getValue(nodeCT, "tech_armor_hp", 0);
    
    -- If current tech armor HP equals the HP we would give, don't use a tech armor use
    if currentTechArmorHP >= nTechArmorHP then
        ChatManager.SystemMessage("Character already has full tech armor HP (" .. currentTechArmorHP .. " >= " .. nTechArmorHP .. "). Not using tech armor use.");
        return;
    end

    -- Check if we have uses remaining
    local nUses = getTechArmorUses(nodeChar);
    if nUses == 0 or nUses < 0 then
        return;
    end

    -- Use the function from the combat script
    if ME5eCombat and ME5eCombat.activateTechArmor then
        local bSuccess = ME5eCombat.activateTechArmor(nodeChar, nTechArmorHP);
        if bSuccess then            
            -- Mark a tech armor use as spent by checking the appropriate checkbox
            local currentUses = DB.getValue(nodeChar, "techarmor_uses", 0);
            local maxUses = getTechArmorUses(nodeChar);
            local spentUses = maxUses - currentUses;
            
            -- Press the next unpressed label (fill left to right)
            if spentUses < maxUses then
                local label = self["techarmor_use_" .. (spentUses + 1)];
                if label then
                    label.setValue("■");
                end
            end
            
            updateDefenseInterface();
            
            -- Refresh combat tracker to show updated tech armor HP value
            if nodeCT then
                -- Force refresh by updating the field again
                local currentTechArmorHP = DB.getValue(nodeChar, "tech_armor_hp", 0);
                DB.setValue(nodeCT, "tech_armor_hp", "number", currentTechArmorHP);
            end
        end
    end
end

function onTechArmorActivate()
    -- Legacy function - redirect to new system
    activateTechArmorFromXML();
end
