"""Spotify Web API client wrapper using spotipy."""

import logging
import spotipy
from spotipy.oauth2 import SpotifyOAuth

logger = logging.getLogger("SpotifyControl.spotify")

SCOPES = (
    "user-read-playback-state "
    "user-modify-playback-state "
    "user-read-currently-playing"
)


class SpotifyClient:
    """Thin wrapper around spotipy for the SpotifyControl command set."""

    def __init__(self, client_id, client_secret, redirect_uri,
                 cache_path=".spotify_cache", volume_step=10):
        self.volume_step = volume_step
        self.auth_manager = SpotifyOAuth(
            client_id=client_id,
            client_secret=client_secret,
            redirect_uri=redirect_uri,
            scope=SCOPES,
            cache_path=cache_path,
            open_browser=True,
        )
        self.sp = spotipy.Spotify(auth_manager=self.auth_manager)
        logger.info("Spotify client initialized.")

    def get_playback_state(self):
        """
        Fetch current Spotify playback state.
        Returns a dict matching the SpotifyControlData schema.
        """
        try:
            state = self.sp.current_playback()
            if not state:
                return {
                    "connected": True,
                    "is_playing": False,
                    "track_name": "",
                    "artist_name": "",
                    "album_name": "",
                    "track_duration_ms": 0,
                    "track_progress_ms": 0,
                    "volume_percent": 0,
                    "shuffle_state": False,
                    "repeat_state": "off",
                    "device_name": "No active device",
                    "error_message": "No active playback session. Open Spotify on a device.",
                }

            track = state.get("item") or {}
            artists = ", ".join(
                a.get("name", "Unknown") for a in track.get("artists", [])
            )

            return {
                "connected": True,
                "is_playing": state.get("is_playing", False),
                "track_name": track.get("name", "Unknown"),
                "artist_name": artists or "Unknown",
                "album_name": track.get("album", {}).get("name", "Unknown"),
                "track_duration_ms": track.get("duration_ms", 0),
                "track_progress_ms": state.get("progress_ms", 0),
                "volume_percent": state.get("device", {}).get("volume_percent", 50),
                "shuffle_state": state.get("shuffle_state", False),
                "repeat_state": state.get("repeat_state", "off"),
                "device_name": state.get("device", {}).get("name", "Unknown"),
                "error_message": "",
            }
        except spotipy.exceptions.SpotifyException as e:
            logger.error(f"Spotify API error: {e}")
            return {"connected": False, "error_message": str(e)}
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            return {"connected": False, "error_message": str(e)}

    def execute_command(self, cmd, args=""):
        """Execute a playback command. Returns True on success."""
        try:
            if cmd == "PLAY":
                self.sp.start_playback()
            elif cmd == "PAUSE":
                self.sp.pause_playback()
            elif cmd == "TOGGLE":
                state = self.sp.current_playback()
                if state and state.get("is_playing"):
                    self.sp.pause_playback()
                else:
                    self.sp.start_playback()
            elif cmd == "NEXT":
                self.sp.next_track()
            elif cmd == "PREV":
                self.sp.previous_track()
            elif cmd == "VOL_UP":
                self._adjust_volume(self.volume_step)
            elif cmd == "VOL_DOWN":
                self._adjust_volume(-self.volume_step)
            elif cmd == "VOL_SET":
                vol = max(0, min(100, int(args)))
                self.sp.volume(vol)
            elif cmd == "SHUFFLE_ON":
                self.sp.shuffle(True)
            elif cmd == "SHUFFLE_OFF":
                self.sp.shuffle(False)
            elif cmd == "REPEAT_OFF":
                self.sp.repeat("off")
            elif cmd == "REPEAT_TRACK":
                self.sp.repeat("track")
            elif cmd == "REPEAT_CONTEXT":
                self.sp.repeat("context")
            else:
                logger.warning(f"Unknown command: {cmd}")
                return False

            logger.info(f"Executed: {cmd} {args}")
            return True

        except spotipy.exceptions.SpotifyException as e:
            logger.error(f"Spotify API error executing {cmd}: {e}")
            return False
        except Exception as e:
            logger.error(f"Error executing {cmd}: {e}")
            return False

    def _adjust_volume(self, delta):
        """Get current volume, adjust by delta, clamp to 0-100."""
        state = self.sp.current_playback()
        if state and state.get("device"):
            current = state["device"].get("volume_percent", 50)
            new_vol = max(0, min(100, current + delta))
            self.sp.volume(new_vol)
            logger.debug(f"Volume: {current} -> {new_vol}")
        else:
            logger.warning("No active device for volume adjustment.")
