sub init()
    ' UI nodes
    m.browseUI = m.top.findNode("browseUI")
    m.searchIndicator = m.top.findNode("searchIndicator")
    m.navList = m.top.findNode("navList")
    m.channelList = m.top.findNode("channelList")
    m.channelHeader = m.top.findNode("channelHeader")
    m.channelCount = m.top.findNode("channelCount")
    m.channelInfo = m.top.findNode("channelInfo")
    m.infoName = m.top.findNode("infoName")
    m.infoLang = m.top.findNode("infoLang")
    m.infoFav = m.top.findNode("infoFav")
    m.infoStreams = m.top.findNode("infoStreams")
    m.infoFavIcon = m.top.findNode("infoFavIcon")
    m.emptyText = m.top.findNode("emptyText")
    m.player = m.top.findNode("player")
    m.overlayGroup = m.top.findNode("overlayGroup")
    m.overlayTitle = m.top.findNode("overlayTitle")
    m.overlayChannelList = m.top.findNode("overlayChannelList")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.loadingText = m.top.findNode("loadingText")
    m.hintsNav = m.top.findNode("hintsNav")
    m.hintsChannel = m.top.findNode("hintsChannel")
    m.radioDisplay = m.top.findNode("radioDisplay")
    m.radioStationName = m.top.findNode("radioStationName")

    ' State
    m.viewMode = ""
    m.focusedPanel = "left"
    m.state = "browsing"
    m.searchQuery = ""
    m.languageFilter = ""  ' e.g. "eng", "spa", "" = all
    m.selectedNavCode = ""
    m.currentPlayingIndex = -1
    m.overlayVisible = false
    m.overlayState = ""  ' "nav" or "channels"
    m.overlaySavedIndex = -1
    m.overlayNavSavedIndex = -1

    ' Data
    m.navCodes = []
    m.navNames = {}
    m.displayedNavCodes = []
    m.allChannelData = []
    m.displayedChannelData = []
    m.favorites = loadFavorites()

    ' Category list for surf mode
    m.categoryNames = ["Animation", "Auto", "Business", "Classic", "Comedy", "Cooking",
                        "Culture", "Documentary", "Education", "Entertainment", "Family",
                        "General", "Kids", "Legislative", "Lifestyle", "Movies", "Music",
                        "News", "Outdoor", "Public", "Relax", "Religious", "Science",
                        "Series", "Shop", "Show", "Sports", "Top News", "Travel", "Weather"]
    m.categoryCodes = ["animation", "auto", "business", "classic", "comedy", "cooking",
                        "culture", "documentary", "education", "entertainment", "family",
                        "general", "kids", "legislative", "lifestyle", "movies", "music",
                        "news", "outdoor", "public", "relax", "religious", "science",
                        "series", "shop", "show", "sports", "top-news", "travel", "weather"]

    ' Observers
    m.navList.observeField("itemSelected", "onNavSelected")
    m.channelList.observeField("itemFocused", "onChannelFocused")
    m.channelList.observeField("itemSelected", "onChannelSelected")
    m.overlayChannelList.observeField("itemSelected", "onOverlayItemSelected")
    m.player.observeField("state", "onPlayerStateChange")
end sub

' Called when viewMode is set from main.brs
sub onViewModeSet()
    m.viewMode = m.top.viewMode
    if m.viewMode = "country"
        fetchCountries()
    else if m.viewMode = "radio"
        fetchRadioCountries()
    else if m.viewMode = "surf"
        loadSurfCategories()
    else if m.viewMode = "favorites"
        loadFavoritesView()
    end if
end sub

' ===== FAVORITES PERSISTENCE =====

function loadFavorites() as object
    sec = createObject("roRegistrySection", "toskr")
    raw = sec.read("favorites")
    if raw = "" then return {}
    data = parseJSON(raw)
    if data = invalid then return {}
    return data
end function

sub saveFavorites()
    sec = createObject("roRegistrySection", "toskr")
    sec.write("favorites", formatJSON(m.favorites))
    sec.flush()
end sub

function isFavorite(nanoid as string) as boolean
    return m.favorites.doesExist(nanoid)
end function

