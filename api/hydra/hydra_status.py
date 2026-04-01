#!/usr/bin/env python3
"""HYDRA status check CLI."""

import json
import os
import sys

import psycopg2
import psycopg2.extras

DEFAULT_DSN = os.getenv("PG_DSN", "postgresql://localhost:5432/research")


def main() -> int:
    try:
        with psycopg2.connect(DEFAULT_DSN) as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
                cur.execute("SELECT COUNT(*) AS count FROM tier45_evaluations_v2")
                eval_count = int(cur.fetchone()["count"])

                cur.execute("SELECT COUNT(DISTINCT model_name) AS count FROM tier45_evaluations_v2")
                model_count = int(cur.fetchone()["count"])

                cur.execute("SELECT COUNT(DISTINCT technique_name) AS count FROM tier45_evaluations_v2")
                technique_count = int(cur.fetchone()["count"])

                cur.execute("SELECT MAX(created_at) AS last_eval_at FROM tier45_evaluations_v2")
                last_eval_at = cur.fetchone()["last_eval_at"]

        print(
            json.dumps(
                {
                    "ok": True,
                    "database": "connected",
                    "eval_count": eval_count,
                    "model_count": model_count,
                    "technique_count": technique_count,
                    "last_eval_at": last_eval_at.isoformat() if last_eval_at else None,
                },
                ensure_ascii=False,
            )
        )
        return 0
    except Exception as exc:
        print(json.dumps({"ok": False, "database": "disconnected", "error": str(exc)}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
