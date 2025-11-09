--
-- Helper methods for interacting with classes.
--

function getClassNode(nodeTarget, sClassName)
    -- Try to get from the character sheet classes section (array of classes)
    local sNodePath = DB.getPath(nodeTarget);
    local nodeClasses = DB.findNode(sNodePath .. ".classes");
    
    if nodeClasses then
        -- Check all classes to find if any are Vanguard (or other ME5e classes)
        local nClassCount = DB.getChildCount(nodeClasses);
        local sFirstClass = nil;
        
        -- Get all child nodes and iterate through them (don't assume sequential IDs)
        local aChildren = DB.getChildren(nodeClasses);
        for _, nodeClass in pairs(aChildren) do
            if nodeClass then
                local sClass = DB.getValue(nodeClass, "name", "");
                
                if sClass == sClassName then
                    return nodeClass;
                end
            end
        end
    end
    
    return nil;
end