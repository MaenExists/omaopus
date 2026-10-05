import QtQuick

Item {
  id: root

  property bool isPlaying: false
  property bool isPaused: false
  property real volume: 70
  property int colorTheme: 0 // 0: Nebula Deep Space, 1: Solar Supernova, 2: Cyber Aurora
  property bool active: isPlaying || isPaused

  signal themeToggled()

  implicitWidth: 360
  implicitHeight: 52

  Rectangle {
    id: bgCard
    anchors.fill: parent
    radius: 10
    color: Qt.rgba(0.04, 0.06, 0.12, 0.75)
    border.color: Qt.rgba(0.35, 0.45, 0.85, 0.25)
    border.width: 1
    clip: true

    Canvas {
      id: waveCanvas
      anchors.fill: parent

      property real timeStep: 0
      property real targetAmp: root.isPlaying ? (0.6 + (root.volume / 100.0) * 0.4) : (root.isPaused ? 0.22 : 0.05)
      property real currentAmp: 0.1

      // Stardust quantum particles array
      property var stars: []

      Component.onCompleted: {
        var s = []
        for (var i = 0; i < 22; i++) {
          s.push({
            x: Math.random() * 360,
            offsetY: (Math.random() - 0.5) * 26,
            speed: 0.3 + Math.random() * 0.7,
            size: 1.0 + Math.random() * 1.6,
            alpha: 0.3 + Math.random() * 0.7,
            twinkleSpeed: 1.0 + Math.random() * 2.0
          })
        }
        stars = s
      }

      onPaint: {
        var ctx = getContext("2d")
        var w = width
        var h = height
        if (w <= 0 || h <= 0) return

        ctx.clearRect(0, 0, w, h)

        var midY = h / 2.0
        var t = timeStep
        var amp = currentAmp

        // Theme palette definitions
        var gradFill, stroke1, stroke2, starColor
        if (root.colorTheme === 1) {
          // Solar Supernova (Gold / Amber / Crimson)
          gradFill = ctx.createLinearGradient(0, 0, w, 0)
          gradFill.addColorStop(0.0, "rgba(234, 88, 12, 0.20)")
          gradFill.addColorStop(0.5, "rgba(245, 158, 11, 0.32)")
          gradFill.addColorStop(1.0, "rgba(239, 68, 68, 0.20)")

          stroke1 = ctx.createLinearGradient(0, 0, w, 0)
          stroke1.addColorStop(0.0, "#fbbf24")
          stroke1.addColorStop(0.5, "#f59e0b")
          stroke1.addColorStop(1.0, "#ea580c")

          stroke2 = ctx.createLinearGradient(0, 0, w, 0)
          stroke2.addColorStop(0.0, "#f43f5e")
          stroke2.addColorStop(0.5, "#fb923c")
          stroke2.addColorStop(1.0, "#facc15")

          starColor = "rgba(254, 240, 138, "
        } else if (root.colorTheme === 2) {
          // Cyber Aurora (Matrix Emerald / Cyan / Mint)
          gradFill = ctx.createLinearGradient(0, 0, w, 0)
          gradFill.addColorStop(0.0, "rgba(16, 185, 129, 0.18)")
          gradFill.addColorStop(0.5, "rgba(6, 182, 212, 0.30)")
          gradFill.addColorStop(1.0, "rgba(52, 211, 153, 0.18)")

          stroke1 = ctx.createLinearGradient(0, 0, w, 0)
          stroke1.addColorStop(0.0, "#10b981")
          stroke1.addColorStop(0.5, "#06b6d4")
          stroke1.addColorStop(1.0, "#34d399")

          stroke2 = ctx.createLinearGradient(0, 0, w, 0)
          stroke2.addColorStop(0.0, "#38bdf8")
          stroke2.addColorStop(0.5, "#2dd4bf")
          stroke2.addColorStop(1.0, "#a7f3d0")

          starColor = "rgba(167, 243, 208, "
        } else {
          // Default: Nebula Deep Space (Electric Cyan / Hyper Violet / Magenta)
          gradFill = ctx.createLinearGradient(0, 0, w, 0)
          gradFill.addColorStop(0.0, "rgba(139, 92, 246, 0.22)")
          gradFill.addColorStop(0.5, "rgba(217, 70, 239, 0.32)")
          gradFill.addColorStop(1.0, "rgba(99, 102, 241, 0.22)")

          stroke1 = ctx.createLinearGradient(0, 0, w, 0)
          stroke1.addColorStop(0.0, "#00f2fe")
          stroke1.addColorStop(0.5, "#818cf8")
          stroke1.addColorStop(1.0, "#38bdf8")

          stroke2 = ctx.createLinearGradient(0, 0, w, 0)
          stroke2.addColorStop(0.0, "#f43f5e")
          stroke2.addColorStop(0.5, "#c084fc")
          stroke2.addColorStop(1.0, "#e879f9")

          starColor = "rgba(224, 231, 255, "
        }

        // LAYER 1: Deep Aurora Fill Wave
        ctx.save()
        ctx.beginPath()
        ctx.moveTo(0, h)
        var step = 4
        for (var x = 0; x <= w; x += step) {
          var y1 = midY + (Math.sin(x * 0.02 + t * 1.6) * 10.0 + Math.cos(x * 0.045 - t * 0.9) * 5.0) * amp
          ctx.lineTo(x, y1)
        }
        ctx.lineTo(w, h)
        ctx.closePath()
        ctx.fillStyle = gradFill
        ctx.fill()
        ctx.restore()

        // LAYER 2: Primary Harmonic Pulsar Ribbon (Electric Cyan / Main)
        ctx.save()
        ctx.lineWidth = 2.2
        ctx.strokeStyle = stroke1
        ctx.beginPath()
        for (var x2 = 0; x2 <= w; x2 += step) {
          var y2 = midY + (Math.sin(x2 * 0.032 - t * 2.3) * 11.0 + Math.sin(x2 * 0.016 + t * 1.2) * 7.0) * amp
          if (x2 === 0) ctx.moveTo(x2, y2)
          else ctx.lineTo(x2, y2)
        }
        ctx.stroke()
        ctx.restore()

        // LAYER 3: Fast Cosmic Starlight Line (Supernova / Crest)
        ctx.save()
        ctx.lineWidth = 1.6
        ctx.strokeStyle = stroke2
        ctx.beginPath()
        for (var x3 = 0; x3 <= w; x3 += step) {
          var y3 = midY + (Math.cos(x3 * 0.026 + t * 2.8) * 8.0 + Math.sin(x3 * 0.052 - t * 1.7) * 4.5) * amp
          if (x3 === 0) ctx.moveTo(x3, y3)
          else ctx.lineTo(x3, y3)
        }
        ctx.stroke()
        ctx.restore()

        // LAYER 4: Stardust Quantum Particles
        ctx.save()
        for (var i = 0; i < stars.length; i++) {
          var star = stars[i]
          var sx = (star.x + t * star.speed * 20.0) % w
          var waveHeight = (Math.sin(sx * 0.03 + t) * 9.0) * amp
          var sy = midY + waveHeight + star.offsetY
          var tw = 0.5 + 0.5 * Math.sin(t * star.twinkleSpeed + i)
          var alpha = star.alpha * tw

          ctx.fillStyle = starColor + alpha + ")"
          ctx.beginPath()
          ctx.arc(sx, sy, star.size, 0, 2 * Math.PI)
          ctx.fill()

          // Subtle glowing halo for larger star particles
          if (star.size > 1.8) {
            ctx.fillStyle = starColor + (alpha * 0.3) + ")"
            ctx.beginPath()
            ctx.arc(sx, sy, star.size * 2.2, 0, 2 * Math.PI)
            ctx.fill()
          }
        }
        ctx.restore()
      }
    }

    // High performance frame timer: runs only when panel is visible and active
    Timer {
      id: animTimer
      interval: 32 // ~30 FPS, silky smooth fluid dynamics with negligible CPU load
      running: root.visible && root.active
      repeat: true
      onTriggered: {
        waveCanvas.timeStep += 0.04
        waveCanvas.currentAmp += (waveCanvas.targetAmp - waveCanvas.currentAmp) * 0.15
        waveCanvas.requestPaint()
      }
    }

    // Click to cycle cosmic color themes!
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.colorTheme = (root.colorTheme + 1) % 3
        root.themeToggled()
      }
    }

    // Theme indicator badge
    Row {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 6
      spacing: 4
      opacity: 0.75

      Text {
        text: root.colorTheme === 1 ? "☀ Solar" : (root.colorTheme === 2 ? "✦ Cyber" : "★ Nebula")
        color: root.colorTheme === 1 ? "#fbbf24" : (root.colorTheme === 2 ? "#34d399" : "#a855f7")
        font.pixelSize: 10
        font.bold: true
      }
    }
  }
}
