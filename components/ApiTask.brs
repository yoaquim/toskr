sub init()
    m.top.functionName = "fetchData"
end sub

sub fetchData()
    http = createObject("roUrlTransfer")
    http.setUrl(m.top.requestUrl)
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    http.initClientCertificates()
    http.enableEncodings(true)
    response = http.getToString()
    m.top.responseData = response
end sub