sub toggleFavorite(index as integer)
    if index < 0 or index >= m.displayedChannelData.count() then return

    channel = m.displayedChannelData[index]
    nanoid = channel.nanoid

    if isFavorite(nanoid)
        m.favorites.delete(nanoid)
    else
        entry = {}
        entry.name = channel.name
        entry.urls = channel.stream_urls
        entry.country = channel.country
        if channel.languages <> invalid and channel.languages.count() > 0
            entry.lang = channel.languages[0]
        end if
        m.favorites[nanoid] = entry
    end if

    saveFavorites()

    channelPos = m.channelList.itemFocused
    navPos = m.navList.itemFocused

    buildChannelContent()
    if m.viewMode <> "favorites"
        buildNavContent()
        m.navList.jumpToItem = navPos
    end if

    m.channelList.jumpToItem = channelPos
    updateChannelInfo(index)
end sub

' ===== COUNTRY MODE =====

sub fetchCountries()
    showLoading("Loading countries...")

    task = createObject("roSGNode", "ApiTask")
    task.requestUrl = "https://raw.githubusercontent.com/famelack/famelack-data/main/tv/raw/countries_metadata.json"
    task.observeField("responseData", "onCountriesResponse")
    task.control = "run"
    m.apiTask = task
end sub

sub onCountriesResponse()
    hideLoading()
    raw = m.apiTask.responseData
    data = parseJSON(raw)

    if data = invalid
        m.channelHeader.text = "Failed to load"
        return
    end if

    m.navCodes = []
    m.navNames = {}

    for each code in data
        country = data[code]
        if country.hasChannels = true
            m.navCodes.push(code)
            m.navNames[code] = country.country
        end if
    end for

    sortNavCodes()
    buildNavContent()
    m.navList.setFocus(true)
    m.state = "browsing"
    m.emptyText.text = "Select a country to browse channels"
    updateHints()
end sub

' ===== RADIO MODE =====

sub fetchRadioCountries()
    showLoading("Loading radio countries...")

    task = createObject("roSGNode", "ApiTask")
    task.requestUrl = "https://raw.githubusercontent.com/famelack/famelack-data/main/radio/raw/countries_metadata.json"
    task.observeField("responseData", "onRadioCountriesResponse")
    task.control = "run"
    m.apiTask = task
end sub

sub onRadioCountriesResponse()
    hideLoading()
    raw = m.apiTask.responseData
    data = parseJSON(raw)

    if data = invalid
        m.channelHeader.text = "Failed to load"
        return
    end if

    m.navCodes = []
    m.navNames = {}

    for each code in data
        country = data[code]
        if country.hasChannels = true
            m.navCodes.push(code)
            m.navNames[code] = country.country
        end if
    end for

    sortNavCodes()
    buildNavContent()
    m.navList.setFocus(true)
    m.state = "browsing"
    m.emptyText.text = "Select a country to browse radio stations"
    updateHints()
end sub

sub sortNavCodes()
    codes = m.navCodes
    for i = 1 to codes.count() - 1
        j = i
        while j > 0 and lcase(m.navNames[codes[j]]) < lcase(m.navNames[codes[j - 1]])
            temp = codes[j]
            codes[j] = codes[j - 1]
            codes[j - 1] = temp
            j = j - 1
        end while
    end for
    m.navCodes = codes
end sub

' ===== SURF MODE =====

sub loadSurfCategories()
    m.navCodes = []
    m.navNames = {}

    for i = 0 to m.categoryCodes.count() - 1
        code = m.categoryCodes[i]
        m.navCodes.push(code)
        m.navNames[code] = m.categoryNames[i]
    end for

    buildNavContent()
    m.navList.setFocus(true)
    m.state = "browsing"
    m.emptyText.text = "Select a category to browse channels"
    updateHints()
end sub

' ===== FAVORITES MODE =====

sub loadFavoritesView()
    ' No left panel needed — go straight to channels
    m.navList.visible = false
    m.focusedPanel = "right"
    showFavoritesChannels()
end sub

