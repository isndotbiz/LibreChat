#!/usr/bin/env python3
"""HYDRA IP score lookup CLI."""

import argparse
import json
import os
import re
import sys

import psycopg2
import psycopg2.extras

DEFAULT_DSN = os.getenv("PG_DSN", "postgresql://localhost:5432/research")


def _model_family(model: str) -> str:
    if "/" in model:
        return model.split("/", 1)[0]
    return re.split(r"[-_]", model)[0]


def main() -> int:
    parser = argparse.ArgumentParser(description="Lookup HYDRA IP score for a model")
    parser.add_argument("--model", required=True, help="Model id, e.g. deepseek/deepseek-chat")
    args = parser.parse_args()
    model = args.model
    family = _model_family(model)

    try:
        with psycopg2.connect(DEFAULT_DSN) as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
                cur.execute(
                    """
                    SELECT
                      technique_name,
                      successes,
                      attempts,
                      win_rate,
                      ema_score
                    FROM technique_model_scores
                    WHERE (model_id = %s OR model_family = %s)
                      AND status = 'ACTIVE'
                    ORDER BY ema_score DESC NULLS LAST, win_rate DESC NULLS LAST
                    LIMIT 5
                    """,
                    (model, family),
                )
                rows = cur.fetchall()

        eval_count = int(sum((row["attempts"] or 0) for row in rows))
        wins = int(sum((row["successes"] or 0) for row in rows))
        win_rate = (wins / eval_count) if eval_count > 0 else 0.0
        confidence = min(1.0, eval_count / 50.0)
        ip_score = round((win_rate * 0.7 + confidence * 0.3) * 100, 2)
        top_techniques = [
            {
                "technique": row["technique_name"],
                "win_rate": float(row["win_rate"] or 0),
                "ema_score": float(row["ema_score"] or 0),
            }
            for row in rows
        ]

        print(
            json.dumps(
                {
                    "ok": True,
                    "model": model,
                    "model_family": family,
                    "ip_score": ip_score,
                    "eval_count": eval_count,
                    "confidence": round(confidence, 3),
                    "top_techniques": top_techniques,
                },
                ensure_ascii=False,
            )
        )
        return 0
    except Exception as exc:
        print(json.dumps({"ok": False, "error": str(exc), "model": model}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
