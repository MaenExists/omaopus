import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "maen.omaopus"
  ipcTarget: "maen.omaopus"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property color muted: Qt.darker(foreground, 1.85)
  readonly property color accent: Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string backendPath: Qt.resolvedUrl("oma-player").toString().replace(/^file:\/\//, "")
  readonly property string statusPath: Quickshell.env("XDG_STATE_HOME", Quickshell.env("HOME") + "/.local/state") + "/omaopus/status.json"

  // Player State
  property bool isPlaying: false
  property bool isPaused: false
  property bool isBusy: false
  property string currentTitle: ""
  property string currentArtist: ""
  property string currentUrl: ""
  property int currentPositionSec: 0
  property int totalDurationSec: 0
  property int volume: 70

  // Tabs: "search" | "queue" | "favorites"
  property string activeTab: "search"

  // Search State
  property var searchResults: []
  property bool isSearching: false
  property string lastQuery: ""

  // Queue State
  property var queueTracks: []
  property int queueIndex: -1

  // Favorites State
  property var favorites: []

  function playSound(name) {
    soundProc.command = [root.backendPath, "sound", name]
    soundProc.running = true
  }

  function refreshStatus() {
    if (statusProc.running) return
    statusProc.running = true
  }

  function refreshQueue() {
    if (queueProc.running) return
    queueProc.running = true
  }

  function refreshFavorites() {
    if (favProc.running) return
    favProc.running = true
  }

  function togglePlayPause() {
    isBusy = true
    execAction("toggle")
  }

  function nextTrack() {
    isBusy = true
    execAction("next")
  }

  function prevTrack() {
    isBusy = true
    execAction("prev")
  }

  function playTrack(item) {
    if (!item || !item.url) return
    isBusy = true
    currentTitle = item.title || "Loading..."
    currentArtist = item.artist || ""
    currentUrl = item.url
    isPlaying = true
    isPaused = false
    actionProc.command = [root.backendPath, "play-url", item.url, item.title || "", item.artist || "", item.duration || ""]
    actionProc.running = true
  }

  function queueTrack(item) {
    if (!item || !item.url) return
    isBusy = true
    actionProc.command = [root.backendPath, "queue-url", item.url, item.title || "", item.artist || "", item.duration || ""]
    actionProc.running = true
    Qt.callLater(root.refreshQueue)
  }

  function clearQueue() {
    execAction("queue-clear")
    queueTracks = []
    queueIndex = -1
  }

  function restartSession() {
    isBusy = true
    currentTitle = ""
    currentArtist = ""
    isPlaying = false
    isPaused = false
    execAction("restart-session")
    root.refreshQueue()
    root.refreshFavorites()
  }

  function toggleFavorite(item) {
    if (!item) return
    var jsonStr = JSON.stringify(item)
    favToggleProc.command = [root.backendPath, "favorites-toggle", jsonStr]
    favToggleProc.running = true
  }

  function isTrackFavorite(item) {
    if (!item) return false
    var key = item.id || item.url || ""
    for (var i = 0; i < favorites.length; i++) {
      if ((favorites[i].id || favorites[i].url) === key) return true
    }
    return false
  }

  function setVolume(pct) {
    volume = Math.max(0, Math.min(100, Math.round(pct)))
    execActionWithArg("volume", String(volume))
  }

  function startSearch(query) {
    var trimmed = (query || "").trim()
    if (!trimmed || trimmed === lastQuery) return
    lastQuery = trimmed
    isSearching = true
    searchProc.query = trimmed
    searchProc.running = true
  }

  function execAction(action) {
    actionProc.command = [root.backendPath, action]
    actionProc.running = true
  }

  function execActionWithArg(action, arg) {
    actionProc.command = [root.backendPath, action, arg]
    actionProc.running = true
  }

  function parseStatus(raw) {
    try {
      if (!raw || typeof raw !== "string") return
      var data = JSON.parse(raw)
      root.isPlaying = data.state === "playing"
      root.isPaused = data.state === "paused"
      root.isBusy = false

      if (data.track) {
        root.currentTitle = data.track.title || ""
        root.currentArtist = data.track.artist || ""
        root.currentUrl = data.track.path || data.track.url || ""
      }

      if (data.duration) {
        root.totalDurationSec = Math.round(data.duration)
      }
      if (data.position !== undefined) {
        root.currentPositionSec = Math.round(data.position)
      }
      if (data.volume !== undefined) {
        root.volume = Math.round(data.volume)
      }
    } catch (e) {
      // Ignored
    }
  }

  function formatTime(secs) {
    if (!secs || secs < 0) return "0:00"
    var m = Math.floor(secs / 60)
    var s = Math.floor(secs % 60)
    return m + ":" + (s < 10 ? "0" : "") + s
  }

  visible: true
  implicitWidth: iconContainer.width
  implicitHeight: bar ? bar.barSize : Style.bar.sizeHorizontal

  // Periodic polling for status
  Timer {
    interval: root.opened ? 1200 : (root.isPlaying ? 2500 : 7000)
    running: true
    repeat: true
    onTriggered: {
      root.refreshStatus()
      if (root.opened) {
        if (root.activeTab === "queue") root.refreshQueue()
        if (root.activeTab === "favorites") root.refreshFavorites()
      }
    }
  }

  // File watcher for status file
  FileView {
    path: root.statusPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.parseStatus(text())
    onFileChanged: reload()
  }

  Process {
    id: statusProc
    command: [root.backendPath, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onTextChanged: if (text) root.parseStatus(text)
    }
  }

  Process {
    id: actionProc
    command: []
    onExited: root.refreshStatus()
  }

  Process {
    id: soundProc
    command: []
  }

  Process {
    id: queueProc
    command: [root.backendPath, "queue-list"]
    stdout: StdioCollector {
      id: queueOut
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode === 0 && queueOut.text) {
        try {
          var parsed = JSON.parse(queueOut.text)
          root.queueTracks = parsed.tracks || []
          root.queueIndex = parsed.currentIndex !== undefined ? parsed.currentIndex : -1
        } catch (e) {
          root.queueTracks = []
        }
      }
    }
  }

  Process {
    id: favProc
    command: [root.backendPath, "favorites-list"]
    stdout: StdioCollector {
      id: favOut
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode === 0 && favOut.text) {
        try {
          root.favorites = JSON.parse(favOut.text) || []
        } catch (e) {
          root.favorites = []
        }
      }
    }
  }

  Process {
    id: favToggleProc
    command: []
    stdout: StdioCollector {
      id: favToggleOut
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode === 0 && favToggleOut.text) {
        try {
          root.favorites = JSON.parse(favToggleOut.text) || []
        } catch (e) {
          // Ignored
        }
      }
    }
  }

  Process {
    id: searchProc
    property string query: ""
    command: [root.backendPath, "search", query, "8"]
    stdout: StdioCollector {
      id: searchOut
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.isSearching = false
      if (exitCode === 0 && searchOut.text) {
        try {
          var parsed = JSON.parse(searchOut.text)
          root.searchResults = parsed.results || []
        } catch (e) {
          root.searchResults = []
        }
      }
    }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function play(): void { root.togglePlayPause() }
    function next(): void { root.nextTrack() }
    function prev(): void { root.prevTrack() }
  }

  // Bar Widget: Icon ONLY (Clean, minimal, hover reveals full song details)
  Item {
    id: iconContainer
    width: Style.bar.statusSlot
    height: Style.bar.statusSlot
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
      id: iconBg
      anchors.fill: parent
      radius: width / 2
      color: root.isPlaying
        ? Style.selectedFillFor(root.foreground, root.accent)
        : (barMouse.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12) : "transparent")
    }

    Text {
      id: iconLabel
      anchors.centerIn: parent
      text: root.isBusy ? "󰑮" : (root.isPlaying ? "󱑽" : "󱑼")
      color: root.isPlaying ? root.accent : (root.bar ? root.bar.barForeground : Color.foreground)
      font.family: root.fontFamily
      font.pixelSize: Style.font.icon

      RotationAnimation on rotation {
        running: root.isBusy || (root.isPlaying && root.activeTab === "search" && root.isSearching)
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 1200
      }
    }

    // Glowing accent indicator when playing
    Rectangle {
      visible: root.isPlaying && !root.isBusy
      width: Style.space(5)
      height: Style.space(5)
      radius: width / 2
      color: root.accent
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.space(1)
      anchors.rightMargin: Style.space(1)
    }

    MouseArea {
      id: barMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor

      onEntered: {
        if (root.bar) {
          var tip = root.isPlaying
            ? (root.currentTitle ? (root.currentTitle + (root.currentArtist ? " — " + root.currentArtist : "")) : "Playing music")
            : (root.isPaused ? "Paused: " + root.currentTitle : "OmaOpus - YouTube Player")
          root.bar.showTooltip(root, tip)
        }
      }
      onExited: {
        if (root.bar) root.bar.hideTooltip(root)
      }

      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          root.togglePlayPause()
        } else {
          root.toggle()
        }
      }
    }
  }

  // Interactive Dropdown Panel
  KeyboardPanel {
    id: panel
    anchorItem: iconContainer
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: searchField
    contentWidth: panel.fittedContentWidth(Style.space(390))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight, Style.space(560))

    Column {
      id: mainColumn
      width: parent.width
      spacing: Style.space(10)
      topPadding: Style.space(12)
      bottomPadding: Style.space(10)
      leftPadding: Style.space(14)
      rightPadding: Style.space(14)

      // Header row with Title, Tab switcher, Restart & Close session buttons
      Row {
        width: parent.width - Style.space(28)
        spacing: Style.space(8)

        Text {
          text: "󱑽 OmaOpus"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          width: parent.width - x - restartBtn.width - closeBtn.width - Style.space(8)
          height: 1
        }

        // Restart Instance/Session Button
        PanelActionButton {
          id: restartBtn
          iconText: "󰑐"
          tooltipText: "Restart Session (clears audio daemon & resets bot limits)"
          anchors.verticalCenter: parent.verticalCenter
          onClicked: root.restartSession()
        }

        // Close dropdown
        PanelActionButton {
          id: closeBtn
          iconText: "󰅖"
          tooltipText: "Close Panel"
          anchors.verticalCenter: parent.verticalCenter
          onClicked: root.close()
        }
      }

      // Tab switcher bar: Search | Queue | Favorites
      Row {
        width: parent.width - Style.space(28)
        spacing: Style.space(6)

        Repeater {
          model: [
            { id: "search", name: "󰍉 Search" },
            { id: "queue", name: "󰒮 Queue (" + root.queueTracks.length + ")" },
            { id: "favorites", name: "󰋑 Favorites (" + root.favorites.length + ")" }
          ]

          Rectangle {
            width: (parent.width - Style.space(12)) / 3
            height: Style.space(28)
            radius: Style.cornerRadius
            color: root.activeTab === modelData.id
              ? Style.selectedFillFor(root.foreground, root.accent)
              : (tabMouse.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08) : "transparent")

            border.color: root.activeTab === modelData.id ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: modelData.name
              color: root.activeTab === modelData.id ? root.foreground : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: root.activeTab === modelData.id
            }

            MouseArea {
              id: tabMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.activeTab = modelData.id
                root.playSound("click")
                if (root.activeTab === "queue") root.refreshQueue()
                if (root.activeTab === "favorites") root.refreshFavorites()
              }
            }
          }
        }
      }

      // Now Playing Hero Card (Visible across all tabs)
      Rectangle {
        width: parent.width - Style.space(28)
        height: root.currentTitle ? Style.space(106) : Style.space(56)
        radius: Style.cornerRadius
        color: Style.selectedFillFor(root.foreground, root.accent)
        clip: true

        Column {
          anchors.fill: parent
          anchors.margins: Style.space(10)
          spacing: Style.space(4)

          // Track Title with Favorite toggle button
          Row {
            width: parent.width
            spacing: Style.space(6)

            Text {
              width: parent.width - (root.currentTitle ? favHeaderBtn.width + Style.space(6) : 0)
              text: root.currentTitle ? root.currentTitle : "No song playing"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              elide: Text.ElideRight
              anchors.verticalCenter: parent.verticalCenter
            }

            PanelActionButton {
              id: favHeaderBtn
              visible: root.currentTitle !== ""
              iconText: root.isTrackFavorite({ id: root.currentUrl, url: root.currentUrl }) ? "󰋑" : "󰋔"
              tooltipText: "Favorite track"
              size: Style.space(22)
              anchors.verticalCenter: parent.verticalCenter
              onClicked: {
                root.toggleFavorite({
                  id: root.currentUrl,
                  title: root.currentTitle,
                  artist: root.currentArtist,
                  url: root.currentUrl,
                  duration: root.formatTime(root.totalDurationSec)
                })
              }
            }
          }

          // Artist & Duration
          Text {
            width: parent.width
            text: root.currentArtist ? (root.currentArtist + (root.totalDurationSec > 0 ? "  ·  " + root.formatTime(root.currentPositionSec) + " / " + root.formatTime(root.totalDurationSec) : "")) : "Search tracks or pick from favorites below"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }

          // Media Controls Row
          Row {
            visible: root.currentTitle !== ""
            spacing: Style.space(14)
            anchors.horizontalCenter: parent.horizontalCenter

            PanelActionButton {
              iconText: "󰒮"
              tooltipText: "Previous"
              onClicked: root.prevTrack()
            }

            PanelActionButton {
              iconText: root.isBusy ? "󰑮" : (root.isPlaying ? "󰏤" : "󰐊")
              tooltipText: root.isPlaying ? "Pause" : "Play"
              onClicked: root.togglePlayPause()
            }

            PanelActionButton {
              iconText: "󰒭"
              tooltipText: "Next"
              onClicked: root.nextTrack()
            }
          }
        }
      }

      // Volume Slider
      Row {
        width: parent.width - Style.space(28)
        spacing: Style.space(8)

        Text {
          text: root.volume === 0 ? "󰝟" : (root.volume < 50 ? "󰕿" : "󰕾")
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          anchors.verticalCenter: parent.verticalCenter
        }

        PanelSlider {
          id: volSlider
          bar: root.bar
          minimum: 0
          maximum: 100
          value: root.volume
          width: parent.width - Style.space(70)
          anchors.verticalCenter: parent.verticalCenter
          onMoved: function(val) { root.setVolume(val) }
        }

        Text {
          text: root.volume + "%"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      PanelSeparator {
        width: parent.width - Style.space(28)
      }

      // TAB 1: SEARCH
      Column {
        visible: root.activeTab === "search"
        width: parent.width
        spacing: Style.space(8)

        // Search Input Row
        Row {
          width: parent.width - Style.space(28)
          spacing: Style.space(8)

          TextField {
            id: searchField
            width: parent.width - searchActionBtn.width - Style.space(8)
            placeholderText: "Search YouTube Music..."
            font.family: root.fontFamily
            font.pixelSize: Style.font.body

            onAccepted: root.startSearch(text)
            Keys.onDownPressed: {
              if (resultsList.count > 0) {
                resultsList.forceActiveFocus()
                resultsList.currentIndex = 0
              }
            }
            Keys.onEscapePressed: root.close()
          }

          PanelActionButton {
            id: searchActionBtn
            iconText: root.isSearching ? "󰑮" : "󰍉"
            tooltipText: "Search"
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.startSearch(searchField.text)
          }
        }

        // Search Results List
        ListView {
          id: resultsList
          width: parent.width - Style.space(28)
          height: Math.min(Style.space(190), Math.max(Style.space(48), count * Style.space(46)))
          clip: true
          model: root.searchResults

          Keys.onUpPressed: {
            if (currentIndex === 0) searchField.forceActiveFocus()
            else currentIndex--
          }
          Keys.onDownPressed: {
            if (currentIndex < count - 1) currentIndex++
          }
          Keys.onReturnPressed: {
            var item = model[currentIndex]
            if (item) root.playTrack(item)
          }
          Keys.onEscapePressed: root.close()

          delegate: Rectangle {
            width: resultsList.width
            height: Style.space(44)
            radius: Style.cornerRadius
            color: resultsList.currentIndex === index
              ? Style.selectedFillFor(root.foreground, root.accent)
              : (mouseArea.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08) : "transparent")

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                resultsList.currentIndex = index
                root.playTrack(modelData)
              }
            }

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(8)
              anchors.rightMargin: Style.space(8)
              spacing: Style.space(8)

              Text {
                text: "󰐊"
                color: resultsList.currentIndex === index ? root.foreground : root.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - queueBtn.width - favRowBtn.width - timeText.width - Style.space(40)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: modelData.title || ""
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: modelData.artist || ""
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              Text {
                id: timeText
                text: modelData.duration || ""
                color: root.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }

              PanelActionButton {
                id: favRowBtn
                iconText: root.isTrackFavorite(modelData) ? "󰋑" : "󰋔"
                tooltipText: "Favorite"
                size: Style.space(24)
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.toggleFavorite(modelData)
              }

              PanelActionButton {
                id: queueBtn
                iconText: "󰐍"
                tooltipText: "Queue Next"
                size: Style.space(24)
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.queueTrack(modelData)
              }
            }
          }
        }

        Text {
          visible: !root.isSearching && root.searchResults.length === 0
          text: "Type a track name above and press Enter."
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          width: parent.width - Style.space(28)
        }
      }

      // TAB 2: QUEUE
      Column {
        visible: root.activeTab === "queue"
        width: parent.width
        spacing: Style.space(8)

        Row {
          width: parent.width - Style.space(28)
          Text {
            text: "NOW PLAYING QUEUE"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
          Item {
            width: parent.width - x - clearQBtn.width
            height: 1
          }
          PanelActionButton {
            id: clearQBtn
            iconText: "󰅖"
            tooltipText: "Clear Queue"
            size: Style.space(22)
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.clearQueue()
          }
        }

        ListView {
          id: queueList
          width: parent.width - Style.space(28)
          height: Math.min(Style.space(190), Math.max(Style.space(48), count * Style.space(46)))
          clip: true
          model: root.queueTracks

          delegate: Rectangle {
            width: queueList.width
            height: Style.space(44)
            radius: Style.cornerRadius
            color: root.queueIndex === index
              ? Style.selectedFillFor(root.foreground, root.accent)
              : (qMouse.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08) : "transparent")

            MouseArea {
              id: qMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.playTrack(modelData)
            }

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(8)
              anchors.rightMargin: Style.space(8)
              spacing: Style.space(8)

              Text {
                text: root.queueIndex === index ? "󰐊" : String(index + 1)
                color: root.queueIndex === index ? root.accent : root.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - Style.space(40)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: modelData.title || ""
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: modelData.artist || ""
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }
            }
          }
        }

        Text {
          visible: root.queueTracks.length === 0
          text: "Queue is empty. Search tracks and click 󰐍 to add."
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          width: parent.width - Style.space(28)
        }
      }

      // TAB 3: FAVORITES
      Column {
        visible: root.activeTab === "favorites"
        width: parent.width
        spacing: Style.space(8)

        ListView {
          id: favList
          width: parent.width - Style.space(28)
          height: Math.min(Style.space(190), Math.max(Style.space(48), count * Style.space(46)))
          clip: true
          model: root.favorites

          delegate: Rectangle {
            width: favList.width
            height: Style.space(44)
            radius: Style.cornerRadius
            color: favMouse.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08) : "transparent"

            MouseArea {
              id: favMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.playTrack(modelData)
            }

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(8)
              anchors.rightMargin: Style.space(8)
              spacing: Style.space(8)

              Text {
                text: "󰋑"
                color: root.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - favDelBtn.width - Style.space(36)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: modelData.title || ""
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: modelData.artist || ""
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              PanelActionButton {
                id: favDelBtn
                iconText: "󰅖"
                tooltipText: "Remove Favorite"
                size: Style.space(22)
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.toggleFavorite(modelData)
              }
            }
          }
        }

        Text {
          visible: root.favorites.length === 0
          text: "No favorites yet. Click the 󰋔 icon on any track to favorite it."
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          width: parent.width - Style.space(28)
        }
      }

      // Minimal Shortcuts Hint Bar at the very bottom
      PanelSeparator {
        width: parent.width - Style.space(28)
      }

      Row {
        width: parent.width - Style.space(28)
        spacing: Style.space(12)
        anchors.horizontalCenter: parent.horizontalCenter

        Text {
          text: "↵ Play"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption * 0.9
        }

        Text {
          text: "↑/↓ Navigate"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption * 0.9
        }

        Text {
          text: "󰍉 Enter to search"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption * 0.9
        }

        Text {
          text: "Esc Close"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption * 0.9
        }
      }
    }
  }

  Component.onCompleted: {
    root.refreshStatus()
    root.refreshFavorites()
  }
}