sub showFavoritesChannels()
    m.allChannelData = []
    for each nanoid in m.favorites
        fav = m.favorites[nanoid]
        channel = {}
        channel.nanoid = nanoid
        channel.name = fav.name
        channel.stream_urls = fav.urls
        channel.country = fav.country
        channel.languages = []
        if fav.lang <> invalid
            channel.languages = [fav.lang]
        end if
        m.allChannelData.push(channel)
    end for

    m.channelHeader.text = "My Favorites"

    if m.allChannelData.count() = 0
        m.channelCount.text = ""
        m.channelList.visible = false
        m.channelInfo.visible = false
        m.emptyText.text = "No favorites yet. Add channels from Country or Surf."
        m.emptyText.visible = true
        m.top.setFocus(true)
        m.state = "browsing"
        updateHints()
        return
    end if

    applyChannelFilter()
    m.channelList.visible = true
    m.channelInfo.visible = true
    m.emptyText.visible = false
    m.channelList.setFocus(true)
    m.state = "browsing"
    updateHints()
end sub

' ===== CHANNEL FETCHING (shared by country + surf) =====

sub fetchChannels(code as string)
    m.channelList.visible = false
    m.channelInfo.visible = false
    m.emptyText.visible = false
    m.selectedNavCode = code

    if m.navNames.doesExist(code)
        m.channelHeader.text = m.navNames[code]
    else
        m.channelHeader.text = ucase(code)
    end if
    m.channelCount.text = "Loading..."

    if m.viewMode = "radio"
        baseUrl = "https://raw.githubusercontent.com/famelack/famelack-data/main/radio/raw/"
    else
        baseUrl = "https://raw.githubusercontent.com/famelack/famelack-data/main/tv/raw/"
    end if
    if m.viewMode = "surf"
        url = baseUrl + "categories/" + lcase(code) + ".json"
    else
        url = baseUrl + "countries/" + lcase(code) + ".json"
    end if

    task = createObject("roSGNode", "ApiTask")
    task.requestUrl = url
    task.observeField("responseData", "onChannelsResponse")
    task.control = "run"
    m.channelTask = task
end sub

sub onChannelsResponse()
    raw = m.channelTask.responseData
    data = parseJSON(raw)

    if data = invalid
        m.channelCount.text = "Failed to load"
        m.emptyText.text = "Error loading channels"
        m.emptyText.visible = true
        return
    end if

    m.allChannelData = []
    for each channel in data
        hasStreams = (channel.stream_urls <> invalid and channel.stream_urls.count() > 0)
        hasYoutube = (channel.youtube_urls <> invalid and channel.youtube_urls.count() > 0)
        if hasStreams or hasYoutube
            m.allChannelData.push(channel)
        end if
    end for

    applyChannelFilter()
    m.channelList.visible = true
    m.channelInfo.visible = true
    m.emptyText.visible = false
    focusChannelPanel()
end sub

' ===== NAV LIST BUILDING =====

sub buildNavContent()
    content = createObject("roSGNode", "ContentNode")
    m.displayedNavCodes = []

    ' Search item
    searchItem = content.createChild("ContentNode")
    if m.searchQuery <> ""
        searchItem.title = "Search: " + m.searchQuery
    else
        searchItem.title = "Search..."
    end if
    searchItem.description = "SEARCH"
    m.displayedNavCodes.push("SEARCH")

    ' Language filter item
    langItem = content.createChild("ContentNode")
    if m.languageFilter <> ""
        langItem.title = "Language: " + ucase(m.languageFilter)
    else
        langItem.title = "Language: ALL"
    end if
    langItem.description = "LANGUAGE"
    m.displayedNavCodes.push("LANGUAGE")

    ' Favorites shortcut (in country/surf modes)
    favCount = 0
    for each k in m.favorites
        favCount = favCount + 1
    end for
    favItem = content.createChild("ContentNode")
    favItem.title = "Favorites (" + str(favCount).trim() + ")"
    favItem.description = "FAVORITES"
    m.displayedNavCodes.push("FAVORITES")

    ' Nav items (filtered by search)
    for each code in m.navCodes
        name = m.navNames[code]
        if m.searchQuery = "" or fuzzyMatch(m.searchQuery, name) > 0
            item = content.createChild("ContentNode")
            item.title = name
            item.description = code
            m.displayedNavCodes.push(code)
        end if
    end for

    m.navList.content = content
end sub

