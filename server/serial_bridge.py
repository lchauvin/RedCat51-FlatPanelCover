"""
Thread-safe serial bridge to the Arduino Mega firmware.

All public methods block until the Arduino responds (or timeout), and are
protected by a single re-entrant lock so Flask threads don't stomp on each
other.
"""

import threading
import time
import logging
from typing import Optional

import serial

from . import config

log = logging.getLogger(__name__)


class SerialBridgeError(Exception):
    """Raised when a serial command fails or the device is not connected."""


class SerialBridge:
    def __init__(self):
        self._lock   = threading.RLock()
        self._serial: Optional[serial.Serial] = None
        self._connected = False

    # ── Connection management ──────────────────────────────────────────────

    @property
    def connected(self) -> bool:
        return self._connected

    def connect(self, port: Optional[str] = None, baudrate: Optional[int] = None) -> None:
        port     = port     or config.SERIAL_PORT
        baudrate = baudrate or config.SERIAL_BAUDRATE
        with self._lock:
            if self._connected:
                return
            log.info("Opening serial port %s @ %d baud", port, baudrate)
            try:
                self._serial = serial.Serial(
                    port=port,
                    baudrate=baudrate,
                    timeout=config.SERIAL_TIMEOUT,
                )
                # Arduino resets on serial open — wait for it to boot
                time.sleep(2.0)
                self._serial.reset_input_buffer()
                # Verify communication
                resp = self._send_raw("COMMAND:PING")
                if not resp.startswith("RESULT:PING:OK:"):
                    raise SerialBridgeError(f"Unexpected PING response: {resp!r}")
                self._connected = True
                log.info("Connected to firmware: %s", resp.strip())
            except serial.SerialException as exc:
                self._serial = None
                raise SerialBridgeError(str(exc)) from exc

    def disconnect(self) -> None:
        with self._lock:
            if self._serial and self._serial.is_open:
                try:
                    self._serial.close()
                except Exception:
                    pass
            self._serial    = None
            self._connected = False
            log.info("Disconnected from serial port")

    # ── Low-level send/receive ─────────────────────────────────────────────

    def _send_raw(self, command: str) -> str:
        """Send a command line and return the response line. NOT thread-safe — caller must hold lock."""
        if not self._serial or not self._serial.is_open:
            raise SerialBridgeError("Serial port is not open")
        self._serial.write((command + "\n").encode("ascii"))
        self._serial.flush()
        line = self._serial.readline().decode("ascii", errors="replace").strip()
        if not line:
            raise SerialBridgeError(f"Timeout waiting for response to: {command!r}")
        return line

    def _cmd(self, command: str) -> str:
        """Thread-safe wrapper around _send_raw."""
        with self._lock:
            if not self._connected:
                raise SerialBridgeError("Not connected")
            return self._send_raw(command)

    # ── High-level API ─────────────────────────────────────────────────────

    def calibrator_on(self, brightness: int) -> None:
        """Turn LEDs on at 0-640 brightness."""
        brightness = max(0, min(config.MAX_BRIGHTNESS, brightness))
        resp = self._cmd(f"COMMAND:CALIBRATOR:ON:{brightness}")
        if resp != "RESULT:CALIBRATOR:ON:OK":
            raise SerialBridgeError(f"calibrator_on failed: {resp!r}")

    def calibrator_off(self) -> None:
        """Turn LEDs off."""
        resp = self._cmd("COMMAND:CALIBRATOR:OFF")
        if resp != "RESULT:CALIBRATOR:OFF:OK":
            raise SerialBridgeError(f"calibrator_off failed: {resp!r}")

    def get_brightness(self) -> int:
        """Return current brightness (0-255). 0 if off."""
        resp = self._cmd("COMMAND:CALIBRATOR:GETBRIGHTNESS")
        prefix = "RESULT:CALIBRATOR:BRIGHTNESS:"
        if not resp.startswith(prefix):
            raise SerialBridgeError(f"get_brightness unexpected response: {resp!r}")
        return int(resp[len(prefix):])

    def open_cover(self) -> None:
        resp = self._cmd("COMMAND:COVER:OPEN")
        if resp != "RESULT:COVER:OPEN:OK":
            raise SerialBridgeError(f"open_cover failed: {resp!r}")

    def close_cover(self) -> None:
        resp = self._cmd("COMMAND:COVER:CLOSE")
        if resp != "RESULT:COVER:CLOSE:OK":
            raise SerialBridgeError(f"close_cover failed: {resp!r}")

    def halt_cover(self) -> None:
        resp = self._cmd("COMMAND:COVER:HALT")
        if resp != "RESULT:COVER:HALT:OK":
            raise SerialBridgeError(f"halt_cover failed: {resp!r}")

    def get_cover_state(self) -> str:
        """Return 'OPEN', 'CLOSED', or 'MOVING'."""
        resp = self._cmd("COMMAND:COVER:GETSTATE")
        prefix = "RESULT:COVER:STATE:"
        if not resp.startswith(prefix):
            raise SerialBridgeError(f"get_cover_state unexpected response: {resp!r}")
        return resp[len(prefix):]

    def get_info(self) -> str:
        resp = self._cmd("COMMAND:INFO")
        return resp.replace("RESULT:INFO:", "", 1)
