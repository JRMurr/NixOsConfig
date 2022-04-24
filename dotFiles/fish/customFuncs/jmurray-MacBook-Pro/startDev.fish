function startDev
    set --local tab_title "Bodata"
    set --local tab_matcher "title:$tab_title"

    kitty @ set-tab-title $tab_title
    kitty @ launch --match $tab_matcher --copy-env \
        fish -c "npmc"
    kitty @ resize-window --self --axis vertical --increment 50
    npms
end