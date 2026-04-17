"""
Configuration for the RedCat 51 Flat Panel Alpaca server.
Override defaults via CLI arguments (see main.py) or environment variables.
"""

import os

# Serial connection to Arduino Mega
SERIAL_PORT     = os.environ.get("FLATPANEL_SERIAL_PORT", "COM3")
SERIAL_BAUDRATE = int(os.environ.get("FLATPANEL_BAUDRATE", "57600"))
SERIAL_TIMEOUT  = float(os.environ.get("FLATPANEL_SERIAL_TIMEOUT", "2.0"))

# Alpaca HTTP server
ALPACA_HOST = os.environ.get("FLATPANEL_HOST", "0.0.0.0")
ALPACA_PORT = int(os.environ.get("FLATPANEL_PORT", "11111"))

# Alpaca discovery (UDP)
DISCOVERY_PORT = 32227

# Device identity (must be a valid GUID; keep stable across runs)
DEVICE_GUID    = os.environ.get(
    "FLATPANEL_GUID", "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
)
DEVICE_NUMBER  = 0
DEVICE_NAME    = "RedCat51 Flat Panel"
DEVICE_TYPE    = "CoverCalibrator"
DEVICE_DESC    = "DIY LED flat panel with motorized cover for William Optics RedCat 51"
DEVICE_DRIVER  = "RedCat51FlatPanel/1.0"
SERVER_NAME    = "RedCat51FlatPanel Alpaca Server"
MANUFACTURER   = "DIY"
MANUFACTURER_VER = "1.0"
LOCATION       = ""

MAX_BRIGHTNESS = 255
