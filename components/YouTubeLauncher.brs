sub init()
    m.top.functionName = "launchYouTube"
end sub

sub launchYouTube()
    videoId = m.top.videoId
    if videoId = "" then return

    ' Launch YouTube app (channel ID 837) via Roku ECP
    http = createObject("roUrlTransfer")
    http.setUrl("http://127.0.0.1:8060/launch/837?contentId=" + videoId + "&mediaType=live")
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    http.initClientCertificates()
    http.postFromString("")

    m.top.launched = true
end sub
