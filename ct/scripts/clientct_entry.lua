function onInit()
    super.onInit();
    onHealthChanged();
end

function onFactionChanged()
    super.onFactionChanged();
    updateDefenseDisplay();
end

function updateDefenseDisplay()
    local sOption;
    if friendfoe.getStringValue() == "friend" then
        sOption = OptionsManager.getOption("SHPC");
    else
        sOption = OptionsManager.getOption("SHNPC");
    end

    local bShowDetail = (sOption == "detailed");
    local bShowStatus = (sOption == "status");

    shields.setVisible(bShowDetail);
    tech_armor_hp.setVisible(bShowDetail);
    barrier.setVisible(bShowDetail);

    shields_status.setVisible(bShowStatus);
    tech_armor_status.setVisible(bShowStatus);
    barrier_status.setVisible(bShowStatus);
end