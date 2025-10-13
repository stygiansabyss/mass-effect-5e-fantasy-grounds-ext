--
-- Character Defenses Window
-- Handles Barrier, Tech Armor, and Tactical Cloak activation
--

function onInit()
    -- Set up button handlers
    if self.barrier_activate then
        self.barrier_activate.onClick = onBarrierActivate;
    end
    if self.techarmor_activate then
        self.techarmor_activate.onClick = onTechArmorActivate;
    end
    if self.cloak_activate then
        self.cloak_activate.onClick = onCloakActivate;
    end
    
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
    local hasBarrier = hasFeature(nodeChar, "Barrier");
    if hasBarrier then
        -- Show barrier elements
        if self.barrier_frame then self.barrier_frame.setVisible(true); end
        if self.barrier_title then self.barrier_title.setVisible(true); end
        if self.barrier_uses_label then self.barrier_uses_label.setVisible(true); end
        if self.barrier_uses then 
            self.barrier_uses.setVisible(true);
            local nUses = getBarrierUses(nodeChar);
            self.barrier_uses.setValue(nUses);
        end
        if self.barrier_activate then 
            self.barrier_activate.setVisible(true);
            local nUses = getBarrierUses(nodeChar);
            self.barrier_activate.setEnabled(nUses > 0);
        end
    else
        -- Hide barrier elements
        if self.barrier_frame then self.barrier_frame.setVisible(false); end
        if self.barrier_title then self.barrier_title.setVisible(false); end
        if self.barrier_uses_label then self.barrier_uses_label.setVisible(false); end
        if self.barrier_uses then self.barrier_uses.setVisible(false); end
        if self.barrier_activate then self.barrier_activate.setVisible(false); end
    end
    
    -- Update Tech Armor section
    local hasTechArmor = hasFeature(nodeChar, "Tech Armor");
    if hasTechArmor then
        -- Show tech armor elements
        if self.techarmor_frame then self.techarmor_frame.setVisible(true); end
        if self.techarmor_title then self.techarmor_title.setVisible(true); end
        if self.techarmor_uses_label then self.techarmor_uses_label.setVisible(true); end
        if self.techarmor_uses then 
            self.techarmor_uses.setVisible(true);
            local nUses = getTechArmorUses(nodeChar);
            self.techarmor_uses.setValue(nUses);
        end
        if self.techarmor_activate then 
            self.techarmor_activate.setVisible(true);
            local nUses = getTechArmorUses(nodeChar);
            self.techarmor_activate.setEnabled(nUses > 0);
        end
    else
        -- Hide tech armor elements
        if self.techarmor_frame then self.techarmor_frame.setVisible(false); end
        if self.techarmor_title then self.techarmor_title.setVisible(false); end
        if self.techarmor_uses_label then self.techarmor_uses_label.setVisible(false); end
        if self.techarmor_uses then self.techarmor_uses.setVisible(false); end
        if self.techarmor_activate then self.techarmor_activate.setVisible(false); end
    end
    
    -- Update Tactical Cloak section
    local hasCloak = hasFeature(nodeChar, "Tactical Cloak");
    if hasCloak then
        -- Show cloak elements
        if self.cloak_frame then self.cloak_frame.setVisible(true); end
        if self.cloak_title then self.cloak_title.setVisible(true); end
        if self.cloak_uses_label then self.cloak_uses_label.setVisible(true); end
        if self.cloak_uses then 
            self.cloak_uses.setVisible(true);
            local nUses = getCloakUses(nodeChar);
            self.cloak_uses.setValue(nUses);
        end
        if self.cloak_activate then 
            self.cloak_activate.setVisible(true);
            local nUses = getCloakUses(nodeChar);
            self.cloak_activate.setEnabled(nUses > 0);
        end
    else
        -- Hide cloak elements
        if self.cloak_frame then self.cloak_frame.setVisible(false); end
        if self.cloak_title then self.cloak_title.setVisible(false); end
        if self.cloak_uses_label then self.cloak_uses_label.setVisible(false); end
        if self.cloak_uses then self.cloak_uses.setVisible(false); end
        if self.cloak_activate then self.cloak_activate.setVisible(false); end
    end
end

function hasFeature(nodeChar, sFeatureName)
    -- Check if the character has the specified feature
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

function getBarrierUses(nodeChar)
    -- Get current barrier uses from the character sheet
    if not nodeChar then
        return 0;
    end
    
    local nUses = DB.getValue(nodeChar, "barrier_uses", 0);
    return nUses;
end

function getTechArmorUses(nodeChar)
    -- Get current tech armor uses from the character sheet
    if not nodeChar then
        return 0;
    end
    
    local nUses = DB.getValue(nodeChar, "techarmor_uses", 0);
    return nUses;
end

function getCloakUses(nodeChar)
    -- Get current tactical cloak uses from the character sheet
    if not nodeChar then
        return 0;
    end
    
    local nUses = DB.getValue(nodeChar, "cloak_uses", 0);
    return nUses;
end

function onBarrierActivate()
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    -- Check if we have uses remaining
    local nUses = getBarrierUses(nodeChar);
    if nUses <= 0 then
        ChatManager.SystemMessage("No barrier uses remaining!");
        return;
    end
    
    -- Use the function from the combat script
    if ME5eCombat and ME5eCombat.activateBarrier then
        local bSuccess = ME5eCombat.activateBarrier(nodeChar);
        if bSuccess then
            updateDefenseInterface();
        end
    else
        ChatManager.SystemMessage("Error: Combat script not loaded!");
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
        ChatManager.SystemMessage("No tech armor uses remaining!");
        return;
    end
    
    -- Use the function from the combat script
    if ME5eCombat and ME5eCombat.activateTechArmor then
        local bSuccess = ME5eCombat.activateTechArmor(nodeChar);
        if bSuccess then
            updateDefenseInterface();
        end
    else
        ChatManager.SystemMessage("Error: Combat script not loaded!");
    end
end

function onCloakActivate()
    local nodeChar = getDatabaseNode();
    if not nodeChar then
        return;
    end
    
    -- Check if we have uses remaining
    local nUses = getCloakUses(nodeChar);
    if nUses <= 0 then
        ChatManager.SystemMessage("No tactical cloak uses remaining!");
        return;
    end
    
    -- For now, just reduce uses (we can add cloak functionality later)
    local nNewUses = nUses - 1;
    DB.setValue(nodeChar, "cloak_uses", "number", nNewUses);
    ChatManager.SystemMessage("Tactical Cloak activated! Uses remaining: " .. nNewUses);
    
    updateDefenseInterface();
end
