"""
Alpaca UDP discovery responder.

Listens on UDP port 32227 for the Alpaca discovery broadcast
("alpacadiscovery1") and responds with {"AlpacaPort": <port>}
so NINA can auto-discover the device without manual IP entry.
"""

import json
import logging
import socket
import threading
from typing import Optional

from . import config

log = logging.getLogger(__name__)

DISCOVERY_MSG = b"alpacadiscovery1"


class DiscoveryServer:
    def __init__(self, alpaca_port: int = config.ALPACA_PORT):
        self._alpaca_port = alpaca_port
        self._sock: Optional[socket.socket] = None
        self._thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()

    def start(self) -> None:
        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._run, name="AlpacaDiscovery", daemon=True
        )
        self._thread.start()
        log.info("Alpaca discovery server started on UDP port %d", config.DISCOVERY_PORT)

    def stop(self) -> None:
        self._stop_event.set()
        if self._sock:
            try:
                self._sock.close()
            except Exception:
                pass

    def _run(self) -> None:
        try:
            self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            self._sock.settimeout(1.0)
            self._sock.bind(("", config.DISCOVERY_PORT))

            response = json.dumps({"AlpacaPort": self._alpaca_port}).encode("utf-8")

            while not self._stop_event.is_set():
                try:
                    data, addr = self._sock.recvfrom(1024)
                except socket.timeout:
                    continue
                except OSError:
                    break

                if data.startswith(DISCOVERY_MSG):
                    log.debug("Discovery request from %s — responding", addr)
                    try:
                        self._sock.sendto(response, addr)
                    except OSError as exc:
                        log.warning("Discovery response failed: %s", exc)

        except OSError as exc:
            log.error("Discovery server error: %s", exc)
        finally:
            if self._sock:
                try:
                    self._sock.close()
                except Exception:
                    pass