sub buildChannelContent()
    content = createObject("roSGNode", "ContentNode")

    for each channel in m.displayedChannelData
        item = content.createChild("ContentNode")
        item.title = channelDisplayName(channel)
        if isFavorite(channel.nanoid)
            item.description = "fav"
        else if isYouTubeOnly(channel)
            item.description = "yt"
        else
            item.description = ""
        end if
    end for

    m.channelList.content = content
    m.channelCount.text = str(m.displayedChannelData.count()).trim() + " channels"
end sub

function channelDisplayName(channel as object) as string
    name = channel.name
    if isYouTubeOnly(channel)
        name = "[YT] " + name
    else if channel.languages <> invalid and channel.languages.count() > 0
        name = "[" + ucase(channel.languages[0]) + "] " + name
    end if
    return name
end function

function isYouTubeOnly(channel as object) as boolean
    hasStreams = (channel.stream_urls <> invalid and channel.stream_urls.count() > 0)
    hasYoutube = (channel.youtube_urls <> invalid and channel.youtube_urls.count() > 0)
    return (not hasStreams) and hasYoutube
end function

function extractYouTubeId(url as string) as string
    ' Extract video ID from youtube embed URL
    ' e.g. https://www.youtube-nocookie.com/embed/VIDEO_ID
    idx = instr(1, url, "/embed/")
    if idx > 0
        return mid(url, idx + 7)
    end if
    idx = instr(1, url, "v=")
    if idx > 0
        return mid(url, idx + 2)
    end if
    return ""
end function

' ===== SEARCH =====

sub openSearch()
    dialog = createObject("roSGNode", "KeyboardDialog")
    if m.viewMode = "surf"
        dialog.title = "Search Categories & Channels"
    else
        dialog.title = "Search Countries & Channels"
    end if
    if m.searchQuery <> ""
        dialog.text = m.searchQuery
    end if
    dialog.buttons = ["Search", "Clear", "Cancel"]
    dialog.observeField("buttonSelected", "onSearchButton")
    m.top.dialog = dialog
end sub

sub onSearchButton()
    dialog = m.top.dialog
    buttonIndex = dialog.buttonSelected

    if buttonIndex = 0
        query = dialog.text
        if len(query) > 0
            m.searchQuery = query
        end if
    else if buttonIndex = 1
        m.searchQuery = ""
    end if

    dialog.close = true
    applySearch()
end sub

sub applySearch()
    if m.viewMode <> "favorites"
        buildNavContent()
    end if
    if m.allChannelData.count() > 0
        applyChannelFilter()
    end if
    if m.searchQuery <> ""
        m.searchIndicator.text = "Searching: " + m.searchQuery
    else
        m.searchIndicator.text = ""
    end if
end sub

sub applyChannelFilter()
    m.displayedChannelData = []
    for each channel in m.allChannelData
        ' Search filter
        matchesSearch = (m.searchQuery = "" or fuzzyMatch(m.searchQuery, channel.name) > 0)
        ' Language filter
        matchesLang = true
        if m.languageFilter <> ""
            matchesLang = false
            if channel.languages <> invalid
                for each lang in channel.languages
                    if lcase(lang) = lcase(m.languageFilter)
                        matchesLang = true
                        exit for
                    end if
                end for
            end if
        end if
        if matchesSearch and matchesLang
            m.displayedChannelData.push(channel)
        end if
    end for
    buildChannelContent()
end sub

' ===== LANGUAGE FILTER =====

sub openLanguageFilter()
    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Filter by Language"
    dialog.message = ["Select a language"]
    dialog.buttons = ["All", "English", "Spanish", "French", "Portuguese", "German", "Arabic", "Chinese", "Japanese", "Korean", "Hindi", "Russian", "Italian", "Cancel"]
    dialog.observeField("buttonSelected", "onLanguageSelected")
    m.top.dialog = dialog
end sub

sub onLanguageSelected()
    dialog = m.top.dialog
    index = dialog.buttonSelected
    langs = ["", "eng", "spa", "fra", "por", "deu", "ara", "zho", "jpn", "kor", "hin", "rus", "ita"]

    if index >= 0 and index < langs.count()
        m.languageFilter = langs[index]
    end if
    ' Last button = Cancel, do nothing

    dialog.close = true

    ' Rebuild nav to show updated language label
    if m.viewMode <> "favorites"
        buildNavContent()
    end if
    ' Re-filter channels if loaded
    if m.allChannelData.count() > 0
        applyChannelFilter()
    end if
