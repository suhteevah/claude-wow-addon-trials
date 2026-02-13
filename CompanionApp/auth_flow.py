"""First-time Spotify OAuth2 setup wizard."""

import webbrowser


def print_setup_instructions():
    """Print step-by-step instructions for Spotify Developer setup."""
    print()
    print("=" * 60)
    print("  SpotifyControl Companion - First Time Setup")
    print("=" * 60)
    print()
    print("Before you can use SpotifyControl, you need a Spotify")
    print("Developer Application. Here's how to set one up:")
    print()
    print("  1. Go to: https://developer.spotify.com/dashboard")
    print("  2. Log in with your Spotify account")
    print("  3. Click 'Create App'")
    print("  4. Fill in:")
    print("     - App name: SpotifyControl (or anything you like)")
    print("     - App description: WoW addon companion")
    print("     - Redirect URI: http://127.0.0.1:8888/callback")
    print("  5. Click 'Save'")
    print("  6. Click 'Settings' on your new app")
    print("  7. Copy the 'Client ID' and 'Client Secret'")
    print("  8. Paste them into config.ini under [spotify]")
    print()
    print("After filling in config.ini, run this app again.")
    print("A browser window will open asking you to log in to Spotify.")
    print("After authorizing, the companion app will start automatically.")
    print()

    answer = input("Open Spotify Developer Dashboard in browser? (y/n): ")
    if answer.lower().startswith("y"):
        webbrowser.open("https://developer.spotify.com/dashboard")
