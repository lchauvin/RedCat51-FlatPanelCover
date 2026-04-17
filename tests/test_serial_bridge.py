"""
Unit tests for SerialBridge.

Uses unittest.mock to simulate the serial port so no Arduino is required.
"""

import sys
import types
import unittest
from typing import List
from unittest.mock import MagicMock, patch, call

# ---------------------------------------------------------------------------
# Stub out the `serial` package so tests run without pyserial installed
# ---------------------------------------------------------------------------
serial_stub = types.ModuleType("serial")
serial_stub.Serial = MagicMock
serial_stub.SerialException = OSError
sys.modules.setdefault("serial", serial_stub)

from server.serial_bridge import SerialBridge, SerialBridgeError  # noqa: E402


def _make_bridge_connected(responses: List[str]) -> SerialBridge:
    """Return a SerialBridge whose serial port replies with *responses* in order."""
    bridge = SerialBridge()
    mock_serial = MagicMock()
    mock_serial.is_open = True

    # readline returns bytes; cycle through responses
    response_iter = iter(
        [(r + "\n").encode("ascii") for r in responses]
    )
    mock_serial.readline.side_effect = lambda: next(response_iter)

    bridge._serial    = mock_serial
    bridge._connected = True
    return bridge, mock_serial


class TestSerialBridgeConnect(unittest.TestCase):
    @patch("server.serial_bridge.serial.Serial")
    @patch("server.serial_bridge.time.sleep")  # skip the 2 s Arduino boot wait
    def test_connect_success(self, mock_sleep, MockSerial):
        mock_port = MagicMock()
        mock_port.is_open = True
        mock_port.readline.return_value = b"RESULT:PING:OK:GUID\n"
        MockSerial.return_value = mock_port

        bridge = SerialBridge()
        bridge.connect(port="COM3", baudrate=57600)

        self.assertTrue(bridge.connected)

    @patch("server.serial_bridge.serial.Serial")
    @patch("server.serial_bridge.time.sleep")
    def test_connect_bad_ping(self, mock_sleep, MockSerial):
        mock_port = MagicMock()
        mock_port.is_open = True
        mock_port.readline.return_value = b"GARBAGE\n"
        MockSerial.return_value = mock_port

        bridge = SerialBridge()
        with self.assertRaises(SerialBridgeError):
            bridge.connect(port="COM3", baudrate=57600)

        self.assertFalse(bridge.connected)

    @patch("server.serial_bridge.serial.Serial", side_effect=OSError("port not found"))
    @patch("server.serial_bridge.time.sleep")
    def test_connect_serial_exception(self, mock_sleep, MockSerial):
        bridge = SerialBridge()
        with self.assertRaises(SerialBridgeError):
            bridge.connect(port="COMX")
        self.assertFalse(bridge.connected)


class TestSerialBridgeCommands(unittest.TestCase):
    def test_calibrator_on(self):
        bridge, mock_serial = _make_bridge_connected(["RESULT:CALIBRATOR:ON:OK"])
        bridge.calibrator_on(128)
        mock_serial.write.assert_called_once_with(b"COMMAND:CALIBRATOR:ON:128\n")

    def test_calibrator_on_clamps(self):
        bridge, _ = _make_bridge_connected(["RESULT:CALIBRATOR:ON:OK"])
        bridge.calibrator_on(300)  # should clamp to 255, no exception

    def test_calibrator_off(self):
        bridge, mock_serial = _make_bridge_connected(["RESULT:CALIBRATOR:OFF:OK"])
        bridge.calibrator_off()
        mock_serial.write.assert_called_once_with(b"COMMAND:CALIBRATOR:OFF\n")

    def test_get_brightness(self):
        bridge, _ = _make_bridge_connected(["RESULT:CALIBRATOR:BRIGHTNESS:200"])
        self.assertEqual(bridge.get_brightness(), 200)

    def test_open_cover(self):
        bridge, mock_serial = _make_bridge_connected(["RESULT:COVER:OPEN:OK"])
        bridge.open_cover()
        mock_serial.write.assert_called_once_with(b"COMMAND:COVER:OPEN\n")

    def test_close_cover(self):
        bridge, mock_serial = _make_bridge_connected(["RESULT:COVER:CLOSE:OK"])
        bridge.close_cover()
        mock_serial.write.assert_called_once_with(b"COMMAND:COVER:CLOSE\n")

    def test_halt_cover(self):
        bridge, mock_serial = _make_bridge_connected(["RESULT:COVER:HALT:OK"])
        bridge.halt_cover()
        mock_serial.write.assert_called_once_with(b"COMMAND:COVER:HALT\n")

    def test_get_cover_state_open(self):
        bridge, _ = _make_bridge_connected(["RESULT:COVER:STATE:OPEN"])
        self.assertEqual(bridge.get_cover_state(), "OPEN")

    def test_get_cover_state_closed(self):
        bridge, _ = _make_bridge_connected(["RESULT:COVER:STATE:CLOSED"])
        self.assertEqual(bridge.get_cover_state(), "CLOSED")

    def test_error_on_unexpected_response(self):
        bridge, _ = _make_bridge_connected(["RESULT:COVER:STATE:CLOSED"])
        # The response is consumed; next call will get nothing — timeout
        bridge._serial.readline.side_effect = lambda: b""
        with self.assertRaises(SerialBridgeError):
            bridge.calibrator_on(100)

    def test_not_connected_raises(self):
        bridge = SerialBridge()
        with self.assertRaises(SerialBridgeError):
            bridge.calibrator_on(100)


if __name__ == "__main__":
    unittest.main()