end sub

function detectStreamFormat(url as string) as string
    u = lcase(url)
    if instr(1, u, ".m3u8") > 0 then return "hls"
    if instr(1, u, ".mpd") > 0 then return "dash"
    if instr(1, u, ".mp4") > 0 then return "mp4"
    if instr(1, u, ".mp3") > 0 then return "mp3"
    if instr(1, u, ".aac") > 0 then return "aac"
    if instr(1, u, ".ogg") > 0 then return "ogg"
    if instr(1, u, ".flac") > 0 then return "flac"
    ' No clear extension — use mode-appropriate default
    if m.viewMode = "radio" then return "mp3"
    return "hls"
end function

function fuzzyMatch(query as string, target as string) as integer
    q = lcase(query)
    t = lcase(target)
    if len(q) = 0 then return 100
    if instr(1, t, q) > 0 then return 100
    return 0
end function

' ===== INFO PANEL =====

sub onChannelFocused()
    index = m.channelList.itemFocused
    updateChannelInfo(index)
end sub

sub updateChannelInfo(index as integer)
    if index < 0 or index >= m.displayedChannelData.count() then return

    channel = m.displayedChannelData[index]
    m.infoName.text = channel.name

    lang = ""
    if channel.languages <> invalid and channel.languages.count() > 0
        lang = "Language: " + ucase(channel.languages[0])
    end if
    m.infoLang.text = lang

    if isFavorite(channel.nanoid)
        m.infoFavIcon.uri = "pkg:/images/fav_acorn.png"
        m.infoFavIcon.visible = true
        m.infoFav.text = "Favorited"
        m.infoFav.translation = [46, 183]
    else
        m.infoFavIcon.visible = false
        m.infoFav.text = "Press Play to favorite"
        m.infoFav.translation = [20, 183]
    end if

    if isYouTubeOnly(channel)
        m.infoStreams.text = "Opens in YouTube app"
    else
        m.infoStreams.text = str(channel.stream_urls.count()).trim() + " stream(s)"
    end if
end sub

' ===== SELECTION HANDLERS =====

sub onNavSelected()
    index = m.navList.itemSelected
    if index < 0 or index >= m.displayedNavCodes.count() then return

    code = m.displayedNavCodes[index]

    if code = "SEARCH"
        openSearch()
    else if code = "LANGUAGE"
        openLanguageFilter()
    else if code = "FAVORITES"
        showInlineFavorites()
    else
        fetchChannels(code)
    end if
end sub

sub showInlineFavorites()
    ' Show favorites in the right panel (inline, not a mode switch)
    m.allChannelData = []
    for each nanoid in m.favorites
        fav = m.favorites[nanoid]
        channel = {}
        channel.nanoid = nanoid
        channel.name = fav.name
        channel.stream_urls = fav.urls
        channel.country = fav.country
        channel.languages = []
        if fav.lang <> invalid
            channel.languages = [fav.lang]
        end if
        m.allChannelData.push(channel)
    end for

    m.selectedNavCode = "FAVORITES"
    m.channelHeader.text = "My Favorites"

    if m.allChannelData.count() = 0
        m.channelCount.text = ""
        m.channelList.visible = false
        m.channelInfo.visible = false
        m.emptyText.text = "No favorites yet. Press Star on any channel."
        m.emptyText.visible = true
        return
    end if

    applyChannelFilter()
    m.channelList.visible = true
    m.channelInfo.visible = true
    m.emptyText.visible = false
    focusChannelPanel()
end sub

sub onChannelSelected()
    index = m.channelList.itemSelected
    if index < 0 or index >= m.displayedChannelData.count() then return

    channel = m.displayedChannelData[index]
    m.currentPlayingIndex = index

    if isYouTubeOnly(channel)
        launchYouTube(channel)
    else
        urls = channel.stream_urls
        if urls.count() = 0 then return
        m.currentStreamUrls = urls
        m.currentStreamIndex = 0
        playStream(urls[0], channel.name)
    end if
end sub

sub launchYouTube(channel as object)
    url = channel.youtube_urls[0]
    videoId = extractYouTubeId(url)
    if videoId = "" then return

    task = createObject("roSGNode", "YouTubeLauncher")
    task.videoId = videoId
    task.control = "run"
