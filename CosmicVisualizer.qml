import QtQuick
import Quickshell.Io

Item {
  id: root

  property bool isPlaying: false
  property bool isPaused: false
  property real volume: 70
  property int colorTheme: 0 // 0: Gargantua Gold (Nolan Canon), 1: Quantum Singularity (Cyan/Violet), 2: Solar Flare (Crimson/Gold)
  property string enginePath: Qt.resolvedUrl("oma-visualizer-engine").toString().replace(/^file:\/\//, "")
  property bool active: isPlaying && !isPaused

  signal themeToggled()

  implicitWidth: 360
  implicitHeight: 74

  // Real-time audio reactive properties
  property var currentBands: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  property var targetBands: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  property var peakHold: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

  property real currentBass: 0.0
  property real targetBass: 0.0
  property real currentMid: 0.0
  property real targetMid: 0.0
  property real currentHigh: 0.0
  property real targetHigh: 0.0
  property real currentEnergy: 0.0
  property real targetEnergy: 0.0

  // Beat impact physics
  property real beatPulse: 0.0
  property real springScale: 1.0
  property real shakeX: 0.0
  property real shakeY: 0.0
  property real swirlSpeed: 1.0

  function triggerBeat() {
    beatPulse = 1.0
    springScale = 1.45
    shakeX = (Math.random() - 0.5) * 5.0
    shakeY = (Math.random() - 0.5) * 3.5
  }

  function feedAudioData(line) {
    if (!line) return
    try {
      var d = JSON.parse(line)
      if (d.b && d.b.length > 0) targetBands = d.b
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
    command: [root.enginePath]
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
    color: "#020306"
    border.color: Qt.rgba(0.25, 0.35, 0.6, 0.3)
    border.width: 1
    clip: true

    Canvas {
      id: holeCanvas
      anchors.fill: parent

      property real timeStep: 0.0
      property int pxSize: 3 // Chunky retro pixel-art grid unit

      // Swirling relativistic accretion matter particles
      property var particles: []
      // Background starfield
      property var stars: []

      Component.onCompleted: {
        var p = []
        for (var i = 0; i < 85; i++) {
          p.push({
            r: 18 + Math.random() * 115,
            angle: Math.random() * Math.PI * 2,
            size: Math.random() > 0.7 ? 2 : 1,
            lum: 0.35 + Math.random() * 0.65,
            speedMul: 0.75 + Math.random() * 0.5
          })
        }
        particles = p

        var s = []
        for (var j = 0; j < 36; j++) {
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
        var cx = Math.floor((w / 2.0 + root.shakeX) / px) * px
        var cy = Math.floor((h / 2.0 + root.shakeY) / px) * px

        // Deep cosmic void background
        ctx.fillStyle = "#010205"
        ctx.fillRect(0, 0, w, h)

        var t = timeStep
        var bass = root.currentBass
        var mid = root.currentMid
        var high = root.currentHigh
        var energy = root.currentEnergy
        var beat = root.beatPulse
        var scale = root.springScale

        // Color Palette Definitions
        var cCore, cDiskHot, cDiskMid, cDiskCold, cHalo, cJet, cStar, cEq
        if (root.colorTheme === 1) {
          // Quantum Singularity (Cyan / Violet)
          cCore = "#ffffff"
          cDiskHot = "#67e8f9"
          cDiskMid = "#818cf8"
          cDiskCold = "#4c1d95"
          cHalo = "#a855f7"
          cJet = "#c084fc"
          cStar = "rgba(199, 210, 254, "
          cEq = "#38bdf8"
        } else if (root.colorTheme === 2) {
          // Solar Supernova (Crimson / Gold)
          cCore = "#ffffff"
          cDiskHot = "#fef08a"
          cDiskMid = "#fb923c"
          cDiskCold = "#991b1b"
          cHalo = "#f43f5e"
          cJet = "#facc15"
          cStar = "rgba(254, 215, 170, "
          cEq = "#f59e0b"
        } else {
          // Nolan Canon Gargantua (Interstellar Gold & Amber)
          cCore = "#ffffff"
          cDiskHot = "#fffbeb"
          cDiskMid = "#f59e0b"
          cDiskCold = "#78350f"
          cHalo = "#ea580c"
          cJet = "#fde047"
          cStar = "rgba(254, 243, 199, "
          cEq = "#fbbf24"
        }

        // Helper: snap coordinate to pixel grid
        function snap(v) {
          return Math.floor(v / px) * px
        }

        // Helper: draw single pixel block
        function pset(x, y, color) {
          ctx.fillStyle = color
          ctx.fillRect(snap(x), snap(y), px, px)
        }

        // 1. BACKGROUND STARS (Gravitational lensing deflection)
        for (var si = 0; si < stars.length; si++) {
          var star = stars[si]
          var dx = star.x - cx
          var dy = star.y - cy
          var dist = Math.sqrt(dx * dx + dy * dy)
          var lensOffset = dist > 18 ? (40.0 / dist) * scale : 0
          var sx = star.x + (dx > 0 ? lensOffset : -lensOffset)
          var sy = star.y + (dy > 0 ? lensOffset : -lensOffset)
          var tw = 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(t * star.twinkleSpeed + star.twinkle)) * (1.0 + high * 0.9)
          ctx.fillStyle = cStar + Math.min(1.0, tw) + ")"
          ctx.fillRect(snap(sx), snap(sy), px * star.size, px * star.size)
        }

        // 2. BEAT EXPLOSION SHOCKWAVE (Rippling outward on drum kicks)
        if (beat > 0.05) {
          var shockR = (13.0 + bass * 5.0) + (1.0 - beat) * 75.0
          for (var sa = 0; sa < Math.PI * 2; sa += 0.18) {
            if (Math.random() > 0.25) {
              var shx = cx + Math.cos(sa) * shockR
              var shy = cy + Math.sin(sa) * (shockR * 0.42)
              pset(shx, shy, beat > 0.5 ? cCore : cJet)
            }
          }
        }

        // Core Black Hole Dimensions
        var rHole = (14.0 + bass * 6.5) * scale
        var rPhoton = rHole + 2.0

        // 3. GRAVITATIONAL LENSING: UPPER ARC (Bending light over top of hole)
        var upperRadiusX = (rHole * 1.85 + bass * 8.0)
        var upperRadiusY = (rHole * 1.55 + bass * 7.0)
        var arcStep = 0.07
        for (var a = Math.PI * 0.82; a <= Math.PI * 2.18; a += arcStep) {
          var lx = cx + Math.cos(a) * upperRadiusX
          var ly = (cy - 2) + Math.sin(a) * upperRadiusY
          var doppler = (lx < cx) ? 1.3 : 0.8
          var col1 = doppler > 1.0 ? (beat > 0.4 ? cCore : cDiskHot) : cDiskMid
          var col2 = doppler > 1.0 ? cDiskMid : cDiskCold
          pset(lx, ly, col1)
          pset(lx, ly - px, col2)
          if (beat > 0.2 || energy > 0.5) {
            pset(lx, ly - px * 2, cHalo)
          }
        }

        // 4. GRAVITATIONAL LENSING: LOWER ARC (Bending light under bottom of hole)
        var lowerRadiusX = (rHole * 1.75 + bass * 6.0)
        var lowerRadiusY = (rHole * 1.25 + bass * 5.0)
        for (var la = -Math.PI * 0.18; la <= Math.PI * 1.18; la += arcStep) {
          var llx = cx + Math.cos(la) * lowerRadiusX
          var lly = (cy + 2) + Math.sin(la) * lowerRadiusY
          var dLower = (llx < cx) ? 1.2 : 0.75
          pset(llx, lly, dLower > 1.0 ? cDiskMid : cDiskCold)
          pset(llx, lly + px, cDiskCold)
        }

        // 5. SWIRLING ACCRETION MATTER PARTICLES (Rear half: behind hole)
        var pSpeed = (1.0 + bass * 3.5 + beat * 4.5)
        for (var pi = 0; pi < particles.length; pi++) {
          var p = particles[pi]
          var v = (0.055 / Math.sqrt(p.r / (rHole + 1.0))) * pSpeed * p.speedMul
          p.angle = (p.angle + v) % (Math.PI * 2)

          if (Math.sin(p.angle) < 0) {
            var pDistX = Math.cos(p.angle) * p.r
            var pDistY = Math.sin(p.angle) * (p.r * 0.26)
            var pxPos = cx + pDistX
            var pyPos = cy + pDistY

            var distToHole = Math.sqrt(pDistX * pDistX + pDistY * pDistY)
            if (distToHole > rHole) {
              var pDoppler = (pxPos < cx) ? 1.3 : 0.7
              pset(pxPos, pyPos, pDoppler > 1.0 ? cDiskMid : cDiskCold)
            }
          }
        }

        // 6. EVENT HORIZON: OBSIDIAN BLACK HOLE SHADOW
        ctx.fillStyle = "#010204"
        ctx.beginPath()
        ctx.arc(cx, cy, rHole, 0, Math.PI * 2)
        ctx.fill()

        // 7. PHOTON SPHERE RING (Blazing ring framing the void)
        var pRingColor = beat > 0.3 ? cCore : (cDiskHot)
        for (var pa = 0; pa < Math.PI * 2; pa += 0.1) {
          var phx = cx + Math.cos(pa) * rPhoton
          var phy = cy + Math.sin(pa) * rPhoton
          pset(phx, phy, pRingColor)
          if (beat > 0.4) {
            pset(phx + (Math.random() - 0.5) * px, phy + (Math.random() - 0.5) * px, cCore)
          }
        }

        // 8. ACTIVE VISUALIZER: EQUALIZER SPIRES ALONG ACCRETION DISK
        // Renders 16 dancing vertical equalizer bars directly across the accretion disk!
        var numB = Math.min(16, root.currentBands.length)
        var barSpacing = px * 3
        var totalEqW = numB * barSpacing
        var eqStartX = cx - totalEqW / 2.0

        for (var bi = 0; bi < numB; bi++) {
          var barX = eqStartX + bi * barSpacing
          var bVal = root.currentBands[bi] || 0.0
          var pVal = root.peakHold[bi] || 0.0

          // Calculate height of frequency spire
          var maxBarHeight = 24.0 + beat * 14.0
          var barH = Math.max(px, Math.floor((bVal * maxBarHeight) / px) * px)
          var peakH = Math.max(px, Math.floor((pVal * maxBarHeight) / px) * px)

          // Color based on frequency & position
          var isInner = Math.abs(bi - 7.5) < 3.5
          var barColor = isInner ? (beat > 0.3 ? cCore : cDiskHot) : cEq

          // Draw vertical frequency pillar shooting out of accretion disk
          for (var bh = 0; bh < barH; bh += px) {
            pset(barX, cy - bh - px, barColor)
            pset(barX, cy + bh + px, cDiskCold)
          }

          // Peak-hold floating pixel cap
          if (peakH > px) {
            pset(barX, cy - peakH - px * 2, cCore)
          }
        }

        // 9. EQUATORIAL ACCRETION DISK (Front Crossing Belt)
        var diskWidth = 115 + energy * 45.0 + bass * 25.0
        for (var dx = -diskWidth; dx <= diskWidth; dx += px) {
          var curX = cx + dx
          var normDist = dx / diskWidth
          var absDist = Math.abs(normDist)

          var bIdx = Math.min(numB - 1, Math.floor(absDist * numB))
          var bEnergy = root.currentBands[bIdx] || 0.0

          var baseThick = (3.2 + mid * 4.0 + bEnergy * 6.0 + beat * 4.0) * (1.0 - absDist * 0.55)
          var isApproaching = dx < 0
          var dopplerBoost = isApproaching ? (1.35 + mid * 0.4) : 0.65

          for (var dy = cy - baseThick; dy <= cy + baseThick; dy += px) {
            var distFromEquator = Math.abs(dy - cy) / Math.max(1, baseThick)
            var pCol
            if (distFromEquator < 0.28 && dopplerBoost > 1.1) {
              pCol = cCore // White-hot core stream
            } else if (distFromEquator < 0.65) {
              pCol = isApproaching ? cDiskHot : cDiskMid
            } else {
              pCol = isApproaching ? cDiskMid : cDiskCold
            }

            if (Math.random() < (0.85 + high * 0.15)) {
              pset(curX, dy, pCol)
            }
          }
        }

        // 10. SWIRLING ACCRETION PARTICLES (Front half: swirling across the front of the hole)
        for (var pfi = 0; pfi < particles.length; pfi++) {
          var pf = particles[pfi]
          if (Math.sin(pf.angle) >= 0) {
            var pfX = cx + Math.cos(pf.angle) * pf.r
            var pfY = cy + Math.sin(pf.angle) * (pf.r * 0.26)
            var pfDoppler = (pfX < cx) ? 1.4 : 0.75
            var pfCol = (pfDoppler > 1.2) ? cCore : ((pfDoppler > 0.9) ? cDiskHot : cDiskMid)

            // Motion blur trail on heavy beats
            if (beat > 0.3) {
              var trailX = pfX - Math.sin(pf.angle) * (px * 2)
              var trailY = pfY + Math.cos(pf.angle) * (px * 0.5)
              pset(trailX, trailY, cDiskCold)
            }

            pset(pfX, pfY, pfCol)
            if (pf.size > 1 && beat > 0.2) {
              pset(pfX + px, pfY, cDiskHot)
            }
          }
        }

        // 11. POLAR RELATIVISTIC JETS (Blinding laser beams erupting vertically on kicks)
        if (beat > 0.2 || bass > 0.6) {
          var jetLen = 16 + bass * 20.0 + beat * 14.0
          for (var j = 0; j < jetLen; j += px) {
            var jSpread = (j / jetLen) * (px * 2.5)
            var jxTop = cx + (Math.random() - 0.5) * jSpread
            var jyTop = (cy - rHole) - j
            pset(jxTop, jyTop, Math.random() > 0.3 ? cCore : cJet)

            var jxBot = cx + (Math.random() - 0.5) * jSpread
            var jyBot = (cy + rHole) + j
            pset(jxBot, jyBot, Math.random() > 0.3 ? cCore : cJet)
          }
        }
      }
    }

    // Silky Smooth 40 FPS Visualizer Engine & Physics Step
    Timer {
      id: animTimer
      interval: 25 // 40 FPS ultra-responsive loop
      running: root.visible && root.active
      repeat: true
      onTriggered: {
        waveCanvas_step()
      }
    }

    function waveCanvas_step() {
      // 1. Interpolate frequency bands with snappy attack & smooth decay
      var cb = root.currentBands
      var tb = root.targetBands
      var ph = root.peakHold
      var nextB = []
      var nextPh = []
      var len = Math.max(cb.length, tb.length)

      for (var i = 0; i < len; i++) {
        var target = (tb && tb[i] !== undefined) ? tb[i] : 0.0
        var cur = (cb && cb[i] !== undefined) ? cb[i] : 0.0
        var factor = target > cur ? 0.65 : 0.22 // Snappy fast attack
        var updated = cur + (target - cur) * factor
        nextB.push(updated)

        // Peak-hold physics (gravity drop)
        var oldPeak = (ph && ph[i] !== undefined) ? ph[i] : 0.0
        if (updated > oldPeak) {
          nextPh.push(updated)
        } else {
          nextPh.push(Math.max(0.0, oldPeak - 0.038))
        }
      }
      root.currentBands = nextB
      root.peakHold = nextPh

      // 2. Interpolate audio scalars
      var aFactor = 0.45
      root.currentBass += (root.targetBass - root.currentBass) * aFactor
      root.currentMid += (root.targetMid - root.currentMid) * aFactor
      root.currentHigh += (root.targetHigh - root.currentHigh) * aFactor
      root.currentEnergy += (root.targetEnergy - root.currentEnergy) * aFactor

      // 3. Beat physics: spring elastic snapback
      if (root.beatPulse > 0.01) {
        root.beatPulse *= 0.84
      } else {
        root.beatPulse = 0.0
      }

      root.springScale += (1.0 - root.springScale) * 0.24
      root.shakeX *= 0.68
      root.shakeY *= 0.68

      holeCanvas.timeStep += 0.06
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
      opacity: 0.9

      Rectangle {
        width: 7
        height: 7
        radius: 3.5
        anchors.verticalCenter: parent.verticalCenter
        color: root.beatPulse > 0.3 ? "#ffffff" : (root.colorTheme === 1 ? "#67e8f9" : (root.colorTheme === 2 ? "#fb923c" : "#f59e0b"))

        SequentialAnimation on scale {
          running: root.beatPulse > 0.4
          NumberAnimation { from: 1.0; to: 1.6; duration: 60 }
          NumberAnimation { from: 1.6; to: 1.0; duration: 120 }
        }
      }

      Text {
        text: root.colorTheme === 1 ? "QUANTUM GARGANTUA" : (root.colorTheme === 2 ? "SOLAR GARGANTUA" : "GARGANTUA 8-BIT")
        color: root.colorTheme === 1 ? "#67e8f9" : (root.colorTheme === 2 ? "#fb923c" : "#f59e0b")
        font.pixelSize: 9
        font.bold: true
        font.family: "monospace"
      }
    }
  }
}
