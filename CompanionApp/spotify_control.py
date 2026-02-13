"""SpotifyControl Companion App - Main Entry Point.

This application bridges the SpotifyControl WoW addon with the
Spotify Web API. It watches for commands from the addon (via
SavedVariables files) and writes current playback status back
to a Lua file the addon can read.

Usage:
    python spotify_control.py
    python spotify_control.py --setup   (first-time setup wizard)
"""

import sys
import logging
import signal

from config import Config
from spotify_client import SpotifyClient
from wow_bridge import WoWBridge
from tray_app import TrayApp
from auth_flow import print_setup_instructions


def main():
    if "--setup" in sys.argv:
        print_setup_instructions()
        return

    # Load configuration
    try:
        config = Config("config.ini")
    except SystemExit:
        print("\nRun 'python spotify_control.py --setup' for first-time setup.")
        return

    # Set up logging
    logging.basicConfig(
        level=getattr(logging, config.log_level.upper(), logging.INFO),
        format="%(asctime)s [%(name)s] %(levelname)-7s %(message)s",
        datefmt="%H:%M:%S",
    )
    logger = logging.getLogger("SpotifyControl")

    logger.info("=" * 50)
    logger.info("SpotifyControl Companion starting...")
    logger.info("=" * 50)

    # Verify paths
    logger.info(f"WoW base path: {config.wow_base_path}")
    logger.info(f"Addon folder:  {config.addon_folder_path}")
    logger.info(f"SavedVariables watch: {config.saved_variables_watch_path}")

    if not config.addon_folder_path.exists():
        logger.error(
            f"Addon folder not found: {config.addon_folder_path}\n"
            f"Make sure the SpotifyControl addon is installed in your WoW AddOns folder."
        )
        return

    # Initialize Spotify client (triggers OAuth browser flow on first run)
    logger.info("Connecting to Spotify...")
    try:
        spotify = SpotifyClient(
            client_id=config.spotify_client_id,
            client_secret=config.spotify_client_secret,
            redirect_uri=config.spotify_redirect_uri,
            cache_path=config.spotify_cache_path,
            volume_step=config.volume_step,
        )
    except Exception as e:
        logger.error(f"Failed to initialize Spotify client: {e}")
        logger.error("Run 'python spotify_control.py --setup' for setup instructions.")
        return

    # Test Spotify connection
    state = spotify.get_playback_state()
    if state and state.get("connected"):
        track = state.get("track_name", "")
        if track:
            logger.info(
                f"Spotify connected. Currently: {track} - {state.get('artist_name', '')}"
            )
        else:
            logger.info("Spotify connected. No active playback.")
    else:
        logger.warning(
            "Spotify connected but no active session. Open Spotify on a device."
        )

    # Initialize WoW bridge
    bridge = WoWBridge(config, spotify)
    bridge.start()

    # Handle Ctrl+C gracefully
    def signal_handler(sig, frame):
        logger.info("Shutting down...")
        bridge.stop()
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)

    # Run system tray (blocks main thread)
    logger.info("Starting system tray icon...")
    logger.info("Right-click the tray icon for Spotify controls.")
    logger.info("Waiting for commands from WoW addon...")

    tray = TrayApp(
        spotify_client=spotify,
        bridge=bridge,
        on_quit_callback=lambda: sys.exit(0),
    )
    tray.run()


if __name__ == "__main__":
    main()
