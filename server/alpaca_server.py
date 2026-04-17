"""
ASCOM Alpaca CoverCalibrator REST endpoints.

Alpaca spec: https://ascom-standards.org/api/

Cover states (Alpaca enum):
  0 = NotPresent, 1 = Closed, 2 = Moving, 3 = Open, 4 = Unknown, 5 = Error

Calibrator states (Alpaca enum):
  0 = NotPresent, 1 = Off, 2 = NotReady, 3 = Ready, 4 = Unknown, 5 = Error
"""

import logging
from flask import Blueprint, request, jsonify, Flask

from . import config
from .serial_bridge import SerialBridge, SerialBridgeError

log = logging.getLogger(__name__)

# Alpaca error numbers
ALPACA_OK              = 0
ALPACA_NOT_CONNECTED   = 0x407
ALPACA_NOT_IMPLEMENTED = 0x400
ALPACA_VALUE_ERROR     = 0x401
ALPACA_DRIVER_ERROR    = 0x500

# Cover state enum values
COVER_NOT_PRESENT = 0
COVER_CLOSED      = 1
COVER_MOVING      = 2
COVER_OPEN        = 3
COVER_UNKNOWN     = 4
COVER_ERROR       = 5

# Calibrator state enum values
CAL_NOT_PRESENT = 0
CAL_OFF         = 1
CAL_NOT_READY   = 2
CAL_READY       = 3
CAL_UNKNOWN     = 4
CAL_ERROR       = 5


def _cover_state_str_to_int(state_str: str) -> int:
    return {
        "OPEN":   COVER_OPEN,
        "CLOSED": COVER_CLOSED,
        "MOVING": COVER_MOVING,
    }.get(state_str, COVER_UNKNOWN)


def create_app(bridge: SerialBridge) -> Flask:
    app = Flask(__name__)
    app.register_blueprint(_build_management_bp())
    app.register_blueprint(_build_device_bp(bridge))
    return app


# ── Helpers ────────────────────────────────────────────────────────────────

def _ok(value=None, **extra):
    """Build a successful Alpaca response."""
    body = {
        "ClientTransactionID": _client_tid(),
        "ServerTransactionID": _server_tid(),
        "ErrorNumber": ALPACA_OK,
        "ErrorMessage": "",
    }
    if value is not None:
        body["Value"] = value
    body.update(extra)
    return jsonify(body)


def _err(number: int, message: str):
    return jsonify({
        "ClientTransactionID": _client_tid(),
        "ServerTransactionID": _server_tid(),
        "ErrorNumber": number,
        "ErrorMessage": message,
        "Value": 0,
    })


_server_tx_id = 0

def _server_tid() -> int:
    global _server_tx_id
    _server_tx_id += 1
    return _server_tx_id


def _client_tid() -> int:
    try:
        return int(request.values.get("ClientTransactionID", 0))
    except (ValueError, TypeError):
        return 0


def _require_connected(bridge: SerialBridge):
    """Return an error response if not connected, else None."""
    if not bridge.connected:
        return _err(ALPACA_NOT_CONNECTED, "Not connected to flat panel")
    return None


# ── Management endpoints ───────────────────────────────────────────────────

def _build_management_bp() -> Blueprint:
    bp = Blueprint("management", __name__)

    @bp.route("/management/apiversions")
    def api_versions():
        return _ok(value=[1])

    @bp.route("/management/v1/description")
    def description():
        return _ok(value={
            "ServerName":        config.SERVER_NAME,
            "Manufacturer":      config.MANUFACTURER,
            "ManufacturerVersion": config.MANUFACTURER_VER,
            "Location":          config.LOCATION,
        })

    @bp.route("/management/v1/configureddevices")
    def configured_devices():
        return _ok(value=[{
            "DeviceName":   config.DEVICE_NAME,
            "DeviceType":   config.DEVICE_TYPE,
            "DeviceNumber": config.DEVICE_NUMBER,
            "UniqueID":     config.DEVICE_GUID,
        }])

    return bp


# ── CoverCalibrator device endpoints ──────────────────────────────────────

