sub init()
    ' Two rows: favorites (row 0) and cards (row 1)
    m.focusRow = 1  ' Start on cards row
    m.cardIndex = 0  ' Which card in the bottom row

    m.favPoster = m.top.findNode("cardFavorites")
    m.cardPosters = [
        m.top.findNode("cardCountry"),
        m.top.findNode("cardSurf"),
        m.top.findNode("cardRadio")
    ]
    m.cardModes = ["country", "surf", "radio"]

    m.top.setFocus(true)
    updateFocus()
end sub

sub updateFocus()
    ' Favorites banner
    if m.focusRow = 0
        m.favPoster.opacity = 1.0
    else
        m.favPoster.opacity = 0.4
    end if

    ' Bottom cards
    for i = 0 to m.cardPosters.count() - 1
        if m.focusRow = 1 and i = m.cardIndex
            m.cardPosters[i].opacity = 1.0
        else
            m.cardPosters[i].opacity = 0.4
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "up"
        if m.focusRow = 1
            m.focusRow = 0
            updateFocus()
            return true
        end if
    else if key = "down"
        if m.focusRow = 0
            m.focusRow = 1
            updateFocus()
            return true
        end if
    else if key = "right"
        if m.focusRow = 1 and m.cardIndex < 2
            m.cardIndex = m.cardIndex + 1
            updateFocus()
            return true
        end if
    else if key = "left"
        if m.focusRow = 1 and m.cardIndex > 0
            m.cardIndex = m.cardIndex - 1
            updateFocus()
            return true
        end if
    else if key = "OK" or key = "play"
        if m.focusRow = 0
            m.top.selectedMode = "favorites"
        else
            m.top.selectedMode = m.cardModes[m.cardIndex]
        end if
        return true
    end if

    return false
end function
