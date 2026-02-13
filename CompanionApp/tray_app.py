"""System tray icon for SpotifyControl companion app."""

import logging
import time
import threading
from PIL import Image, ImageDraw

try:
    import pystray
    HAS_PYSTRAY = True
except ImportError:
    HAS_PYSTRAY = False

logger = logging.getLogger("SpotifyControl.tray")


def create_circle_icon(color=(29, 185, 84), size=64):
    """Create a simple colored circle icon for the system tray."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dc = ImageDraw.Draw(image)
    margin = size // 8
    dc.ellipse(
        [margin, margin, size - margin, size - margin],
        fill=color,
    )
    return image


class TrayApp:
    """System tray application for SpotifyControl companion."""

    STATUS_GREEN = (29, 185, 84)
    STATUS_YELLOW = (255, 200, 0)
    STATUS_RED = (200, 50, 50)

    def __init__(self, spotify_client, bridge, on_quit_callback=None):
        if not HAS_PYSTRAY:
            logger.warning("pystray not installed. System tray icon disabled.")
            self.icon = None
            return

        self.spotify = spotify_client
        self.bridge = bridge
        self.on_quit_callback = on_quit_callback
        self.icon = None

    def _build_menu(self):
        return pystray.Menu(
            pystray.MenuItem("SpotifyControl Companion", None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Play / Pause", self._on_toggle),
            pystray.MenuItem("Next Track", self._on_next),
            pystray.MenuItem("Previous Track", self._on_prev),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Volume Up", self._on_vol_up),
            pystray.MenuItem("Volume Down", self._on_vol_down),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Force Status Refresh", self._on_refresh),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Quit", self._on_quit),
        )

    def _on_toggle(self, icon, item):
        self.spotify.execute_command("TOGGLE")
        self.bridge._write_status()

    def _on_next(self, icon, item):
        self.spotify.execute_command("NEXT")
        time.sleep(0.5)
        self.bridge._write_status()

    def _on_prev(self, icon, item):
        self.spotify.execute_command("PREV")
        time.sleep(0.5)
        self.bridge._write_status()

    def _on_vol_up(self, icon, item):
        self.spotify.execute_command("VOL_UP")
        self.bridge._write_status()

    def _on_vol_down(self, icon, item):
        self.spotify.execute_command("VOL_DOWN")
        self.bridge._write_status()

    def _on_refresh(self, icon, item):
        self.bridge._write_status()
        logger.info("Manual status refresh triggered from tray.")

    def _on_quit(self, icon, item):
        logger.info("Quit requested from tray.")
        self.bridge.stop()
        icon.stop()
        if self.on_quit_callback:
            self.on_quit_callback()

    def set_status(self, status):
        """Update tray icon color: 'connected', 'waiting', 'error'."""
        if not self.icon:
            return
        color_map = {
            "connected": self.STATUS_GREEN,
            "waiting": self.STATUS_YELLOW,
            "error": self.STATUS_RED,
        }
        color = color_map.get(status, self.STATUS_GREEN)
        self.icon.icon = create_circle_icon(color)

    def run(self):
        """Run the tray icon (blocks the calling thread)."""
        if not HAS_PYSTRAY:
            logger.warning("Cannot start tray: pystray not available.")
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                self.bridge.stop()
            return

        self.icon = pystray.Icon(
            name="SpotifyControl",
            icon=create_circle_icon(self.STATUS_GREEN),
            title="SpotifyControl Companion",
            menu=self._build_menu(),
        )
        logger.info("System tray icon started. Right-click for controls.")
        self.icon.run()
