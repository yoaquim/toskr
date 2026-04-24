sub main()
    screen = createObject("roSGScreen")
    port = createObject("roMessagePort")
    screen.setMessagePort(port)

    while true
        ' Show home screen
        scene = screen.createScene("HomeScene")
        screen.show()
        scene.observeField("selectedMode", port)

        ' Wait for selection
        selectedMode = ""
        while selectedMode = ""
            msg = wait(0, port)
            if type(msg) = "roSGScreenEvent"
                if msg.isScreenClosed() then return
            else if type(msg) = "roSGNodeEvent"
                field = msg.getField()
                if field = "selectedMode"
                    value = msg.getData()
                    if value <> "" and value <> invalid
                        selectedMode = value
                    end if
                end if
            end if
        end while

        ' Switch to main scene with selected mode
        scene = screen.createScene("MainScene")
        screen.show()
        scene.observeField("goHome", port)
        scene.viewMode = selectedMode

        ' Wait until user backs out to home
        while true
            msg = wait(0, port)
            if type(msg) = "roSGScreenEvent"
                if msg.isScreenClosed() then return
            else if type(msg) = "roSGNodeEvent"
                field = msg.getField()
                if field = "goHome" and msg.getData() = true
                    exit while
                end if
            end if
        end while
    end while
end sub
