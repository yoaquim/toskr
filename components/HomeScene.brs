sub init()
    ' 2x2 grid: [0,0]=country [1,0]=surf [0,1]=favorites [1,1]=radio
    m.gridCol = 0
    m.gridRow = 0

    m.posters = [
        [m.top.findNode("cardCountry"), m.top.findNode("cardSurf")],
        [m.top.findNode("cardFavorites"), m.top.findNode("cardRadio")]
    ]
    m.modes = [
        ["country", "surf"],
        ["favorites", "radio"]
    ]

    m.top.setFocus(true)
    updateFocus()
end sub

sub updateFocus()
    for row = 0 to 1
        for col = 0 to 1
            if row = m.gridRow and col = m.gridCol
                m.posters[row][col].opacity = 1.0
            else
                m.posters[row][col].opacity = 0.4
            end if
        end for
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "right"
        if m.gridCol < 1
            m.gridCol = 1
            updateFocus()
            return true
        end if
    else if key = "left"
        if m.gridCol > 0
            m.gridCol = 0
            updateFocus()
            return true
        end if
    else if key = "up"
        if m.gridRow > 0
            m.gridRow = 0
            updateFocus()
            return true
        end if
    else if key = "down"
        if m.gridRow < 1
            m.gridRow = 1
            updateFocus()
            return true
        end if
    else if key = "OK" or key = "play"
        m.top.selectedMode = m.modes[m.gridRow][m.gridCol]
        return true
    end if

    return false
end function
