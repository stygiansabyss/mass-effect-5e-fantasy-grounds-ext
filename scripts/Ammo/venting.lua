---
-- Venting system - track weapon ammo usage per character
--
local weaponAmmoTracker = {};

function onInit()
    -- Hook into combat turn management for venting system
    CombatManager.setCustomTurnStart(onTurnStart);
end

-- Hook into Fantasy Grounds turn start events
function onTurnStart(nodeEntry)
    if not nodeEntry then
        return;
    end
    
    -- Process venting for this character
    processVenting(nodeEntry);
end

-- Process venting at the start of each character's turn
function processVenting(actorNode)
    -- Only process if venting is enabled
    if OptionsManager.getOption("ME5E_HEAT_HANDLING") ~= "venting" then return end;

    if not actorNode then 
        return;
    end
    
    -- Get the actual character sheet from the combat tracker entry
    local sClass, sRecord = DB.getValue(actorNode, "link");
    if not sClass or not sRecord or sClass ~= "charsheet" then
        return;
    end
    
    local charNode = DB.findNode(sRecord);
    if not charNode then
        return;
    end
    
    -- Use character sheet ID for tracking (more reliable than combat tracker ID)
    local charId = charNode.getNodeName();
    if not weaponAmmoTracker[charId] then
        initializeAmmoTracking(charNode);
        return;
    end
    
    -- Get all weapons from the character's weaponlist
    local nodeWeaponList = DB.findNode(charNode.getPath() .. ".weaponlist");
    if not nodeWeaponList then 
        return;
    end
    
    local weaponList = DB.getChildList(nodeWeaponList);
    
    for _, weaponNode in ipairs(weaponList) do
        if weaponNode then
            local weaponName = DB.getValue(weaponNode, "name", "");
            local usedAmmo = DB.getValue(weaponNode, "ammo", 0);
            local maxAmmo = DB.getValue(weaponNode, "maxammo", 0);
            local carried = DB.getValue(weaponNode, "carried", 0);
            
            -- Only process equipped weapons that have ammo capacity (carried = 2 and maxAmmo > 0)
            if carried == 2 and maxAmmo > 0 then
                -- Initialize tracking if this weapon isn't being tracked yet
                if not weaponAmmoTracker[charId][weaponName] then
                    weaponAmmoTracker[charId][weaponName] = {
                        lastUsedAmmo = usedAmmo,
                        firedThisRound = false
                    };
                end
                
                local tracking = weaponAmmoTracker[charId][weaponName];
                
                -- Check if weapon was fired this round (compare current vs last known ammo)
                local wasFired = (usedAmmo > tracking.lastUsedAmmo);
                
                if not wasFired then
                    -- Weapon wasn't fired, regenerate 1 ammo (reduce used ammo by 1)
                    if usedAmmo > 0 then
                        local newUsedAmmo = math.max(usedAmmo - 1, 0);
                        DB.setValue(weaponNode, "ammo", "number", newUsedAmmo);
                        
                        -- Send individual message for each weapon that vents
                        ChatManager.SystemMessage("[Venting] " .. weaponName .. " vented 1 heat");
                    end
                end
                
                -- Always update tracking to current ammo count for next round
                tracking.lastUsedAmmo = DB.getValue(weaponNode, "ammo", 0);
                tracking.firedThisRound = false;
            end
        end
    end
    
end

-- Initialize ammo tracking for a character
function initializeAmmoTracking(charNode)
    if not charNode then return end;
    
    -- Use the character sheet path as the ID for tracking
    local charId = charNode.getNodeName();
    if not weaponAmmoTracker[charId] then
        weaponAmmoTracker[charId] = {};
    end
    
    -- Get all weapons from the character's weaponlist
    local nodeWeaponList = DB.findNode(charNode.getPath() .. ".weaponlist");
    if nodeWeaponList then
        local weaponList = DB.getChildList(nodeWeaponList);
        for _, weaponNode in ipairs(weaponList) do
            if weaponNode then
                local weaponName = DB.getValue(weaponNode, "name", "");
                local usedAmmo = DB.getValue(weaponNode, "ammo", 0);
                local maxAmmo = DB.getValue(weaponNode, "maxammo", 0);
                local carried = DB.getValue(weaponNode, "carried", 0);
                
                -- Initialize tracking for equipped weapons with ammo capacity
                if carried == 2 and maxAmmo > 0 then
                    if not weaponAmmoTracker[charId][weaponName] then
                        weaponAmmoTracker[charId][weaponName] = {
                            lastUsedAmmo = usedAmmo,
                            firedThisRound = false
                        };
                    else
                        -- Update the used ammo count
                        weaponAmmoTracker[charId][weaponName].lastUsedAmmo = usedAmmo;
                    end
                end
            end
        end
    end
end

-- Track weapon firing (called when a weapon is used)
function trackWeaponFiring(actorNode, weaponName)
    if not actorNode or not weaponName then return end;
    
    local actorId = actorNode.getNodeName();
    if weaponAmmoTracker[actorId] and weaponAmmoTracker[actorId][weaponName] then
        weaponAmmoTracker[actorId][weaponName].firedThisRound = true;
    end
end