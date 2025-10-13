--
-- Mass Effect 5e Defenses Commands
-- Adds chat commands to open the Character Defenses window
--

function onInit()
    -- Register chat commands
    Comm.registerSlashHandler("defenses", onDefensesCommand);
    Comm.registerSlashHandler("defense", onDefensesCommand);
    Comm.registerSlashHandler("me5edefenses", onDefensesCommand);
    Comm.registerSlashHandler("testwindow", onTestWindowCommand);
end

function onClose()
    -- Clean up
end

function onDefensesCommand(sCommand, sParams)
    -- Get the current character
    local nodeChar = nil;
    
    -- Try to get character from various sources
    if Session.IsHost then
        -- If host, try to get from combat tracker selection
        local nodeSelected = CombatManager.getActiveCT();
        if nodeSelected then
            local sActorType, nodeActor = ActorManager.getTypeAndNode(nodeSelected);
            if sActorType == "pc" then
                nodeChar = nodeActor;
            end
        end
    else
        -- If client, try to get their own character
        local nodeCharList = DB.getChildren("charsheet");
        for _, nodeCharNode in pairs(nodeCharList) do
            local sOwner = DB.getValue(nodeCharNode, "owner", "");
            if sOwner == User.getUsername() then
                nodeChar = nodeCharNode;
                break;
            end
        end
    end
    
    -- Try to open the defenses window
    ChatManager.SystemMessage("Attempting to open ME5e defenses window...");
    local wDefenses = Interface.openWindow("me5e_defenses", nil);
    if wDefenses then
        ChatManager.SystemMessage("Window created successfully!");
        wDefenses.bringToFront();
        wDefenses.setPosition(100, 100);
        wDefenses.setSize(400, 300);
        ChatManager.SystemMessage("Character Defenses window opened successfully.");
    else
        ChatManager.SystemMessage("Error: Could not open Character Defenses window. Window creation returned nil.");
    end
end

function onTestWindowCommand(sCommand, sParams)
    ChatManager.SystemMessage("Attempting to open test window...");
    local wTest = Interface.openWindow("test_window", nil);
    if wTest then
        ChatManager.SystemMessage("Test window created successfully!");
        ChatManager.SystemMessage("Window position: " .. wTest.getPosition());
        ChatManager.SystemMessage("Window size: " .. wTest.getSize());
        wTest.setPosition(200, 200);
        wTest.setSize(300, 200);
        if wTest.show then
            wTest.show();
            ChatManager.SystemMessage("Called show() method");
        end
        wTest.bringToFront();
        ChatManager.SystemMessage("Test window opened successfully.");
    else
        ChatManager.SystemMessage("Error: Could not open test window. Window creation returned nil.");
    end
end