end sub

sub onOverlayItemSelected()
    index = m.overlayChannelList.itemSelected

    if m.overlayState = "nav"
        ' Save nav position before switching to channels
        m.overlayNavSavedIndex = index
        if index < 0 or index >= m.navCodes.count() then return
        code = m.navCodes[index]
        m.selectedNavCode = code
        m.overlayTitle.text = m.navNames[code] + " — Loading..."
        fetchOverlayChannels(code)
    else if m.overlayState = "channels"
        ' Selected a channel
        if index < 0 or index >= m.displayedChannelData.count() then return
        channel = m.displayedChannelData[index]
        m.currentPlayingIndex = index

        if isYouTubeOnly(channel)
            hideOverlay()
            launchYouTube(channel)
        else
            urls = channel.stream_urls
            if urls.count() = 0 then return

            m.currentStreamUrls = urls
            m.currentStreamIndex = 0

            videoContent = createObject("roSGNode", "ContentNode")
            videoContent.url = urls[0]
            videoContent.title = channel.name
            videoContent.streamFormat = detectStreamFormat(videoContent.url)
            m.player.content = videoContent
            m.player.control = "play"

            if m.navNames.doesExist(m.selectedNavCode)
                m.overlayTitle.text = m.navNames[m.selectedNavCode]
            end if
        end if
    end if
end sub

sub fetchOverlayChannels(code as string)
    if m.viewMode = "radio"
        baseUrl = "https://raw.githubusercontent.com/famelack/famelack-data/main/radio/raw/"
    else
        baseUrl = "https://raw.githubusercontent.com/famelack/famelack-data/main/tv/raw/"
    end if
    if m.viewMode = "surf"
        url = baseUrl + "categories/" + lcase(code) + ".json"
    else
        url = baseUrl + "countries/" + lcase(code) + ".json"
    end if

    task = createObject("roSGNode", "ApiTask")
    task.requestUrl = url
    task.observeField("responseData", "onOverlayChannelsResponse")
    task.control = "run"
    m.overlayTask = task
end sub

sub onOverlayChannelsResponse()
    raw = m.overlayTask.responseData
    data = parseJSON(raw)

    if data = invalid
        m.overlayTitle.text = "Failed to load"
        return
    end if

    m.allChannelData = []
    for each channel in data
        hasStreams = (channel.stream_urls <> invalid and channel.stream_urls.count() > 0)
        hasYoutube = (channel.youtube_urls <> invalid and channel.youtube_urls.count() > 0)
        if hasStreams or hasYoutube
            m.allChannelData.push(channel)
        end if
    end for

    m.displayedChannelData = m.allChannelData
    showOverlayChannels()
end sub

' ===== PANEL FOCUS =====

sub focusNavPanel()
    m.focusedPanel = "left"
    m.navList.setFocus(true)
    updateHints()
end sub

sub focusChannelPanel()
    if m.channelList.visible = false
        ' Nothing to focus in right panel — keep focus somewhere
        if m.viewMode = "favorites"
            m.focusedPanel = "right"
            m.top.setFocus(true)
        end if
        updateHints()
        return
    end if
    m.focusedPanel = "right"
    m.channelList.setFocus(true)
    updateHints()
end sub

' ===== VIDEO PLAYBACK =====

sub playStream(url as string, channelTitle as string)
    videoContent = createObject("roSGNode", "ContentNode")
    videoContent.url = url
    videoContent.title = channelTitle
    videoContent.streamFormat = detectStreamFormat(videoContent.url)

    m.player.content = videoContent
    m.player.visible = true
    m.player.control = "play"
    m.top.setFocus(true)

    m.browseUI.visible = false
    m.state = "playing"

    ' Show radio display for audio-only streams
    if m.viewMode = "radio"
        m.radioDisplay.visible = true
        m.radioStationName.text = channelTitle

        ' Start a buffering timeout for radio (10 seconds)
        if m.bufferTimer = invalid
            m.bufferTimer = createObject("roSGNode", "Timer")
            m.bufferTimer.duration = 10
            m.bufferTimer.repeat = false
            m.bufferTimer.observeField("fire", "onBufferTimeout")
        end if
        m.bufferTimer.control = "start"
    else
        m.radioDisplay.visible = false
        if m.bufferTimer <> invalid
            m.bufferTimer.control = "stop"
        end if
    end if
