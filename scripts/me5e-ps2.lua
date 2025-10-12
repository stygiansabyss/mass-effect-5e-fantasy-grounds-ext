
local originalLinkFunction;

function onInit()
    originalLinkFunction = PartyManager2.linkPCFields

    PartyManager2.linkPCFields = linkPCFields
end

function linkPCFields(nodePs)
    local nodeChar = PartyManager.mapPStoChar(nodePS);

    PartyManager.linkRecordField(nodeChar, nodePS, "shields", "number", "shields");
    PartyManager.linkRecordField(nodeChar, nodePS, "tech_armor_hp", "number", "tech_armor_hp");
    PartyManager.linkRecordField(nodeChar, nodePS, "barrier", "number", "barrier");

    PartyManager2.linkPCFields = originalLinkFunction
    PartyManager2.linkPCFields(nodePs)
end