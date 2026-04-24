sub init()
    m.rowBg = m.top.findNode("rowBg")
    m.focusBg = m.top.findNode("focusBg")
    m.accentBar = m.top.findNode("accentBar")
    m.nameLabel = m.top.findNode("nameLabel")
    m.favIcon = m.top.findNode("favIcon")
end sub

sub onContentChanged()
    content = m.top.itemContent
    if content = invalid then return

    m.nameLabel.text = content.title
    if content.description = "fav"
        m.favIcon.uri = "pkg:/images/fav_acorn.png"
        m.favIcon.visible = true
    else
        m.favIcon.uri = ""
        m.favIcon.visible = false
    end if
end sub

sub onFocusChanged()
    focused = m.top.focusPercent > 0.5
    m.focusBg.visible = focused
    m.accentBar.visible = focused

    if focused
        m.nameLabel.color = "#ffffff"
    else
        m.nameLabel.color = "#704020"
    end if
end sub
