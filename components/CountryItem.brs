sub init()
    m.bg = m.top.findNode("bg")
    m.focusBg = m.top.findNode("focusBg")
    m.accentBar = m.top.findNode("accentBar")
    m.favIcon = m.top.findNode("favIcon")
    m.label = m.top.findNode("label")
end sub

sub onContentChanged()
    content = m.top.itemContent
    if content = invalid then return

    itemType = content.description

    ' Show acorn icon for favorites item or favorited channels
    if itemType = "FAVORITES" or itemType = "fav"
        m.favIcon.uri = "pkg:/images/fav_acorn.png"
        m.favIcon.visible = true
        m.label.translation = [40, 11]
    else
        m.favIcon.visible = false
        m.label.translation = [16, 11]
    end if

    m.label.text = content.title
    setTypeColor(itemType)
end sub

sub onFocusChanged()
    focused = m.top.focusPercent > 0.5
    content = m.top.itemContent
    if content = invalid then return

    itemType = content.description
    isDivider = (itemType = "DIVIDER")

    m.focusBg.visible = focused and not isDivider
    m.accentBar.visible = focused and not isDivider

    if focused and not isDivider
        m.label.color = "#ffffff"
    else
        setTypeColor(itemType)
    end if
end sub

sub setTypeColor(itemType as string)
    if itemType = "SEARCH"
        m.label.color = "#b08060"
    else if itemType = "LANGUAGE"
        m.label.color = "#b08060"
    else if itemType = "FAVORITES"
        m.label.color = "#f07020"
    else if itemType = "DIVIDER"
        m.label.color = "#d8c8b8"
    else
        m.label.color = "#704020"
    end if
end sub
