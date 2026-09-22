#!/usr/bin/env python3
"""Local Forgeworks achievements service for Anvil development."""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
import time
import uuid
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse


DEFAULT_PLAYER_ID = "local-dev"


class Store:
    def __init__(self, data_dir: Path, sets_dir: Path) -> None:
        self.data_dir = data_dir
        self.sets_dir = sets_dir
        self.db_path = data_dir / "forgeworks-achievements.sqlite3"
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self) -> None:
        with self._connect() as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS claims (
                    id TEXT PRIMARY KEY,
                    player_id TEXT NOT NULL,
                    game_id TEXT NOT NULL,
                    achievement_set TEXT NOT NULL,
                    achievement_id TEXT NOT NULL,
                    status TEXT NOT NULL,
                    evidence_json TEXT NOT NULL,
                    created_at INTEGER NOT NULL,
                    updated_at INTEGER NOT NULL,
                    UNIQUE (player_id, achievement_set, achievement_id)
                )
                """
            )
            conn.commit()

    def list_sets(self) -> list[dict]:
        sets = []
        for path in sorted(self.sets_dir.glob("*.json")):
            achievement_set = self._load_set_path(path)
            sets.append(self._summarize_set(achievement_set))
        return sets

    def get_set(self, set_id: str) -> dict:
        path = self.sets_dir / f"{set_id}.json"
        if not path.is_file():
            raise KeyError(set_id)
        return self._load_set_path(path)

    def achievement_exists(self, set_id: str, achievement_id: str) -> bool:
        achievement_set = self.get_set(set_id)
        return any(item.get("id") == achievement_id for item in achievement_set.get("achievements", []))

    def record_claim(self, payload: dict) -> dict:
        player_id = str(payload.get("player_id") or DEFAULT_PLAYER_ID)
        game_id = str(payload.get("game_id") or "")
        set_id = str(payload.get("achievement_set") or "")
        achievement_id = str(payload.get("achievement_id") or "")
        evidence = payload.get("evidence") or {}

        if not game_id:
            raise ValueError("game_id is required")
        if not set_id:
            raise ValueError("achievement_set is required")
        if not achievement_id:
            raise ValueError("achievement_id is required")
        if not isinstance(evidence, dict):
            raise ValueError("evidence must be an object")
        if not self.achievement_exists(set_id, achievement_id):
            raise KeyError(f"{set_id}/{achievement_id}")

        now = int(time.time())
        claim_id = uuid.uuid4().hex
        evidence_json = json.dumps(evidence, sort_keys=True, separators=(",", ":"))

        with self._connect() as conn:
            conn.execute(
                """
                INSERT INTO claims (
                    id, player_id, game_id, achievement_set, achievement_id,
                    status, evidence_json, created_at, updated_at
                )
                VALUES (?, ?, ?, ?, ?, 'recorded-local', ?, ?, ?)
                ON CONFLICT(player_id, achievement_set, achievement_id) DO UPDATE SET
                    game_id = excluded.game_id,
                    evidence_json = excluded.evidence_json,
                    updated_at = excluded.updated_at
                """,
                (claim_id, player_id, game_id, set_id, achievement_id, evidence_json, now, now),
            )
            conn.commit()

        return self.get_player_claim(player_id, set_id, achievement_id)

    def get_player_claims(self, player_id: str) -> list[dict]:
        with self._connect() as conn:
            rows = conn.execute(
                """
                SELECT * FROM claims
                WHERE player_id = ?
                ORDER BY updated_at DESC, achievement_set, achievement_id
                """,
                (player_id,),
            ).fetchall()
        return [self._claim_from_row(row) for row in rows]

    def get_player_claim(self, player_id: str, set_id: str, achievement_id: str) -> dict:
        with self._connect() as conn:
            row = conn.execute(
                """
                SELECT * FROM claims
                WHERE player_id = ? AND achievement_set = ? AND achievement_id = ?
                """,
                (player_id, set_id, achievement_id),
            ).fetchone()
        if row is None:
            raise KeyError(f"{player_id}/{set_id}/{achievement_id}")
        return self._claim_from_row(row)

    def _load_set_path(self, path: Path) -> dict:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)

    def _summarize_set(self, achievement_set: dict) -> dict:
        achievements = achievement_set.get("achievements", [])
        return {
            "id": achievement_set.get("id"),
            "name": achievement_set.get("name"),
            "source": achievement_set.get("source"),
            "platform": achievement_set.get("platform"),
            "schema": achievement_set.get("schema"),
            "count": len(achievements),
            "points": sum(int(item.get("points") or 0) for item in achievements),
        }

    def _claim_from_row(self, row: sqlite3.Row) -> dict:
        return {
            "id": row["id"],
            "player_id": row["player_id"],
            "game_id": row["game_id"],
            "achievement_set": row["achievement_set"],
            "achievement_id": row["achievement_id"],
            "status": row["status"],
            "evidence": json.loads(row["evidence_json"]),
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
        }


class Handler(BaseHTTPRequestHandler):
    server_version = "ForgeworksAchievements/0.1"

    @property
    def store(self) -> Store:
        return self.server.store  # type: ignore[attr-defined]

    def do_GET(self) -> None:
        try:
            path = self._path_parts()
            if path == ["health"]:
                self._json({"ok": True, "service": "forgeworks-achievements"})
                return
            if path == ["v1", "achievement-sets"]:
                self._json({"sets": self.store.list_sets()})
                return
            if len(path) == 3 and path[:2] == ["v1", "achievement-sets"]:
                self._json(self.store.get_set(path[2]))
                return
            if len(path) == 4 and path[:3] == ["v1", "players", path[2]] and path[3] == "achievements":
                self._json({"player_id": path[2], "claims": self.store.get_player_claims(path[2])})
                return
            self._error(HTTPStatus.NOT_FOUND, "not found")
        except KeyError:
            self._error(HTTPStatus.NOT_FOUND, "not found")
        except Exception as exc:
            self._error(HTTPStatus.INTERNAL_SERVER_ERROR, str(exc))

    def do_POST(self) -> None:
        try:
            path = self._path_parts()
            if path == ["v1", "claims"]:
                self._json(self.store.record_claim(self._body()), HTTPStatus.CREATED)
                return
            self._error(HTTPStatus.NOT_FOUND, "not found")
        except ValueError as exc:
            self._error(HTTPStatus.BAD_REQUEST, str(exc))
        except KeyError:
            self._error(HTTPStatus.NOT_FOUND, "not found")
        except Exception as exc:
            self._error(HTTPStatus.INTERNAL_SERVER_ERROR, str(exc))

    def log_message(self, fmt: str, *args: object) -> None:
        print(f"{self.address_string()} - {fmt % args}")

    def _path_parts(self) -> list[str]:
        parsed = urlparse(self.path)
        return [unquote(part) for part in parsed.path.split("/") if part]

    def _body(self) -> dict:
        length = int(self.headers.get("content-length") or "0")
        raw = self.rfile.read(length)
        if not raw:
            return {}
        data = json.loads(raw.decode("utf-8"))
        if not isinstance(data, dict):
            raise ValueError("request body must be an object")
        return data

    def _json(self, payload: dict, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = json.dumps(payload, indent=2, sort_keys=True).encode("utf-8")
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _error(self, status: HTTPStatus, message: str) -> None:
        self._json({"error": message}, status)


class Server(ThreadingHTTPServer):
    def __init__(self, address: tuple[str, int], store: Store) -> None:
        super().__init__(address, Handler)
        self.store = store


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the local Forgeworks achievements service.")
    parser.add_argument("--host", default=os.environ.get("FORGEWORKS_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("FORGEWORKS_PORT", "8080")))
    parser.add_argument(
        "--data-dir",
        default=os.environ.get("FORGEWORKS_DATA", "/data"),
        help="directory for SQLite state",
    )
    parser.add_argument(
        "--sets-dir",
        default=os.environ.get("FORGEWORKS_ACHIEVEMENT_SETS_DIR", "/app/achievement-sets"),
        help="directory containing achievement set JSON files",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    store = Store(Path(args.data_dir), Path(args.sets_dir))
    server = Server((args.host, args.port), store)
    print(f"forgeworks-achievements listening on {args.host}:{args.port}")
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
