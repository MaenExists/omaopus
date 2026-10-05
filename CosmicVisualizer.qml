import QtQuick
import Quickshell.Io

Item {
  id: root

  property bool isPlaying: false
  property bool isPaused: false
  property bool panelOpened: true
  property real volume: 70
  property int colorTheme: 0 // 0: Cyber Neon, 1: Solar Amber, 2: Matrix Emerald, 3: Electric Violet
  property string enginePath: Qt.resolvedUrl("oma-visualizer-engine").toString().replace(/^file:\/\//, "")

  signal themeToggled()

  implicitWidth: 360
  implicitHeight: 82

  readonly property var themeNames: ["CYBER NEON", "SOLAR AMBER", "MATRIX EMERALD", "ELECTRIC VIOLET"]
  readonly property var themeColors: ["#06b6d4", "#f59e0b", "#10b981", "#c084fc"]
  readonly property color activeThemeColor: themeColors[colorTheme % 4]
  readonly property string activeThemeName: themeNames[colorTheme % 4]

  // 32 Frequency Bars Data (Strict 0.0 resting state when idle)
  property var barValues: [
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
  ]
  property var peakValues: [
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
  ]
  property var peakVelocities: [
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
  ]

  property var targetBands: []
  property real currentBass: 0.0
  property real targetBass: 0.0
  property real beatPulse: 0.0
  property real animPhase: 0.0

  function triggerBeat() {
    if (root.isPlaying && !root.isPaused) {
      beatPulse = 1.0
    }
  }

  function feedAudioData(line) {
    if (!line || !root.isPlaying || root.isPaused) return
    try {
      var d = JSON.parse(line)
      if (d.b && d.b.length >= 16) {
        var incoming = d.b
        var full = []
        if (incoming.length >= 32) {
          full = incoming
        } else {
          for (var j = 0; j < 32; j++) {
            var srcIdx = Math.floor((j / 32.0) * incoming.length)
            full.push(incoming[srcIdx] || 0.0)
          }
        }
        targetBands = full
      }
      if (d.bass !== undefined) targetBass = d.bass
      if (d.beat && d.beat > 0.5) triggerBeat()
    } catch (e) {}
  }

  // Real-time audio engine process (runs strictly when music is playing and panel is open)
  Process {
    id: engineProc
    command: [root.enginePath]
    running: root.visible && root.panelOpened && root.isPlaying && !root.isPaused
    stdout: SplitParser {
      onRead: function(line) {
        root.feedAudioData(line)
      }
    }
  }

  // Card Background with Frosted Obsidian Aesthetic & Dynamic Beat Glow
  Rectangle {
    id: bgCard
    anchors.fill: parent
    radius: 10
    color: "#080b13"
    border.color: Qt.rgba(
      root.activeThemeColor.r,
      root.activeThemeColor.g,
      root.activeThemeColor.b,
      root.isPlaying && !root.isPaused ? (0.22 + root.beatPulse * 0.28) : 0.15
    )
    border.width: 1
    clip: true

    // Ambient Bass Luminescence Halo
    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      opacity: (root.isPlaying && !root.isPaused) ? (0.05 + root.beatPulse * 0.15 + root.currentBass * 0.08) : 0.0
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 0.5; color: root.activeThemeColor }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }

    // Top HUD Bar
    Row {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.margins: 7
      spacing: 6

      Text {
        text: "󰓃"
        color: root.activeThemeColor
        font.pixelSize: 10
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: "SPECTRUM ANALYZER"
        color: "#94a3b8"
        font.pixelSize: 8
        font.bold: true
        font.family: "monospace"
        anchors.verticalCenter: parent.verticalCenter
      }

      // Live status dot & label
      Rectangle {
        width: 5
        height: 5
        radius: 2.5
        anchors.verticalCenter: parent.verticalCenter
        color: (root.isPlaying && !root.isPaused)
          ? (root.beatPulse > 0.4 ? "#ffffff" : root.activeThemeColor)
          : (root.isPaused ? "#f59e0b" : "#475569")
      }

      Text {
        text: (root.isPlaying && !root.isPaused) ? "LIVE FFT" : (root.isPaused ? "PAUSED" : "IDLE")
        color: (root.isPlaying && !root.isPaused) ? root.activeThemeColor : (root.isPaused ? "#f59e0b" : "#64748b")
        font.pixelSize: 8
        font.bold: true
        font.family: "monospace"
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    // Interactive Theme Switcher Pill
    Rectangle {
      id: themePill
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 5
      height: 16
      width: themePillRow.width + 12
      radius: 8
      color: themeMouse.containsMouse
        ? Qt.rgba(root.activeThemeColor.r, root.activeThemeColor.g, root.activeThemeColor.b, 0.22)
        : Qt.rgba(root.activeThemeColor.r, root.activeThemeColor.g, root.activeThemeColor.b, 0.10)
      border.color: Qt.rgba(root.activeThemeColor.r, root.activeThemeColor.g, root.activeThemeColor.b, 0.35)
      border.width: 1

      Row {
        id: themePillRow
        anchors.centerIn: parent
        spacing: 4

        Rectangle {
          width: 5
          height: 5
          radius: 2.5
          anchors.verticalCenter: parent.verticalCenter
          color: root.activeThemeColor
        }

        Text {
          text: root.activeThemeName + " // 32B"
          color: root.activeThemeColor
          font.pixelSize: 8
          font.bold: true
          font.family: "monospace"
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      MouseArea {
        id: themeMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.colorTheme = (root.colorTheme + 1) % 4
          root.themeToggled()
        }
      }
    }

    // Baseline grid separator
    Rectangle {
      id: baselineLine
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 14
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      height: 1
      color: Qt.rgba(1.0, 1.0, 1.0, 0.10)
    }

    // 32 Hardware-Accelerated SceneGraph Equalizer Bars
    Row {
      id: barsRow
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: baselineLine.top
      spacing: 2

      Repeater {
        model: 32

        Item {
          id: barItem
          width: Math.max(4, Math.floor((bgCard.width - 24 - 31 * 2) / 32))
          height: 44

          // 1. Peak Hold Floating Cap (Crisp white with gravity decay)
          Rectangle {
            visible: root.isPlaying && !root.isPaused && (root.peakValues[index] || 0.0) > 0.02
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.min(parent.height - 2, Math.max(1, (root.peakValues[index] || 0.0) * (parent.height - 3)))
            width: parent.width
            height: 2
            radius: 1
            color: "#ffffff"
          }

          // 2. Main Equalizer Bar
          Rectangle {
            visible: root.isPlaying && !root.isPaused && (root.barValues[index] || 0.0) > 0.005
            anchors.bottom: parent.bottom
            width: parent.width
            height: Math.min(parent.height, Math.max(0, (root.barValues[index] || 0.0) * parent.height))
            radius: 1.5

            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: root.colorTheme === 1 ? "#fef08a" : (root.colorTheme === 2 ? "#6ee7b7" : (root.colorTheme === 3 ? "#f472b6" : "#f43f5e"))
              }
              GradientStop {
                position: 0.35
                color: root.colorTheme === 1 ? "#f59e0b" : (root.colorTheme === 2 ? "#10b981" : (root.colorTheme === 3 ? "#c084fc" : "#8b5cf6"))
              }
              GradientStop {
                position: 0.70
                color: root.colorTheme === 1 ? "#ea580c" : (root.colorTheme === 2 ? "#059669" : (root.colorTheme === 3 ? "#6366f1" : "#3b82f6"))
              }
              GradientStop {
                position: 1.0
                color: root.colorTheme === 1 ? "#991b1b" : (root.colorTheme === 2 ? "#064e3b" : (root.colorTheme === 3 ? "#1e1b4b" : "#06b6d4"))
              }
            }
          }

          // 3. Glossy Bottom Mirror Reflection
          Rectangle {
            visible: root.isPlaying && !root.isPaused && (root.barValues[index] || 0.0) > 0.03
            anchors.top: parent.bottom
            anchors.topMargin: 2
            width: parent.width
            height: Math.min(6, (root.barValues[index] || 0.0) * 6)
            radius: 1
            opacity: 0.28
            color: root.activeThemeColor
          }
        }
      }
    }

    // Bottom Frequency Labels & Studio Axis
    Row {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 2
      anchors.leftMargin: 12
      anchors.rightMargin: 12

      Repeater {
        model: [
          { freq: "20Hz" },
          { freq: "100Hz" },
          { freq: "500Hz" },
          { freq: "1kHz" },
          { freq: "4kHz" },
          { freq: "10kHz" },
          { freq: "20kHz" }
        ]

        Item {
          width: parent.width / 7
          height: 10

          Text {
            anchors.centerIn: parent
            text: modelData.freq
            color: "#475569"
            font.pixelSize: 7
            font.bold: true
            font.family: "monospace"
          }
        }
      }
    }
  }

  // High-performance 40 FPS Visualizer Engine & Physics Step
  Timer {
    id: animTimer
    interval: 25 // 40 FPS silky smooth SceneGraph updates
    running: root.visible && root.panelOpened
    repeat: true
    onTriggered: {
      updateVisualizerFrame()
    }
  }

  function updateVisualizerFrame() {
    var activeAudio = root.isPlaying && !root.isPaused
    var tb = root.targetBands
    var cb = root.barValues
    var ph = root.peakValues
    var pv = root.peakVelocities
    var nextBars = []
    var nextPeaks = []
    var nextVels = []

    // When NOT playing music: smoothly decay all bars down to pure zero resting state
    if (!activeAudio) {
      for (var i = 0; i < 32; i++) {
        var curVal = (cb && cb[i] !== undefined) ? cb[i] : 0.0
        var curPeak = (ph && ph[i] !== undefined) ? ph[i] : 0.0

        var decayedVal = curVal * 0.72
        if (decayedVal < 0.003) decayedVal = 0.0

        var decayedPeak = Math.max(0.0, curPeak - 0.04)
        if (decayedPeak < 0.003) decayedPeak = 0.0

        nextBars.push(decayedVal)
        nextPeaks.push(decayedPeak)
        nextVels.push(0.0)
      }

      root.barValues = nextBars
      root.peakValues = nextPeaks
      root.peakVelocities = nextVels
      root.currentBass = 0.0
      root.targetBass = 0.0
      root.beatPulse = 0.0
      return
    }

    // Active Playback: Drive bars with audio stream
    root.animPhase += 0.08
    var phase = root.animPhase
    var isLiveAudio = tb && tb.length >= 32 && (root.targetBass > 0.005 || root.currentBass > 0.005)

    for (var j = 0; j < 32; j++) {
      var liveVal = (tb && tb[j] !== undefined) ? tb[j] : 0.0
      var barVal = (cb && cb[j] !== undefined) ? cb[j] : 0.0
      var peakVal = (ph && ph[j] !== undefined) ? ph[j] : 0.0
      var velVal = (pv && pv[j] !== undefined) ? pv[j] : 0.0

      var targetVal = 0.0
      if (isLiveAudio) {
        // Direct audio FFT data
        targetVal = Math.min(1.0, liveVal * 1.08)
      } else {
        // Subtle rhythm wave only while playback is actively running (track start buffering)
        var normX = j / 31.0
        var wave1 = Math.sin(normX * 5.0 - phase * 3.0) * 0.22 + 0.22
        var wave2 = Math.cos(normX * 9.0 + phase * 4.2) * 0.16 + 0.16
        var bassSurge = Math.max(0.0, (1.0 - normX * 1.3)) * (root.currentBass * 0.5 + root.beatPulse * 0.45)
        targetVal = Math.min(1.0, Math.max(0.0, (wave1 + wave2 + bassSurge) * 0.75))
      }

      // Fast snappy attack (0.76), smooth analog meter decay (0.22)
      var attackFactor = targetVal > barVal ? 0.76 : 0.22
      var updatedVal = barVal + (targetVal - barVal) * attackFactor
      if (updatedVal < 0.002) updatedVal = 0.0
      nextBars.push(updatedVal)

      // Peak-hold with realistic gravity drop
      if (updatedVal >= peakVal) {
        nextPeaks.push(updatedVal)
        nextVels.push(0.0) // Reset drop velocity
      } else {
        var newVel = velVal + 0.004 // Gravity acceleration
        var newPeak = Math.max(0.0, peakVal - newVel)
        if (newPeak < 0.002) {
          newPeak = 0.0
          newVel = 0.0
        }
        nextPeaks.push(newPeak)
        nextVels.push(newVel)
      }
    }

    root.barValues = nextBars
    root.peakValues = nextPeaks
    root.peakVelocities = nextVels

    // Smooth bass and decay beat pulse
    root.currentBass += (root.targetBass - root.currentBass) * 0.35
    root.beatPulse *= 0.82
  }
}
