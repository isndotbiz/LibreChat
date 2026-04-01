#!/usr/bin/env python3
"""HYDRA evaluation CLI for LibreChat tool bridge."""

import argparse
import json
import os
import sys
from typing import Any

from hydra_pipeline import Pipe


def _detect_refusal(text: str) -> bool:
    lowered = (text or "").lower()
    refusal_markers = [
        "i can't",
        "i cannot",
        "i won't",
        "sorry, but i can't",
        "cannot assist",
        "cannot provide",
        "must decline",
        "unable to comply",
    ]
    return any(marker in lowered for marker in refusal_markers)


def _safe_value(value: Any, default: Any) -> Any:
    return value if value is not None else default


def main() -> int:
    parser = argparse.ArgumentParser(description="Run HYDRA cascade evaluation")
    parser.add_argument("--message", required=True, help="User prompt")
    parser.add_argument("--model", default="", help="Optional target model")
    args = parser.parse_args()

    try:
        pipe = Pipe()
        pipe.valves.ENABLE_STREAMING = False
        if args.model:
            pipe.MODEL_CASCADE = [args.model] + [m for m in pipe.MODEL_CASCADE if m != args.model]
        result = pipe.pipe({"messages": [{"role": "user", "content": args.message}]})
        response_text = result if isinstance(result, str) else "".join(result)

        payload = {
            "ok": True,
            "model": args.model or pipe.MODEL_CASCADE[0],
            "technique_used": "auto",
            "quality_score": len(response_text or ""),
            "refusal_detected": _detect_refusal(response_text),
            "response": _safe_value(response_text, ""),
            "metadata": {
                "cascade_size": len(pipe.MODEL_CASCADE),
                "openrouter_key_present": bool(
                    pipe.valves.OPENROUTER_API_KEY or os.getenv("OPENROUTER_API_KEY")
                ),
            },
        }
        print(json.dumps(payload, ensure_ascii=False))
        return 0
    except Exception as exc:
        print(json.dumps({"ok": False, "error": str(exc)}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