def _build_device_bp(bridge: SerialBridge) -> Blueprint:
    bp = Blueprint("device", __name__)
    base = f"/api/v1/covercalibrator/{config.DEVICE_NUMBER}"

    # ── Common device properties ───────────────────────────────────────────

    @bp.route(f"{base}/connected", methods=["GET"])
    def get_connected():
        return _ok(value=bridge.connected)

    @bp.route(f"{base}/connected", methods=["PUT"])
    def put_connected():
        raw = request.form.get("Connected", "").strip().lower()
        if raw not in ("true", "false"):
            return _err(ALPACA_VALUE_ERROR, "Connected must be True or False")
        want_connected = raw == "true"
        try:
            if want_connected and not bridge.connected:
                bridge.connect()
            elif not want_connected and bridge.connected:
                bridge.disconnect()
        except SerialBridgeError as exc:
            return _err(ALPACA_DRIVER_ERROR, str(exc))
        return _ok()

    @bp.route(f"{base}/name", methods=["GET"])
    def get_name():
        return _ok(value=config.DEVICE_NAME)

    @bp.route(f"{base}/description", methods=["GET"])
    def get_description():
        return _ok(value=config.DEVICE_DESC)

    @bp.route(f"{base}/driverinfo", methods=["GET"])
    def get_driverinfo():
        return _ok(value=config.DEVICE_DRIVER)

    @bp.route(f"{base}/driverversion", methods=["GET"])
    def get_driverversion():
        return _ok(value=config.MANUFACTURER_VER)

    @bp.route(f"{base}/interfaceversion", methods=["GET"])
    def get_interfaceversion():
        return _ok(value=1)

    @bp.route(f"{base}/supportedactions", methods=["GET"])
    def get_supportedactions():
        return _ok(value=[])

    # ── Calibrator ─────────────────────────────────────────────────────────

    @bp.route(f"{base}/maxbrightness", methods=["GET"])
    def get_maxbrightness():
        return _ok(value=config.MAX_BRIGHTNESS)

    @bp.route(f"{base}/brightness", methods=["GET"])
    def get_brightness():
        err = _require_connected(bridge)
        if err:
            return err
        try:
            return _ok(value=bridge.get_brightness())
        except SerialBridgeError as exc:
            return _err(ALPACA_DRIVER_ERROR, str(exc))

    @bp.route(f"{base}/calibratorstate", methods=["GET"])
    def get_calibratorstate():
        err = _require_connected(bridge)
        if err:
            return err
        try:
            brightness = bridge.get_brightness()
            state = CAL_READY if brightness > 0 else CAL_OFF
            return _ok(value=state)
        except SerialBridgeError as exc:
            return _err(ALPACA_DRIVER_ERROR, str(exc))

    @bp.route(f"{base}/calibratoron", methods=["PUT"])
    def put_calibratoron():
        err = _require_connected(bridge)
        if err:
            return err
        try:
            brightness = int(request.form.get("Brightness", 0))
        except (ValueError, TypeError):
            return _err(ALPACA_VALUE_ERROR, "Brightness must be an integer 0-255")
        if not 0 <= brightness <= 255:
            return _err(ALPACA_VALUE_ERROR, "Brightness must be in range 0-255")
        try:
            bridge.calibrator_on(brightness)
        except SerialBridgeError as exc:
            return _err(ALPACA_DRIVER_ERROR, str(exc))
        return _ok()

    @bp.route(f"{base}/calibratoroff", methods=["PUT"])
    def put_calibratoroff():
        err = _require_connected(bridge)
        if err:
            return err
        try:
            bridge.calibrator_off()
        except SerialBridgeError as exc:
            return _err(ALPACA_DRIVER_ERROR, str(exc))
        return _ok()

    # ── Cover ──────────────────────────────────────────────────────────────

    @bp.route(f"{base}/coverstate", methods=["GET"])
    def get_coverstate():
        err = _require_connected(bridge)
        if err:
            return err
        try:
            state_str = bridge.get_cover_state()
            return _ok(value=_cover_state_str_to_int(state_str))
        except SerialBridgeError as exc:
            return _err(ALPACA_DRIVER_ERROR, str(exc))

    @bp.route(f"{base}/opencover", methods=["PUT"])
    def put_opencover():
        err = _require_connected(bridge)
        if err:
            return err
        try:
            bridge.open_cover()
        except SerialBridgeError as exc:
            return _err(ALPACA_DRIVER_ERROR, str(exc))
        return _ok()

    @bp.route(f"{base}/closecover", methods=["PUT"])
    def put_closecover():
        err = _require_connected(bridge)
        if err:
            return err
        try:
            bridge.close_cover()
        except SerialBridgeError as exc:
            return _err(ALPACA_DRIVER_ERROR, str(exc))
        return _ok()

    @bp.route(f"{base}/haltcover", methods=["PUT"])
    def put_haltcover():
        err = _require_connected(bridge)
        if err:
            return err
        try:
            bridge.halt_cover()
        except SerialBridgeError as exc:
            return _err(ALPACA_DRIVER_ERROR, str(exc))
        return _ok()

    # ── Action / command stubs (required by spec) ──────────────────────────

    @bp.route(f"{base}/action", methods=["PUT"])
    def put_action():
        return _err(ALPACA_NOT_IMPLEMENTED, "Action not implemented")

    @bp.route(f"{base}/commandblind", methods=["PUT"])
    def put_commandblind():
        return _err(ALPACA_NOT_IMPLEMENTED, "CommandBlind not implemented")

    @bp.route(f"{base}/commandbool", methods=["PUT"])
    def put_commandbool():
        return _err(ALPACA_NOT_IMPLEMENTED, "CommandBool not implemented")

    @bp.route(f"{base}/commandstring", methods=["PUT"])
    def put_commandstring():
        return _err(ALPACA_NOT_IMPLEMENTED, "CommandString not implemented")

    return bp
