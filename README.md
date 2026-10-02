# OmaOpus 󱑽

A minimalist, lightweight YouTube & online music player plugin for **Omarchy OS**.

OmaOpus docks into your Omarchy status bar with a clean, modern icon, hover details, interactive YouTube search, live queue viewer, persistent favorites, instant session restart, and subtle audio feedback.

---

## ✨ Features

- **Minimalist Top Bar Icon**:
  - Uncluttered status bar: icon-only widget (`󱑽` / `󱑼`) with active accent indicator and animated spinner when loading.
  - Hover tooltip displays current playing track and artist without eating up bar width.
- **Interactive Popup Widget**:
  - **󰍉 Search**: Direct YouTube & music search with instant stream playback.
  - **󰒮 Queue**: Inspect live playlist queue, active track, and one-click clear (`󰅖`).
  - **󰋑 Favorites**: One-click hearting (`󰋔` / `󰋑`) to save favorite songs permanently.
- **Session & Daemon Controls**:
  - **Restart Session (`󰑐`)**: Restarts background audio engine and resets network/bot limits in one click.
  - Smooth interactive volume slider.
- **Sound Effects**: Desktop audio cues for play, pause, queueing, favoriting, and restarts.
- **Ultra-low Resource Footprint**: Direct lightweight daemon engine (<15MB RAM, ~0% idle CPU).

---

## 🛠️ Requirements

- **Omarchy OS** (Hyprland + Quickshell)
- `mpv` (pre-installed on Omarchy)
- `yt-dlp` (pre-installed on Omarchy)
- `socat`
- `jq`
- `canberra-gtk-play` (for audio feedback)

---

## 🚀 Installation

### Option 1: Link into Omarchy Plugins

```bash
git clone https://github.com/MaenExists/omaopus.git ~/Builds/OmaOpus
mkdir -p ~/.config/omarchy/plugins
ln -sfn ~/Builds/OmaOpus ~/.config/omarchy/plugins/maen.omaopus
```

### Option 2: Add to Omarchy Bar

Edit `~/.config/omarchy/shell.json`:

```json
{
  "bar": {
    "layout": {
      "right": [
        { "id": "maen.omaopus" },
        { "id": "omarchy.tray" }
      ]
    }
  }
}
```

Omarchy shell hot-reloads automatically on save!

---

## 🎮 Controls

- **Left-Click Bar Icon**: Toggle the OmaOpus popup.
- **Right-Click Bar Icon**: Quick play / pause toggle.
- **Keyboard Navigation**:
  - `↵ Play`: Start playing selected track.
  - `↑ / ↓`: Navigate search results.
  - `Esc`: Close popup.

---

## 📄 License

MIT © [MaenExists](https://github.com/MaenExists)
