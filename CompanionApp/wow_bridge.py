"""Bridge between WoW addon (via SavedVariables files) and Spotify client."""

import os
import time
import logging
import threading
from pathlib import Path

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

from lua_parser import parse_saved_variables_file
from lua_writer import write_spotify_data

logger = logging.getLogger("SpotifyControl.bridge")


class SavedVariablesWatcher(FileSystemEventHandler):
    """Watches for changes to SpotifyControl.lua in the SavedVariables folder."""

    def __init__(self, target_filename, callback):
        super().__init__()
        self.target_filename = target_filename
        self.callback = callback
        self.last_mtime = 0.0
        self._debounce_timer = None

    def on_modified(self, event):
        if event.is_directory:
            return
        if Path(event.src_path).name != self.target_filename:
            return

        try:
            mtime = os.path.getmtime(event.src_path)
        except OSError:
            return

        if mtime == self.last_mtime:
            return
        self.last_mtime = mtime

        if self._debounce_timer:
            self._debounce_timer.cancel()

        # Wait 300ms for the file write to complete before reading
        self._debounce_timer = threading.Timer(
            0.3, self._fire, args=[event.src_path]
        )
        self._debounce_timer.start()

    def _fire(self, filepath):
        logger.info(f"SavedVariables file changed: {filepath}")
        try:
            self.callback(filepath)
        except Exception as e:
            logger.error(f"Error in callback: {e}", exc_info=True)


class WoWBridge:
    """
    Manages bidirectional communication with the WoW addon:
    - Reads commands from SavedVariables (written by addon on /reload)
    - Writes status to SpotifyControlData.lua (read by addon on /reload)
    """

    def __init__(self, config, spotify_client):
        self.config = config
        self.spotify = spotify_client
        self.last_ack_id = 0
        self.observer = None
        self._running = False
        self._status_thread = None

    def start(self):
        """Start file watcher and periodic status writer."""
        self._running = True

        # Write initial status
        self._write_status()

        # Start watching SavedVariables directory
        self._start_watcher()

        # Start periodic status updates
        self._status_thread = threading.Thread(
            target=self._periodic_status_loop,
            daemon=True,
            name="StatusWriter",
        )
        self._status_thread.start()

        logger.info("WoW bridge started.")

    def stop(self):
        """Stop all bridge activities."""
        self._running = False
        if self.observer:
            self.observer.stop()
            self.observer.join(timeout=5)
        logger.info("WoW bridge stopped.")

    def _start_watcher(self):
        """Start watching the SavedVariables directory for changes."""
        watch_dir = self.config.saved_variables_watch_path

        if not watch_dir.exists():
            logger.warning(
                f"SavedVariables directory does not exist yet: {watch_dir}\n"
                f"It will be created when you first log in with the addon enabled.\n"
                f"The companion will detect it when it appears."
            )
            threading.Thread(
                target=self._poll_for_directory,
                args=(watch_dir,),
                daemon=True,
            ).start()
            return

        self._create_observer(watch_dir)

    def _create_observer(self, watch_dir):
        """Create and start the filesystem observer."""
        handler = SavedVariablesWatcher(
            target_filename="SpotifyControl.lua",
            callback=self._on_saved_variables_changed,
        )
        self.observer = Observer()
        self.observer.schedule(handler, str(watch_dir), recursive=False)
        self.observer.start()
        logger.info(f"Watching for SavedVariables changes in: {watch_dir}")

    def _poll_for_directory(self, watch_dir):
        """Poll until the SavedVariables directory exists, then start watching."""
        while self._running and not watch_dir.exists():
            time.sleep(5)
        if self._running and watch_dir.exists():
            logger.info(f"SavedVariables directory appeared: {watch_dir}")
            self._create_observer(watch_dir)

    def _on_saved_variables_changed(self, filepath):
        """Called when SavedVariables/SpotifyControl.lua is modified."""
        try:
            data = parse_saved_variables_file(filepath)
        except Exception as e:
            logger.error(f"Failed to parse SavedVariables: {e}")
            return

        db = data.get("SpotifyControlDB")
        if not db:
            logger.warning("SpotifyControlDB not found in file.")
            return

        command_queue = db.get("commandQueue", [])
        if isinstance(command_queue, dict):
            # slpp may decode array-style tables as dicts with integer keys
            command_queue = [
                command_queue[k]
                for k in sorted(command_queue.keys())
                if isinstance(command_queue[k], dict)
            ]

        # Filter to only new (unacknowledged) commands
        new_commands = []
        for cmd in command_queue:
            cmd_id = cmd.get("id", 0)
            if isinstance(cmd_id, (int, float)) and cmd_id > self.last_ack_id:
                new_commands.append(cmd)

        new_commands.sort(key=lambda c: c.get("id", 0))

        if not new_commands:
            logger.debug("No new commands to process.")
        else:
            logger.info(f"Processing {len(new_commands)} new command(s).")

        for cmd in new_commands:
            cmd_name = cmd.get("cmd", "")
            cmd_args = str(cmd.get("args", ""))
            cmd_id = int(cmd.get("id", 0))

            logger.info(f"  Command #{cmd_id}: {cmd_name} {cmd_args}")
            success = self.spotify.execute_command(cmd_name, cmd_args)

            if success:
                self.last_ack_id = cmd_id
            else:
                logger.error(f"  Command #{cmd_id} failed.")
                self.last_ack_id = cmd_id  # Still acknowledge to prevent retry loops
                break

        # Write updated status immediately after processing
        self._write_status()

    def _write_status(self):
        """Fetch current Spotify state and write SpotifyControlData.lua."""
        state = self.spotify.get_playback_state()
        if state is None:
            state = {
                "connected": False,
                "error_message": "Failed to fetch playback state.",
            }

        # Add companion metadata
        state["last_ack_id"] = self.last_ack_id
        state["companion_version"] = "1.0.0"
        state["updated_at"] = int(time.time())

        addon_data_path = str(self.config.addon_data_file_path)

        addon_dir = self.config.addon_folder_path
        if not addon_dir.exists():
            logger.warning(f"Addon folder does not exist: {addon_dir}")
            return

        write_spotify_data(addon_data_path, state)

    def _periodic_status_loop(self):
        """Periodically refresh Spotify status and write to data file."""
        interval = self.config.status_refresh_interval
        while self._running:
            try:
                self._write_status()
            except Exception as e:
                logger.error(f"Periodic status update failed: {e}")
            time.sleep(interval)
