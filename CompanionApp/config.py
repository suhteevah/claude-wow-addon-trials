"""Configuration loading and path resolution for SpotifyControl companion."""

import configparser
import os
import sys
import logging
from pathlib import Path

logger = logging.getLogger("SpotifyControl.config")


class Config:
    """Loads and validates config.ini, provides computed paths."""

    def __init__(self, config_path: str = "config.ini"):
        if not os.path.exists(config_path):
            print(f"ERROR: Configuration file not found: {config_path}")
            print("Copy config.ini.example to config.ini and fill in your values.")
            sys.exit(1)

        self.parser = configparser.ConfigParser()
        self.parser.read(config_path, encoding="utf-8")
        self._validate()

    def _validate(self):
        """Check that required config values are present."""
        required = {
            "wow": ["install_path", "game_version", "account_name"],
            "spotify": ["client_id", "client_secret", "redirect_uri"],
        }
        for section, keys in required.items():
            for key in keys:
                val = self.parser.get(section, key, fallback="CHANGE_ME")
                if val == "CHANGE_ME" or not val.strip():
                    print(f"ERROR: config.ini [{section}] {key} is not set.")
                    sys.exit(1)

        if not self.wow_base_path.exists():
            logger.warning(f"WoW base path does not exist: {self.wow_base_path}")

    @property
    def wow_install_path(self) -> Path:
        return Path(self.parser.get("wow", "install_path"))

    @property
    def wow_base_path(self) -> Path:
        return self.wow_install_path / self.parser.get("wow", "game_version")

    @property
    def addon_folder_path(self) -> Path:
        return self.wow_base_path / "Interface" / "AddOns" / "SpotifyControl"

    @property
    def addon_data_file_path(self) -> Path:
        return self.addon_folder_path / "SpotifyControlData.lua"

    @property
    def account_saved_variables_path(self) -> Path:
        account = self.parser.get("wow", "account_name")
        return (
            self.wow_base_path / "WTF" / "Account" / account
            / "SavedVariables" / "SpotifyControl.lua"
        )

    @property
    def saved_variables_watch_path(self) -> Path:
        return self.account_saved_variables_path.parent

    @property
    def spotify_client_id(self) -> str:
        return self.parser.get("spotify", "client_id")

    @property
    def spotify_client_secret(self) -> str:
        return self.parser.get("spotify", "client_secret")

    @property
    def spotify_redirect_uri(self) -> str:
        return self.parser.get("spotify", "redirect_uri")

    @property
    def spotify_cache_path(self) -> str:
        return self.parser.get("spotify", "cache_path", fallback=".spotify_token_cache")

    @property
    def status_refresh_interval(self) -> float:
        return float(self.parser.get("companion", "status_refresh_interval", fallback="5.0"))

    @property
    def volume_step(self) -> int:
        return int(self.parser.get("companion", "volume_step", fallback="10"))

    @property
    def log_level(self) -> str:
        return self.parser.get("companion", "log_level", fallback="INFO")
