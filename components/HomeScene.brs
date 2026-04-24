sub init()
    m.cards = ["country", "favorites", "surf"]
    m.posters = [
        m.top.findNode("cardCountry"),
        m.top.findNode("cardFavorites"),
        m.top.findNode("cardSurf")
    ]
    m.selectedIndex = 0

    m.top.setFocus(true)
    updateFocus()
end sub

sub updateFocus()
    for i = 0 to m.posters.count() - 1
        if i = m.selectedIndex
            m.posters[i].opacity = 1.0
        else
            m.posters[i].opacity = 0.4
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "right"
        if m.selectedIndex < 2
            m.selectedIndex = m.selectedIndex + 1
            updateFocus()
            return true
        end if
    else if key = "left"
        if m.selectedIndex > 0
            m.selectedIndex = m.selectedIndex - 1
            updateFocus()
            return true
        end if
    else if key = "OK" or key = "play"
        m.top.selectedMode = m.cards[m.selectedIndex]
        return true
    end if

    return false
end function