end sub

sub onBufferTimeout()
    ' If still buffering after timeout, try next URL or give up
    if m.state = "playing" and m.player.state = "buffering"
        if m.currentStreamIndex < m.currentStreamUrls.count() - 1
            m.currentStreamIndex = m.currentStreamIndex + 1
            nextUrl = m.currentStreamUrls[m.currentStreamIndex]
            videoContent = createObject("roSGNode", "ContentNode")
            videoContent.url = nextUrl
            videoContent.title = m.player.content.title
            videoContent.streamFormat = detectStreamFormat(nextUrl)
            m.player.content = videoContent
            m.player.control = "play"
            ' Restart timer for next attempt
            m.bufferTimer.control = "start"
        else
            ' All URLs timed out
            if m.overlayVisible
                m.overlayTitle.text = "Station unavailable"
            else
                showOverlay()
                m.overlayTitle.text = "Station unavailable — choose another"
            end if
        end if
    end if
end sub

sub onPlayerStateChange()
    playerState = m.player.state

    ' Cancel buffer timer if stream started playing
    if playerState = "playing" and m.bufferTimer <> invalid
        m.bufferTimer.control = "stop"
    end if

    if playerState = "error"
        if m.currentStreamIndex < m.currentStreamUrls.count() - 1
            ' Try next stream URL
            m.currentStreamIndex = m.currentStreamIndex + 1
            nextUrl = m.currentStreamUrls[m.currentStreamIndex]
            videoContent = createObject("roSGNode", "ContentNode")
            videoContent.url = nextUrl
            videoContent.title = m.player.content.title
            videoContent.streamFormat = detectStreamFormat(videoContent.url)
            m.player.content = videoContent
            m.player.control = "play"
        else
            ' All URLs failed — show overlay with error, don't flicker
            if m.overlayVisible
                m.overlayTitle.text = m.overlayTitle.text + " (stream unavailable)"
            else
                showOverlay()
                m.overlayTitle.text = "Stream unavailable — choose another"
            end if
        end if
    else if playerState = "finished"
        ' Live streams shouldn't finish, but handle gracefully
        if m.overlayVisible
            ' Already browsing overlay, do nothing
        else
            showOverlay()
            m.overlayTitle.text = "Stream ended — choose another"
        end if
    end if
end sub

sub stopPlayer()
    m.player.control = "stop"
    m.player.visible = false
    m.radioDisplay.visible = false
    m.browseUI.visible = true
    m.overlayGroup.visible = false
    m.overlayVisible = false
    m.state = "browsing"

    if m.channelList.visible
        focusChannelPanel()
    else if m.navList.visible
        focusNavPanel()
    else
        ' Favorites mode with no visible list — ensure focus for back key
        m.top.setFocus(true)
    end if
end sub

' ===== OVERLAY =====

sub showOverlay()
    m.overlayGroup.visible = true
    m.overlayVisible = true

    ' Restore previous overlay state and position if available
    if m.overlayState = "channels" and m.displayedChannelData.count() > 0
        showOverlayChannels()
        if m.overlaySavedIndex >= 0
            m.overlayChannelList.jumpToItem = m.overlaySavedIndex
        end if
    else if m.overlayState = "nav"
        showOverlayNav()
        if m.overlaySavedIndex >= 0
            m.overlayChannelList.jumpToItem = m.overlaySavedIndex
        end if
    else if m.displayedChannelData.count() > 0
        showOverlayChannels()
    else
        showOverlayNav()
    end if
end sub

sub showOverlayNav()
    ' Show countries/categories in the overlay
    m.overlayState = "nav"
    content = createObject("roSGNode", "ContentNode")

    for each code in m.navCodes
        name = m.navNames[code]
        item = content.createChild("ContentNode")
        item.title = name
        item.description = code
    end for

    m.overlayChannelList.content = content

    if m.viewMode = "country"
        m.overlayTitle.text = "Countries"
    else if m.viewMode = "surf"
        m.overlayTitle.text = "Categories"
    else
        m.overlayTitle.text = "Browse"
    end if

    m.overlayChannelList.setFocus(true)

    ' Restore saved nav position
    if m.overlayNavSavedIndex >= 0
        m.overlayChannelList.jumpToItem = m.overlayNavSavedIndex
    end if
