import QtQuick
import Quickshell.Io

Item {
  id: root

  property bool isPlaying: false
  property bool isPaused: false
  property real volume: 70
  property int colorTheme: 0 // 0: Gargantua Gold (Nolan Canon), 1: Quantum Singularity (Cyan/Violet), 2: Solar Flare (Crimson/Amber)
  property string enginePath: ""
  property bool active: isPlaying && !isPaused

  signal themeToggled()

  implicitWidth: 360
  implicitHeight: 68

  // Real-time audio reactive properties
  property var currentBands: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  property var targetBands: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  property real currentBass: 0.0
  property real targetBass: 0.0
  property real currentMid: 0.0
  property real targetMid: 0.0
  property real currentHigh: 0.0
  property real targetHigh: 0.0
  property real currentEnergy: 0.0
  property real targetEnergy: 0.0
  property real beatPulse: 0.0

  function triggerBeat() {
    beatPulse = 1.0
  }

  function feedAudioData(line) {
    if (!line) return
    try {
      var d = JSON.parse(line)
      if (d.b && d.b.length >= 8) targetBands = d.b
      if (d.bass !== undefined) targetBass = d.bass
      if (d.mid !== undefined) targetMid = d.mid
      if (d.high !== undefined) targetHigh = d.high
      if (d.energy !== undefined) targetEnergy = d.energy
      if (d.beat && d.beat > 0.5) triggerBeat()
    } catch (e) {}
  }

  // Real-time low-latency audio capture process
  Process {
    id: engineProc
    command: [root.enginePath !== "" ? root.enginePath : (pluginDir + "/oma-visualizer-engine")]
    running: root.visible && root.active
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
    color: "#030408"
    border.color: Qt.rgba(0.25, 0.35, 0.6, 0.3)
    border.width: 1
    clip: true

    Canvas {
      id: holeCanvas
      anchors.fill: parent

      property real timeStep: 0.0
      property int pxSize: 3 // Chunky pixel-art grid unit

      // Swirling relativistic accretion matter particles
      property var particles: []
      // Distant background starfield
      property var stars: []

      Component.onCompleted: {
        var p = []
        for (var i = 0; i < 75; i++) {
          p.push({
            r: 20 + Math.random() * 115,
            angle: Math.random() * Math.PI * 2,
            size: Math.random() > 0.75 ? 2 : 1,
            lum: 0.4 + Math.random() * 0.6,
            speedMul: 0.8 + Math.random() * 0.4
          })
        }
        particles = p

        var s = []
        for (var j = 0; j < 32; j++) {
          s.push({
            x: Math.random() * 360,
            y: Math.random() * 80,
            size: Math.random() > 0.85 ? 2 : 1,
            twinkle: Math.random() * Math.PI * 2,
            twinkleSpeed: 1.5 + Math.random() * 2.5
          })
        }
        stars = s
      }

      onPaint: {
        var ctx = getContext("2d")
        var w = width
        var h = height
        if (w <= 0 || h <= 0) return

        var px = pxSize
        var cx = Math.floor((w / 2.0) / px) * px
        var cy = Math.floor((h / 2.0) / px) * px

        // Deep cosmic void background
        ctx.fillStyle = "#020307"
        ctx.fillRect(0, 0, w, h)

        var t = timeStep
        var bass = root.currentBass
        var mid = root.currentMid
        var high = root.currentHigh
        var energy = root.currentEnergy
        var beat = root.beatPulse

        // Color Palette Definitions (Chris Nolan Gargantua & Variations)
        var cCore, cDiskHot, cDiskMid, cDiskCold, cHalo, cJet, cStar
        if (root.colorTheme === 1) {
          // Quantum Singularity (Cyan / Violet)
          cCore = "#ffffff"
          cDiskHot = "#67e8f9"
          cDiskMid = "#818cf8"
          cDiskCold = "#4c1d95"
          cHalo = "#a855f7"
          cJet = "#c084fc"
          cStar = "rgba(199, 210, 254, "
        } else if (root.colorTheme === 2) {
          // Solar Supernova (Crimson / Gold)
          cCore = "#ffffff"
          cDiskHot = "#fef08a"
          cDiskMid = "#fb923c"
          cDiskCold = "#991b1b"
          cHalo = "#f43f5e"
          cJet = "#facc15"
          cStar = "rgba(254, 215, 170, "
        } else {
          // Nolan Canon Gargantua (Interstellar Gold & Amber)
          cCore = "#ffffff"
          cDiskHot = "#fffbeb"
          cDiskMid = "#f59e0b"
          cDiskCold = "#78350f"
          cHalo = "#ea580c"
          cJet = "#fde047"
          cStar = "rgba(254, 243, 199, "
        }

        // Helper: snap coordinate to pixel grid
        function snap(v) {
          return Math.floor(v / px) * px
        }

        // Helper: draw a single pixel block
        function pset(x, y, color) {
          ctx.fillStyle = color
          ctx.fillRect(snap(x), snap(y), px, px)
        }

        // 1. DISTANT BACKGROUND STARS (Warped slightly by gravity)
        for (var si = 0; si < stars.length; si++) {
          var star = stars[si]
          var dx = star.x - cx
          var dy = star.y - cy
          var dist = Math.sqrt(dx * dx + dy * dy)
          // Gravitational lensing deflecting light around the event horizon
          var lensOffset = dist > 20 ? (35.0 / dist) : 0
          var sx = star.x + (dx > 0 ? lensOffset : -lensOffset)
          var sy = star.y + (dy > 0 ? lensOffset : -lensOffset)
          var tw = 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(t * star.twinkleSpeed + star.twinkle)) * (1.0 + high * 0.8)
          ctx.fillStyle = cStar + Math.min(1.0, tw) + ")"
          ctx.fillRect(snap(sx), snap(sy), px * star.size, px * star.size)
        }

        // Core Event Horizon & Accretion Geometry
        var rHole = 15.0 + bass * 5.0 + beat * 3.0
        var rPhoton = rHole + 2.0

        // 2. GRAVITATIONAL LENSING: UPPER ARC (Bends rear disk over top of black hole)
        var upperRadiusX = rHole * 1.85 + bass * 6.0
        var upperRadiusY = rHole * 1.55 + bass * 5.0
        var arcStep = 0.08
        for (var a = Math.PI * 0.82; a <= Math.PI * 2.18; a += arcStep) {
          var lx = cx + Math.cos(a) * upperRadiusX
          var ly = (cy - 2) + Math.sin(a) * upperRadiusY
          // Thickness layers
          var doppler = (lx < cx) ? 1.25 : 0.85
          var col1 = doppler > 1.0 ? cDiskHot : cDiskMid
          var col2 = doppler > 1.0 ? cDiskMid : cDiskCold
          pset(lx, ly, col1)
          pset(lx, ly - px, col2)
          if (beat > 0.3 || energy > 0.4) {
            pset(lx, ly + px, cHalo)
          }
        }

        // 3. GRAVITATIONAL LENSING: LOWER ARC (Bends rear disk under bottom of black hole)
        var lowerRadiusX = rHole * 1.75 + bass * 5.0
        var lowerRadiusY = rHole * 1.25 + bass * 4.0
        for (var la = -Math.PI * 0.18; la <= Math.PI * 1.18; la += arcStep) {
          var llx = cx + Math.cos(la) * lowerRadiusX
          var lly = (cy + 2) + Math.sin(la) * lowerRadiusY
          var dLower = (llx < cx) ? 1.15 : 0.75
          pset(llx, lly, dLower > 1.0 ? cDiskMid : cDiskCold)
          pset(llx, lly + px, cDiskCold)
        }

        // 4. RELATIVISTIC BEAT RIPPLE (Gravitational wave expansion on kick)
        if (beat > 0.05) {
          var rippleR = rHole + (1.0 - beat) * 45.0
          var rippleAlpha = beat * 0.85
          ctx.strokeStyle = cJet
          ctx.lineWidth = px
          for (var ra = 0; ra < Math.PI * 2; ra += 0.25) {
            if (Math.random() > 0.3) {
              var rx = cx + Math.cos(ra) * rippleR
              var ry = cy + Math.sin(ra) * (rippleR * 0.45)
              pset(rx, ry, cDiskHot)
            }
          }
        }

        // 5. ACCRETION MATTER PARTICLES (Rear half: drawn behind event horizon)
        for (var pi = 0; pi < particles.length; pi++) {
          var p = particles[pi]
          // Orbital physics: v ~ 1/sqrt(r)
          var v = (0.048 / Math.sqrt(p.r / rHole)) * (1.0 + mid * 1.4) * p.speedMul
          p.angle = (p.angle + v) % (Math.PI * 2)

          // Only render rear half here (sin(angle) < 0)
          if (Math.sin(p.angle) < 0) {
            var pDistX = Math.cos(p.angle) * p.r
            var pDistY = Math.sin(p.angle) * (p.r * 0.28)
            var pxPos = cx + pDistX
            var pyPos = cy + pDistY

            // Occluded if inside black hole shadow
            var distToHole = Math.sqrt(pDistX * pDistX + pDistY * pDistY)
            if (distToHole > rHole) {
              var pDoppler = (pxPos < cx) ? 1.3 : 0.7
              pset(pxPos, pyPos, pDoppler > 1.0 ? cDiskMid : cDiskCold)
            }
          }
        }

        // 6. EVENT HORIZON: THE BLACK HOLE SHADOW (Nolan's Gargantua Void)
        ctx.fillStyle = "#010204"
        ctx.beginPath()
        ctx.arc(cx, cy, rHole, 0, Math.PI * 2)
        ctx.fill()

        // 7. PHOTON SPHERE RING (Infinite orbit photon ring framing the void)
        ctx.lineWidth = px
        for (var pa = 0; pa < Math.PI * 2; pa += 0.12) {
          var phx = cx + Math.cos(pa) * rPhoton
          var phy = cy + Math.sin(pa) * rPhoton
          var phColor = (phx < cx) ? cCore : cDiskHot
          pset(phx, phy, phColor)
        }

        // 8. EQUATORIAL ACCRETION DISK (Front Crossing: slices directly in front of the black hole)
        var diskWidth = 115 + energy * 42.0 + bass * 20.0
        for (var dx = -diskWidth; dx <= diskWidth; dx += px) {
          var curX = cx + dx
          var normDist = dx / diskWidth // -1.0 to 1.0
          var absDist = Math.abs(normDist)

          // Map frequency spectrum to disk position (low frequencies near center, high at edges)
          var bandIdx = Math.min(7, Math.floor(absDist * 8.0))
          var bandEnergy = root.currentBands[bandIdx] || 0.0

          // Disk thickness with audio reactivity
          var baseThick = (3.2 + mid * 3.6 + bandEnergy * 5.0) * (1.0 - absDist * 0.55)
          var diskYMin = cy - baseThick
          var diskYMax = cy + baseThick

          // Relativistic Doppler beaming: approaching side (left) is blazing bright, receding (right) is dim/red
          var isApproaching = dx < 0
          var dopplerBoost = isApproaching ? (1.35 + mid * 0.3) : 0.68

          for (var dy = diskYMin; dy <= diskYMax; dy += px) {
            var distFromEquator = Math.abs(dy - cy) / Math.max(1, baseThick)
            var pColor
            if (distFromEquator < 0.28 && dopplerBoost > 1.1) {
              pColor = cCore // White-hot core stream
            } else if (distFromEquator < 0.65) {
              pColor = isApproaching ? cDiskHot : cDiskMid
            } else {
              pColor = isApproaching ? cDiskMid : cDiskCold
            }

            // Pixel coronal sparks / turbulence along the rim
            if (Math.random() < (0.88 + high * 0.1)) {
              pset(curX, dy, pColor)
            }
          }
        }

        // 9. ACCRETION PARTICLES (Front half: swirling in front of the black hole)
        for (var pfi = 0; pfi < particles.length; pfi++) {
          var pf = particles[pfi]
          if (Math.sin(pf.angle) >= 0) {
            var pfX = cx + Math.cos(pf.angle) * pf.r
            var pfY = cy + Math.sin(pf.angle) * (pf.r * 0.28)
            var pfDoppler = (pfX < cx) ? 1.4 : 0.75
            var pfCol = (pfDoppler > 1.2) ? cCore : ((pfDoppler > 0.9) ? cDiskHot : cDiskMid)
            pset(pfX, pfY, pfCol)
            if (pf.size > 1 && beat > 0.2) {
              pset(pfX + px, pfY, cDiskHot)
            }
          }
        }

        // 10. POLAR RELATIVISTIC JETS (Sparks erupting vertically on massive bass kicks)
        if (beat > 0.25 || bass > 0.6) {
          var jetLen = 14 + bass * 16.0 + beat * 10.0
          for (var j = 0; j < jetLen; j += px) {
            var jSpread = (j / jetLen) * (px * 2)
            var jxTop = cx + (Math.random() - 0.5) * jSpread
            var jyTop = (cy - rHole) - j
            pset(jxTop, jyTop, Math.random() > 0.4 ? cCore : cJet)

            var jxBot = cx + (Math.random() - 0.5) * jSpread
            var jyBot = (cy + rHole) + j
            pset(jxBot, jyBot, Math.random() > 0.4 ? cCore : cJet)
          }
        }
      }
    }

    // Animation & Audio Smoothing Loop
    Timer {
      id: animTimer
      interval: 28 // ~35 FPS silky smooth visualizer loop
      running: root.visible && root.active
      repeat: true
      onTriggered: {
        waveCanvas_step()
      }
    }

    function waveCanvas_step() {
      // Smooth frequency bands interpolation
      var cb = root.currentBands
      var tb = root.targetBands
      var nextB = []
      for (var i = 0; i < 8; i++) {
        var target = (tb && tb[i] !== undefined) ? tb[i] : 0.0
        var cur = (cb && cb[i] !== undefined) ? cb[i] : 0.0
        // Snappy attack, smooth decay
        var factor = target > cur ? 0.45 : 0.18
        nextB.push(cur + (target - cur) * factor)
      }
      root.currentBands = nextB

      // Smooth scalar levels
      var aFactor = 0.35
      root.currentBass += (root.targetBass - root.currentBass) * aFactor
      root.currentMid += (root.targetMid - root.currentMid) * aFactor
      root.currentHigh += (root.targetHigh - root.currentHigh) * aFactor
      root.currentEnergy += (root.targetEnergy - root.currentEnergy) * aFactor

      // Decay beat pulse
      if (root.beatPulse > 0.01) {
        root.beatPulse *= 0.82
      } else {
        root.beatPulse = 0.0
      }

      holeCanvas.timeStep += 0.05
      holeCanvas.requestPaint()
    }

    // Interactive Theme Toggle
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.colorTheme = (root.colorTheme + 1) % 3
        root.themeToggled()
      }
    }

    // Real-Time HUD Status Badge
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
        color: root.beatPulse > 0.3 ? "#ffffff" : (root.colorTheme === 1 ? "#67e8f9" : (root.colorTheme === 2 ? "#fb923c" : "#f59e0b"))
      }

      Text {
        text: root.colorTheme === 1 ? "QUANTUM GARGANTUA" : (root.colorTheme === 2 ? "SOLAR GARGANTUA" : "GARGANTUA 8-BIT")
        color: root.colorTheme === 1 ? "#67e8f9" : (root.colorTheme === 2 ? "#fb923c" : "#f59e0b")
        font.pixelSize: 9
        font.bold: true
        font.family: "monospace"
      }
    }

    // Subtle Live Energy Meter
    Row {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.margins: 6
      spacing: 3
      opacity: 0.65

      Repeater {
        model: 8
        Rectangle {
          width: 3
          height: Math.max(2, (root.currentBands[index] || 0.0) * 14.0)
          anchors.bottom: parent.bottom
          color: root.colorTheme === 1 ? "#818cf8" : (root.colorTheme === 2 ? "#f43f5e" : "#f59e0b")
          radius: 1
        }
      }
    }
  }
}
