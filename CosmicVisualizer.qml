import QtQuick
import Quickshell.Io

Item {
  id: root

  property bool isPlaying: false
  property bool isPaused: false
  property real volume: 70
  property int colorTheme: 0 // 0: Cyber Neon, 1: Solar Fire, 2: Matrix Emerald
  property string enginePath: Qt.resolvedUrl("oma-visualizer-engine").toString().replace(/^file:\/\//, "")
  property bool active: isPlaying && !isPaused

  signal themeToggled()

  implicitWidth: 360
  implicitHeight: 76

  // 32 Frequency Bands
  property var currentBands: []
  property var targetBands: []
  property var peakHold: []
  property real currentBass: 0.0
  property real targetBass: 0.0
  property real beatPulse: 0.0
  property real beatPump: 0.0

  Component.onCompleted: {
    var b = []
    var p = []
    for (var i = 0; i < 32; i++) {
      b.push(0.05)
      p.push(0.05)
    }
    currentBands = b
    targetBands = b
    peakHold = p
  }

  function triggerBeat() {
    beatPulse = 1.0
    beatPump = 1.0
  }

  function feedAudioData(line) {
    if (!line) return
    try {
      var d = JSON.parse(line)
      if (d.b && d.b.length >= 16) {
        // Expand/map to 32 bands if needed
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

  // Real-time audio engine process
  Process {
    id: engineProc
    command: [root.enginePath]
    running: root.visible && root.isPlaying
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

    Canvas {
      id: specCanvas
      anchors.fill: parent

      property real timeStep: 0.0

      onPaint: {
        var ctx = getContext("2d")
        var w = width
        var h = height
        if (w <= 0 || h <= 0) return

        ctx.clearRect(0, 0, w, h)

        // Dark background
        ctx.fillStyle = "#080a12"
        ctx.fillRect(0, 0, w, h)

        var t = timeStep
        var numBars = 32
        var padX = 14
        var availW = w - padX * 2
        var barSpacing = 2.0
        var barW = Math.max(3.0, (availW - (numBars - 1) * barSpacing) / numBars)

        var baselineY = h - 16
        var maxBarH = 44.0 + root.beatPump * 6.0

        // Palette Gradients
        var theme = root.colorTheme
        var cPeak, cBase
        // Colors from bottom to top
        var gStop0, gStop1, gStop2, gStop3
        if (theme === 1) {
          // Solar Fire (Gold -> Sunset Amber -> Crimson -> White)
          gStop0 = "#991b1b" // Deep Crimson
          gStop1 = "#ea580c" // Orange
          gStop2 = "#f59e0b" // Amber
          gStop3 = "#fef08a" // Blazing Gold
          cPeak = "#ffffff"
          cBase = "#450a0a"
        } else if (theme === 2) {
          // Matrix Emerald (Deep Green -> Mint -> Cyan -> White)
          gStop0 = "#064e3b" // Deep Emerald
          gStop1 = "#059669" // Green
          gStop2 = "#10b981" // Mint
          gStop3 = "#6ee7b7" // Light Mint
          cPeak = "#ffffff"
          cBase = "#022c22"
        } else {
          // Cyber Neon (Deep Blue -> Cyan -> Purple -> Hot Pink)
          gStop0 = "#1e1b4b" // Deep Indigo
          gStop1 = "#06b6d4" // Electric Cyan
          gStop2 = "#818cf8" // Violet
          gStop3 = "#f43f5e" // Hot Pink
          cPeak = "#ffffff"
          cBase = "#0f172a"
        }

        // Draw Baseline Grid Line
        ctx.strokeStyle = "rgba(255, 255, 255, 0.08)"
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(padX, baselineY + 1)
        ctx.lineTo(w - padX, baselineY + 1)
        ctx.stroke()

        // Draw 32 Spectrum Equalizer Bars
        for (var i = 0; i < numBars; i++) {
          var x = padX + i * (barW + barSpacing)
          var val = root.currentBands[i] || 0.0
          var peakVal = root.peakHold[i] || 0.0

          // Calculate bar height
          var bh = Math.max(3.0, val * maxBarH)
          var barTopY = baselineY - bh

          // Create vertical gradient for this bar
          var grad = ctx.createLinearGradient(0, baselineY, 0, baselineY - maxBarH)
          grad.addColorStop(0.0, gStop0)
          grad.addColorStop(0.35, gStop1)
          grad.addColorStop(0.75, gStop2)
          grad.addColorStop(1.0, gStop3)

          // 1. MAIN EQUALIZER BAR (Segmented LED style)
          var segmentH = 3.0
          var segmentGap = 1.0
          var totalSeg = Math.floor(bh / (segmentH + segmentGap))

          ctx.fillStyle = grad
          for (var s = 0; s < totalSeg; s++) {
            var sy = baselineY - (s + 1) * (segmentH + segmentGap)
            ctx.fillRect(Math.floor(x), Math.floor(sy), Math.floor(barW), segmentH)
          }

          // 2. FLOATING PEAK-HOLD CAP (Classic Hi-Fi Visualizer)
          var peakY = baselineY - (peakVal * maxBarH) - 3.0
          ctx.fillStyle = cPeak
          ctx.fillRect(Math.floor(x), Math.floor(peakY), Math.floor(barW), 2.0)

          // 3. GLOSSY BOTTOM REFLECTION (Fades down into baseline)
          var refH = Math.min(10.0, bh * 0.28)
          var refGrad = ctx.createLinearGradient(0, baselineY, 0, baselineY + refH)
          refGrad.addColorStop(0.0, "rgba(255, 255, 255, 0.18)")
          refGrad.addColorStop(1.0, "rgba(0, 0, 0, 0.0)")
          ctx.fillStyle = refGrad
          ctx.fillRect(Math.floor(x), baselineY + 2, Math.floor(barW), refH)
        }
      }
    }

    // High-performance 40 FPS Visualizer Animation Loop
    Timer {
      id: animTimer
      interval: 25 // 40 FPS ultra-smooth loop
      running: root.visible && root.active
      repeat: true
      onTriggered: {
        stepVisualizer()
      }
    }

    function stepVisualizer() {
      var tb = root.targetBands
      var cb = root.currentBands
      var ph = root.peakHold
      var nextB = []
      var nextPh = []
      var t = specCanvas.timeStep

      // Live Audio vs Harmonic Synth Wave Blend
      // Guarantees that the bars bounce and dance with tempo even during quiet sections!
      var isEngineActive = tb && tb.length > 0 && root.targetBass > 0.02
      var volMult = root.volume / 100.0

      for (var i = 0; i < 32; i++) {
        var liveVal = (tb && tb[i] !== undefined) ? tb[i] : 0.0
        var curVal = (cb && cb[i] !== undefined) ? cb[i] : 0.0
        var oldPeak = (ph && ph[i] !== undefined) ? ph[i] : 0.0

        // Harmonic procedural pulse for lively rhythm
        var normX = i / 32.0
        var wave1 = Math.sin(normX * 4.2 - t * 3.5) * 0.35 + 0.35
        var wave2 = Math.cos(normX * 8.5 + t * 4.8) * 0.25 + 0.25
        var bassBoost = (1.0 - normX) * (root.currentBass * 0.45 + root.beatPulse * 0.35)
        var synthVal = Math.min(1.0, (wave1 + wave2 + bassBoost) * volMult)

        // Target value is either live audio or blended harmonic synth
        var targetVal = isEngineActive ? (liveVal * 0.85 + synthVal * 0.15) : (synthVal * 0.75)

        // Fast attack (snappy jump), smooth decay
        var factor = targetVal > curVal ? 0.70 : 0.22
        var updated = curVal + (targetVal - curVal) * factor
        nextB.push(updated)

        // Peak-hold gravity drop
        if (updated > oldPeak) {
          nextPh.push(updated)
        } else {
          nextPh.push(Math.max(0.0, oldPeak - 0.032))
        }
      }

      root.currentBands = nextB
      root.peakHold = nextPh

      // Interpolate bass and decay beat pump
      root.currentBass += (root.targetBass - root.currentBass) * 0.4
      root.beatPulse *= 0.85
      root.beatPump *= 0.82

      specCanvas.timeStep += 0.08
      specCanvas.requestPaint()
    }

    // Click to cycle color palettes
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.colorTheme = (root.colorTheme + 1) % 3
        root.themeToggled()
      }
    }

    // Top HUD Info Bar
    Row {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 6
      spacing: 6
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

    // Left HUD Indicator
    Row {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.margins: 6
      spacing: 4
      opacity: 0.7

      Text {
        text: "SPECTRUM ANALYZER"
        color: "#94a3b8"
        font.pixelSize: 8
        font.bold: true
        font.family: "monospace"
      }
    }
  }
}