end sub

sub showOverlayChannels()
    ' Show channels for current selection in the overlay
    m.overlayState = "channels"
    content = createObject("roSGNode", "ContentNode")

    for each channel in m.displayedChannelData
        item = content.createChild("ContentNode")
        item.title = channelDisplayName(channel)
        if isFavorite(channel.nanoid)
            item.description = "fav"
        else if isYouTubeOnly(channel)
            item.description = "yt"
        else
            item.description = ""
        end if
    end for

    m.overlayChannelList.content = content

    if m.selectedNavCode <> "" and m.navNames.doesExist(m.selectedNavCode)
        m.overlayTitle.text = m.navNames[m.selectedNavCode]
    else if m.selectedNavCode = "FAVORITES"
        m.overlayTitle.text = "My Favorites"
    else
        m.overlayTitle.text = m.channelHeader.text
    end if

    m.overlayChannelList.setFocus(true)

    if m.currentPlayingIndex >= 0
        m.overlayChannelList.jumpToItem = m.currentPlayingIndex
    end if
end sub

sub hideOverlay()
    ' Save position before hiding
    m.overlaySavedIndex = m.overlayChannelList.itemFocused
    m.overlayGroup.visible = false
    m.overlayVisible = false
    ' Keep m.overlayState so we can restore on re-open
    m.top.setFocus(true)
end sub

' ===== UI HELPERS =====

sub showLoading(msg as string)
    m.loadingGroup.visible = true
    m.loadingText.text = msg
end sub

sub hideLoading()
    m.loadingGroup.visible = false
end sub

sub updateHints()
    showChannelHints = (m.viewMode = "favorites" or m.focusedPanel = "right")
    m.hintsNav.visible = not showChannelHints
    m.hintsChannel.visible = showChannelHints
end sub

' ===== KEY HANDLING =====

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    ' --- OVERLAY MODE ---
    if m.overlayVisible
        if key = "right"
            hideOverlay()
            return true
        else if key = "back"
            if m.overlayState = "channels"
                ' Back from channels → show nav list
                showOverlayNav()
                return true
            else
                ' Back from nav → dismiss overlay
                hideOverlay()
                return true
            end if
        else if key = "left"
            if m.overlayState = "channels"
                ' Left from channels → back to nav
                showOverlayNav()
                return true
            end if
            return true
        else if key = "play"
            if m.overlayState = "channels"
                index = m.overlayChannelList.itemFocused
                if index >= 0 and index < m.displayedChannelData.count()
                    toggleFavorite(index)
                    showOverlayChannels()
                end if
            end if
            return true
        end if
        return false
    end if

    ' --- PLAYING MODE (no overlay) ---
    if m.state = "playing"
        if key = "back" or (key = "OK" and m.viewMode = "radio")
            stopPlayer()
            return true
        else if key = "left"
            showOverlay()
            return true
        else if key = "play"
            toggleFavorite(m.currentPlayingIndex)
            return true
        end if
        return false
    end if

    ' --- BROWSING MODE ---
    if key = "back"
        if m.searchQuery <> ""
            m.searchQuery = ""
            applySearch()
            return true
        else if m.focusedPanel = "right"
            if m.viewMode = "favorites"
                m.top.goHome = true
                return true
            end if
            focusNavPanel()
            return true
        else
            m.top.goHome = true
            return true
        end if
    else if key = "right"
        if m.focusedPanel = "left" and m.channelList.visible
            focusChannelPanel()
            return true
        end if
    else if key = "left"
        if m.focusedPanel = "right"
            if m.viewMode = "favorites"
                return true
            end if
            focusNavPanel()
            return true
        else if m.focusedPanel = "left"
            m.navList.jumpToItem = 1
            return true
        end if
    else if key = "play"
        ' Play button = toggle favorite on channel list, or select on nav list
        if m.focusedPanel = "right" and m.channelList.visible
            index = m.channelList.itemFocused
            toggleFavorite(index)
            return true
        else if m.focusedPanel = "left"
            onNavSelected()
            return true
        end if
    else if key = "replay"
        openSearch()
        return true
    end if

    return false
end function
