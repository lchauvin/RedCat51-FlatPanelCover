"""
Integration tests for the Alpaca REST endpoints.

Uses Flask's test client — no real serial port or Arduino needed.
The SerialBridge is replaced with a mock.
"""

import sys
import types
import json
import unittest
from unittest.mock import MagicMock, patch

# Stub pyserial so import works without it installed
serial_stub = types.ModuleType("serial")
serial_stub.Serial = MagicMock
serial_stub.SerialException = OSError
sys.modules.setdefault("serial", serial_stub)

from server.alpaca_server import create_app  # noqa: E402
from server.serial_bridge import SerialBridgeError  # noqa: E402


def _make_client(connected: bool = True, **bridge_attrs):
    bridge = MagicMock()
    bridge.connected = connected
    for k, v in bridge_attrs.items():
        setattr(bridge, k, v)
    app = create_app(bridge)
    app.config["TESTING"] = True
    return app.test_client(), bridge


BASE = "/api/v1/covercalibrator/0"


class TestManagement(unittest.TestCase):
    def setUp(self):
        self.client, _ = _make_client()

    def _json(self, path):
        return json.loads(self.client.get(path).data)

    def test_api_versions(self):
        body = self._json("/management/apiversions")
        self.assertEqual(body["Value"], [1])
        self.assertEqual(body["ErrorNumber"], 0)

    def test_description(self):
        body = self._json("/management/v1/description")
        self.assertIn("ServerName", body["Value"])

    def test_configured_devices(self):
        body = self._json("/management/v1/configureddevices")
        dev = body["Value"][0]
        self.assertEqual(dev["DeviceType"], "CoverCalibrator")
        self.assertEqual(dev["DeviceNumber"], 0)


class TestConnected(unittest.TestCase):
    def test_get_connected_true(self):
        client, _ = _make_client(connected=True)
        body = json.loads(client.get(f"{BASE}/connected").data)
        self.assertTrue(body["Value"])
        self.assertEqual(body["ErrorNumber"], 0)

    def test_get_connected_false(self):
        client, _ = _make_client(connected=False)
        body = json.loads(client.get(f"{BASE}/connected").data)
        self.assertFalse(body["Value"])

    def test_put_connected_true_calls_connect(self):
        client, bridge = _make_client(connected=False)
        client.put(f"{BASE}/connected", data={"Connected": "True"})
        bridge.connect.assert_called_once()

    def test_put_connected_false_calls_disconnect(self):
        client, bridge = _make_client(connected=True)
        client.put(f"{BASE}/connected", data={"Connected": "False"})
        bridge.disconnect.assert_called_once()

    def test_put_connected_invalid_value(self):
        client, _ = _make_client()
        resp = client.put(f"{BASE}/connected", data={"Connected": "maybe"})
        body = json.loads(resp.data)
        self.assertNotEqual(body["ErrorNumber"], 0)


