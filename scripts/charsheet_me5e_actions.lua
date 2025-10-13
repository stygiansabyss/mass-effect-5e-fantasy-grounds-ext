--
-- Mass Effect 5e Character Sheet Actions
-- Handles Barrier and Tech Armor activation buttons
--

function onInit()
    -- Set up button handlers
    if self.barrier_activate then
        self.barrier_activate.onClick = onBarrierActivate;
    end
    if self.techarmor_activate then
        self.techarmor_activate.onClick = onTechArmorActivate;
    end
    
    -- Initialize the interface - check if elements exist first
    if self.me5e_defenses_header then
        updateDefenseInterface();
    end
end

function onClose()
    -- Clean up if needed
end

function updateDefenseInterface()
    -- Check if character has Barrier feature
    local hasBarrier = hasFeature("Barrier");
    if hasBarrier then
        -- Show barrier elements
        if self.barrier_area then self.barrier_area.setVisible(true); end
        if self.barrier_label then self.barrier_label.setVisible(true); end
        if self.barrier_uses then 
            self.barrier_uses.setVisible(true);
            local nUses = getBarrierUses();
            self.barrier_uses.setValue(nUses);
        end
        if self.barrier_activate then 
            self.barrier_activate.setVisible(true);
            local nUses = getBarrierUses();
            self.barrier_activate.setEnabled(nUses > 0);
        end
    else
        -- Hide barrier elements
        if self.barrier_area then self.barrier_area.setVisible(false); end
        if self.barrier_label then self.barrier_label.setVisible(false); end
        if self.barrier_uses then self.barrier_uses.setVisible(false); end
        if self.barrier_activate then self.barrier_activate.setVisible(false); end
    end
    
    -- Check if character has Tech Armor feature
    local hasTechArmor = hasFeature("Tech Armor");
    if hasTechArmor then
        -- Show tech armor elements
        if self.techarmor_area then self.techarmor_area.setVisible(true); end
        if self.techarmor_label then self.techarmor_label.setVisible(true); end
        if self.techarmor_uses then 
            self.techarmor_uses.setVisible(true);
            local nUses = getTechArmorUses();
            self.techarmor_uses.setValue(nUses);
        end
        if self.techarmor_activate then 
            self.techarmor_activate.setVisible(true);
            local nUses = getTechArmorUses();
            self.techarmor_activate.setEnabled(nUses > 0);
        end
    else
        -- Hide tech armor elements
        if self.techarmor_area then self.techarmor_area.setVisible(false); end
        if self.techarmor_label then self.techarmor_label.setVisible(false); end
        if self.techarmor_uses then self.techarmor_uses.setVisible(false); end
        if self.techarmor_activate then self.techarmor_activate.setVisible(false); end
    end
end

function hasFeature(sFeatureName)
    -- Check if the character has the specified feature
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return false;
    end
    
    -- Look in features section
    local nodeFeatures = DB.findNode(DB.getPath(nodeChar) .. ".features");
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

function getBarrierUses()
    -- Get current barrier uses from the character sheet
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return 0;
    end
    
    -- Look for barrier uses in features or custom fields
    local nUses = DB.getValue(nodeChar, "barrier_uses", 0);
    return nUses;
end

function getTechArmorUses()
    -- Get current tech armor uses from the character sheet
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return 0;
    end
    
    -- Look for tech armor uses in features or custom fields
    local nUses = DB.getValue(nodeChar, "techarmor_uses", 0);
    return nUses;
end

function onBarrierActivate()
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    -- Check if we have uses remaining
    local nUses = getBarrierUses();
    if nUses <= 0 then
        return;
    end
    
    -- Use the function from the combat script
    if ME5eCombat and ME5eCombat.activateBarrier then
        local bSuccess = ME5eCombat.activateBarrier(nodeChar);
        if bSuccess then
            updateDefenseInterface();
        end
    end
end

function onTechArmorActivate()
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    -- Check if we have uses remaining
    local nUses = getTechArmorUses();
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

