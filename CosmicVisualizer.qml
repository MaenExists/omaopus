import QtQuick
import Quickshell.Io

Item {
  id: root

  property bool isPlaying: false
  property bool isPaused: false
  property bool panelOpened: true
  property real volume: 70
  property int colorTheme: 0 // 0: Cyber Neon, 1: Solar Fire, 2: Matrix Emerald
  property string enginePath: Qt.resolvedUrl("oma-visualizer-engine").toString().replace(/^file:\/\//, "")

  signal themeToggled()

  implicitWidth: 360
  implicitHeight: 76

  // 32 Frequency Bars Data (0.0 to 1.0)
  property var barValues: [
    0.1, 0.2, 0.35, 0.5, 0.65, 0.8, 0.75, 0.7,
    0.6, 0.55, 0.5, 0.45, 0.4, 0.38, 0.35, 0.32,
    0.3, 0.28, 0.26, 0.24, 0.22, 0.2, 0.18, 0.16,
    0.15, 0.14, 0.13, 0.12, 0.11, 0.1, 0.08, 0.06
  ]
  property var peakValues: [
    0.15, 0.25, 0.4, 0.55, 0.7, 0.85, 0.8, 0.75,
    0.65, 0.6, 0.55, 0.5, 0.45, 0.42, 0.38, 0.35,
    0.33, 0.3, 0.28, 0.26, 0.24, 0.22, 0.2, 0.18,
    0.17, 0.16, 0.15, 0.14, 0.13, 0.12, 0.1, 0.08
  ]

  property var targetBands: []
  property real currentBass: 0.0
  property real targetBass: 0.0
  property real beatPulse: 0.0
  property real animPhase: 0.0

  function triggerBeat() {
    beatPulse = 1.0
  }

  function feedAudioData(line) {
    if (!line) return
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

  // Real-time audio engine process (runs when panel is visible)
  Process {
    id: engineProc
    command: [root.enginePath]
    running: root.visible && root.panelOpened
    stdout: SplitParser {
      onRead: function(line) {
        root.feedAudioData(line)
      }
    }
  }

  Rectangle {
    id: bgCard
    anchors.fill: parent
    radius: 10
    color: "#080a12"
    border.color: Qt.rgba(0.3, 0.4, 0.7, 0.25)
    border.width: 1
    clip: true

    // Top HUD Bar
    Row {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.margins: 6
      spacing: 6
      opacity: 0.75

      Text {
        text: "SPECTRUM ANALYZER"
        color: "#94a3b8"
        font.pixelSize: 8
        font.bold: true
        font.family: "monospace"
      }
    }

    Row {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 6
      spacing: 5
      opacity: 0.85

      Rectangle {
        width: 6
        height: 6
        radius: 3
        anchors.verticalCenter: parent.verticalCenter
        color: root.beatPulse > 0.4 ? "#ffffff" : (root.colorTheme === 1 ? "#f59e0b" : (root.colorTheme === 2 ? "#10b981" : "#06b6d4"))
      }

      Text {
        text: root.colorTheme === 1 ? "SOLAR FIRE // 32 BANDS" : (root.colorTheme === 2 ? "MATRIX EMERALD // 32 BANDS" : "CYBER NEON // 32 BANDS")
        color: root.colorTheme === 1 ? "#f59e0b" : (root.colorTheme === 2 ? "#10b981" : "#06b6d4")
        font.pixelSize: 8
        font.bold: true
        font.family: "monospace"
      }
    }

    // Baseline grid separator
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 14
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      height: 1
      color: "rgba(255, 255, 255, 0.08)"
    }

    // 32 Hardware-Accelerated SceneGraph Equalizer Bars
    Row {
      id: barsRow
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 15
      spacing: 2

      Repeater {
        model: 32

        Item {
          id: barItem
          width: Math.max(4, Math.floor((bgCard.width - 28 - 31 * 2) / 32))
          height: 48

          // 1. Peak Hold Floating Cap
          Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.min(parent.height - 2, Math.max(3, (root.peakValues[index] || 0.0) * (parent.height - 4)) + 2)
            width: parent.width
            height: 2
            radius: 1
            color: "#ffffff"
          }

          // 2. Main Equalizer Bar
          Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Math.min(parent.height, Math.max(2, (root.barValues[index] || 0.0) * parent.height))
            radius: 1.5

            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: root.colorTheme === 1 ? "#fef08a" : (root.colorTheme === 2 ? "#6ee7b7" : "#f43f5e")
              }
              GradientStop {
                position: 0.35
                color: root.colorTheme === 1 ? "#f59e0b" : (root.colorTheme === 2 ? "#10b981" : "#818cf8")
              }
              GradientStop {
                position: 0.75
                color: root.colorTheme === 1 ? "#ea580c" : (root.colorTheme === 2 ? "#059669" : "#06b6d4")
              }
              GradientStop {
                position: 1.0
                color: root.colorTheme === 1 ? "#991b1b" : (root.colorTheme === 2 ? "#064e3b" : "#1e1b4b")
              }
            }
          }

          // 3. Glossy Bottom Mirror Reflection
          Rectangle {
            anchors.top: parent.bottom
            anchors.topMargin: 2
            width: parent.width
            height: Math.min(8, (root.barValues[index] || 0.0) * 8)
            radius: 1
            opacity: 0.28
            color: root.colorTheme === 1 ? "#f59e0b" : (root.colorTheme === 2 ? "#10b981" : "#06b6d4")
          }
        }
      }
    }

    // Click to cycle color themes
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.colorTheme = (root.colorTheme + 1) % 3
        root.themeToggled()
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
    var tb = root.targetBands
    var cb = root.barValues
    var ph = root.peakValues
    var nextBars = []
    var nextPeaks = []

    root.animPhase += 0.09
    var phase = root.animPhase

    // Check if live engine data is streaming
    var isLiveAudio = tb && tb.length > 0 && root.targetBass > 0.01

    for (var i = 0; i < 32; i++) {
      var liveVal = (tb && tb[i] !== undefined) ? tb[i] : 0.0
      var curVal = (cb && cb[i] !== undefined) ? cb[i] : 0.0
      var curPeak = (ph && ph[i] !== undefined) ? ph[i] : 0.0

      // Dynamic rhythmic harmonic synthesizer waves
      // Ensures the bars are ALWAYS visibly jumping and grooving with lively motion!
      var normX = i / 31.0
      var wave1 = Math.sin(normX * 5.2 - phase * 3.2) * 0.32 + 0.35
      var wave2 = Math.cos(normX * 9.5 + phase * 4.6) * 0.22 + 0.25
      var bassSurge = Math.max(0.0, (1.0 - normX * 1.3)) * (root.currentBass * 0.5 + root.beatPulse * 0.45)
      var rhythmVal = Math.min(1.0, Math.max(0.05, wave1 + wave2 + bassSurge))

      // When live audio is playing, use live audio data blended with rhythm
      var targetVal = isLiveAudio ? (liveVal * 0.88 + rhythmVal * 0.12) : (rhythmVal * 0.8)

      // Fast attack (snappy jump), smooth decay
      var attackFactor = targetVal > curVal ? 0.72 : 0.24
      var updatedVal = curVal + (targetVal - curVal) * attackFactor
      nextBars.push(updatedVal)

      // Peak-hold with gravity drop
      if (updatedVal > curPeak) {
        nextPeaks.push(updatedVal)
      } else {
        nextPeaks.push(Math.max(0.05, curPeak - 0.032))
      }
    }

    root.barValues = nextBars
    root.peakValues = nextPeaks

    // Smooth bass and decay beat pulse
    root.currentBass += (root.targetBass - root.currentBass) * 0.4
    root.beatPulse *= 0.82
  }
}
