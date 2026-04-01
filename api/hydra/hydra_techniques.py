#!/usr/bin/env python3
"""HYDRA techniques ranking CLI."""

import argparse
import json
import os
import sys

import psycopg2
import psycopg2.extras

DEFAULT_DSN = os.getenv("PG_DSN", "postgresql://localhost:5432/research")


def main() -> int:
    parser = argparse.ArgumentParser(description="List HYDRA techniques by win rate")
    parser.add_argument("--category", default="", help="Optional category filter")
    parser.add_argument("--model-family", default="", help="Optional model family filter")
    parser.add_argument("--limit", type=int, default=10, help="Result count (max 50)")
    args = parser.parse_args()

    limit = max(1, min(args.limit, 50))

    where = ["technique_name IS NOT NULL"]
    params = []

    if args.category:
        where.append("category_name = %s")
        params.append(args.category)
    if args.model_family:
        where.append("model_name ILIKE %s")
        params.append(f"{args.model_family}/%")

    where_sql = " AND ".join(where)

    sql = f"""
        SELECT
          technique_name,
          COUNT(*) AS attempts,
          COUNT(*) FILTER (WHERE compliant = true) AS wins,
          ROUND((COUNT(*) FILTER (WHERE compliant = true))::numeric / NULLIF(COUNT(*), 0), 4) AS win_rate
        FROM tier45_evaluations_v2
        WHERE {where_sql}
        GROUP BY technique_name
        HAVING COUNT(*) > 0
        ORDER BY win_rate DESC, attempts DESC
        LIMIT %s
    """
    params.append(limit)

    try:
        with psycopg2.connect(DEFAULT_DSN) as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
                cur.execute(sql, params)
                rows = cur.fetchall()

        print(
            json.dumps(
                {
                    "ok": True,
                    "category": args.category or None,
                    "model_family": args.model_family or None,
                    "count": len(rows),
                    "techniques": [
                        {
                            "technique": row["technique_name"],
                            "attempts": int(row["attempts"] or 0),
                            "wins": int(row["wins"] or 0),
                            "win_rate": float(row["win_rate"] or 0),
                        }
                        for row in rows
                    ],
                },
                ensure_ascii=False,
            )
        )
        return 0
    except Exception as exc:
        print(json.dumps({"ok": False, "error": str(exc)}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
