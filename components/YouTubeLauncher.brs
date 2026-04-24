sub init()
    m.top.functionName = "launchYouTube"
end sub

sub launchYouTube()
    videoId = m.top.videoId
    if videoId = "" then return

    ' Launch YouTube app via Roku ECP on localhost
    ' YouTube channel ID on Roku is typically 837
    url = "http://localhost:8060/launch/837?contentId=" + videoId + "&mediaType=live"

    http = createObject("roUrlTransfer")
    port = createObject("roMessagePort")
    http.setMessagePort(port)
    http.setUrl(url)

    ' Try POST first (standard ECP)
    if http.asyncPostFromString("")
        msg = wait(5000, port)
        if msg <> invalid
            code = msg.getResponseCode()
            print "YouTube launch response: "; code
            if code = 200 or code = 204
                m.top.launched = true
                return
            end if
        end if
    end if

    ' Fallback: try with IP instead of localhost
    url = "http://127.0.0.1:8060/launch/837?contentId=" + videoId + "&mediaType=live"
    http2 = createObject("roUrlTransfer")
    http2.setMessagePort(port)
    http2.setUrl(url)

    if http2.asyncPostFromString("")
        msg = wait(5000, port)
        if msg <> invalid
            code = msg.getResponseCode()
            print "YouTube launch fallback response: "; code
            if code = 200 or code = 204
                m.top.launched = true
            end if
        end if
    end if
end sub
