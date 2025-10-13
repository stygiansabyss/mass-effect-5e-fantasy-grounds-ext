function onInit()
    super.onInit();
    onHealthChanged();
end

function linkPCFields()
    super.linkPCFields();
    local nodeChar = link.getTargetDatabaseNode();
    if nodeChar then
        shields.setLink(DB.createChild(nodeChar, "shields", "number"))
        tech_armor_hp.setLink(DB.createChild(nodeChar, "tech_armor_hp", "number"))
        barrier.setLink(DB.createChild(nodeChar, "barrier", "number"))
    end
end