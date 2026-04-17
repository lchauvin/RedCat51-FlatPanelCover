"""
Entry point for the RedCat 51 Flat Panel Alpaca server.

Usage:
    python -m server.main --serial COM3
    python -m server.main --serial COM3 --port 11111 --host 0.0.0.0
    python -m server.main --serial COM3 --no-discovery

The server starts:
  1. Flask HTTP server on <host>:<port>   (Alpaca REST API)
  2. UDP discovery responder on port 32227 (so NINA auto-discovers the device)
"""

import argparse
import logging
import sys

from . import config
from .alpaca_server import create_app
from .discovery import DiscoveryServer
from .serial_bridge import SerialBridge

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="RedCat 51 Flat Panel — Alpaca server")
    p.add_argument(
        "--serial", default=config.SERIAL_PORT,
        metavar="PORT",
        help=f"Arduino serial port (default: {config.SERIAL_PORT})",
    )
    p.add_argument(
        "--baud", type=int, default=config.SERIAL_BAUDRATE,
        help=f"Serial baud rate (default: {config.SERIAL_BAUDRATE})",
    )
    p.add_argument(
        "--host", default=config.ALPACA_HOST,
        help=f"HTTP bind address (default: {config.ALPACA_HOST})",
    )
    p.add_argument(
        "--port", type=int, default=config.ALPACA_PORT,
        help=f"HTTP port (default: {config.ALPACA_PORT})",
    )
    p.add_argument(
        "--no-discovery", action="store_true",
        help="Disable UDP Alpaca discovery responder",
    )
    p.add_argument(
        "--auto-connect", action="store_true",
        help="Connect to the Arduino immediately on startup (don't wait for NINA)",
    )
    p.add_argument(
        "--debug", action="store_true",
        help="Enable Flask debug mode (single-threaded, verbose)",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    # Override config with CLI values
    config.SERIAL_PORT     = args.serial
    config.SERIAL_BAUDRATE = args.baud
    config.ALPACA_HOST     = args.host
    config.ALPACA_PORT     = args.port

    bridge = SerialBridge()

    if args.auto_connect:
        log.info("Auto-connecting to %s …", args.serial)
        try:
            bridge.connect(port=args.serial, baudrate=args.baud)
            log.info("Connected.")
        except Exception as exc:
            log.error("Auto-connect failed: %s", exc)
            sys.exit(1)

    discovery = None
    if not args.no_discovery:
        discovery = DiscoveryServer(alpaca_port=args.port)
        discovery.start()

    app = create_app(bridge)

    log.info(
        "Starting Alpaca server on http://%s:%d  (serial: %s)",
        args.host if args.host != "0.0.0.0" else "localhost",
        args.port,
        args.serial,
    )
    log.info("In NINA: Equipment → Flat Device → ASCOM Alpaca → Refresh → select device")

    try:
        app.run(host=args.host, port=args.port, debug=args.debug, use_reloader=False)
    except KeyboardInterrupt:
        log.info("Shutting down…")
    finally:
        if discovery:
            discovery.stop()
        if bridge.connected:
            bridge.disconnect()


if __name__ == "__main__":
    main()