class TestCalibrator(unittest.TestCase):
    def test_maxbrightness(self):
        client, _ = _make_client()
        body = json.loads(client.get(f"{BASE}/maxbrightness").data)
        self.assertEqual(body["Value"], 255)

    def test_brightness(self):
        client, bridge = _make_client(connected=True)
        bridge.get_brightness.return_value = 128
        body = json.loads(client.get(f"{BASE}/brightness").data)
        self.assertEqual(body["Value"], 128)

    def test_brightness_not_connected(self):
        client, _ = _make_client(connected=False)
        body = json.loads(client.get(f"{BASE}/brightness").data)
        self.assertNotEqual(body["ErrorNumber"], 0)

    def test_calibratorstate_off(self):
        client, bridge = _make_client(connected=True)
        bridge.get_brightness.return_value = 0
        body = json.loads(client.get(f"{BASE}/calibratorstate").data)
        self.assertEqual(body["Value"], 1)  # CAL_OFF

    def test_calibratorstate_ready(self):
        client, bridge = _make_client(connected=True)
        bridge.get_brightness.return_value = 100
        body = json.loads(client.get(f"{BASE}/calibratorstate").data)
        self.assertEqual(body["Value"], 3)  # CAL_READY

    def test_calibratoron(self):
        client, bridge = _make_client(connected=True)
        resp = client.put(f"{BASE}/calibratoron", data={"Brightness": "200"})
        body = json.loads(resp.data)
        self.assertEqual(body["ErrorNumber"], 0)
        bridge.calibrator_on.assert_called_once_with(200)

    def test_calibratoron_invalid(self):
        client, _ = _make_client(connected=True)
        body = json.loads(
            client.put(f"{BASE}/calibratoron", data={"Brightness": "300"}).data
        )
        self.assertNotEqual(body["ErrorNumber"], 0)

    def test_calibratoron_not_integer(self):
        client, _ = _make_client(connected=True)
        body = json.loads(
            client.put(f"{BASE}/calibratoron", data={"Brightness": "abc"}).data
        )
        self.assertNotEqual(body["ErrorNumber"], 0)

    def test_calibratoroff(self):
        client, bridge = _make_client(connected=True)
        body = json.loads(client.put(f"{BASE}/calibratoroff").data)
        self.assertEqual(body["ErrorNumber"], 0)
        bridge.calibrator_off.assert_called_once()

    def test_calibratoron_bridge_error(self):
        client, bridge = _make_client(connected=True)
        bridge.calibrator_on.side_effect = SerialBridgeError("timeout")
        body = json.loads(
            client.put(f"{BASE}/calibratoron", data={"Brightness": "100"}).data
        )
        self.assertNotEqual(body["ErrorNumber"], 0)
        self.assertIn("timeout", body["ErrorMessage"])


class TestCover(unittest.TestCase):
    def test_coverstate_open(self):
        client, bridge = _make_client(connected=True)
        bridge.get_cover_state.return_value = "OPEN"
        body = json.loads(client.get(f"{BASE}/coverstate").data)
        self.assertEqual(body["Value"], 3)  # COVER_OPEN

    def test_coverstate_closed(self):
        client, bridge = _make_client(connected=True)
        bridge.get_cover_state.return_value = "CLOSED"
        body = json.loads(client.get(f"{BASE}/coverstate").data)
        self.assertEqual(body["Value"], 1)  # COVER_CLOSED

    def test_coverstate_moving(self):
        client, bridge = _make_client(connected=True)
        bridge.get_cover_state.return_value = "MOVING"
        body = json.loads(client.get(f"{BASE}/coverstate").data)
        self.assertEqual(body["Value"], 2)  # COVER_MOVING

    def test_opencover(self):
        client, bridge = _make_client(connected=True)
        body = json.loads(client.put(f"{BASE}/opencover").data)
        self.assertEqual(body["ErrorNumber"], 0)
        bridge.open_cover.assert_called_once()

    def test_closecover(self):
        client, bridge = _make_client(connected=True)
        body = json.loads(client.put(f"{BASE}/closecover").data)
        self.assertEqual(body["ErrorNumber"], 0)
        bridge.close_cover.assert_called_once()

    def test_haltcover(self):
        client, bridge = _make_client(connected=True)
        body = json.loads(client.put(f"{BASE}/haltcover").data)
        self.assertEqual(body["ErrorNumber"], 0)
        bridge.halt_cover.assert_called_once()

    def test_cover_not_connected(self):
        client, _ = _make_client(connected=False)
        body = json.loads(client.get(f"{BASE}/coverstate").data)
        self.assertNotEqual(body["ErrorNumber"], 0)

    def test_cover_bridge_error(self):
        client, bridge = _make_client(connected=True)
        bridge.open_cover.side_effect = SerialBridgeError("no response")
        body = json.loads(client.put(f"{BASE}/opencover").data)
        self.assertNotEqual(body["ErrorNumber"], 0)


class TestUnimplemented(unittest.TestCase):
    def test_action(self):
        client, _ = _make_client()
        body = json.loads(client.put(f"{BASE}/action").data)
        self.assertNotEqual(body["ErrorNumber"], 0)


if __name__ == "__main__":
    unittest.main()
