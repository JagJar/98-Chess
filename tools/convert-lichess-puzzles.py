#!/usr/bin/env python3
"""
convert-lichess-puzzles.py
==========================

One-shot script that reads the Lichess open puzzle database (CC0) and writes
the 365-puzzle Puzzles.json that ships in the app bundle.

Usage:
  1. Download the CSV:
       curl -fLO https://database.lichess.org/lichess_db_puzzle.csv.zst
  2. Decompress (requires zstd: `brew install zstd`):
       zstd -d lichess_db_puzzle.csv.zst
  3. Run this script from the repo root:
       python3 tools/convert-lichess-puzzles.py lichess_db_puzzle.csv \
           > Chess98/Retention/Catalog/Puzzles.json

The Lichess CSV columns are:
  PuzzleId, FEN, Moves, Rating, RatingDeviation, Popularity, NbPlays,
  Themes, GameUrl, OpeningTags

Moves is space-separated UCI. The first move is the opponent's "setup" move
played from FEN; the puzzle proper begins from the resulting position with
the player to move. We preserve `setupMove` separately so the Swift loader
(PuzzleViewModel) can apply it without re-implementing FEN+move arithmetic.

Filtering for an introductory daily-puzzle experience:
  - themes must include mateIn1 OR mateIn2 (skip mateIn3+ as too hard)
  - rating 700-1500 (approachable)
  - popularity >= 85 (well-vetted by Lichess users)
  - at least 2 moves (setup + solution)
"""

import csv
import json
import random
import sys
from pathlib import Path

DEFAULT_INPUT = "lichess_db_puzzle.csv"
TARGET_COUNT = 365
SEED = 42
RATING_MIN = 700
RATING_MAX = 1500
POPULARITY_MIN = 85
ALLOWED_THEMES = {"mateIn1", "mateIn2"}


def main() -> int:
    csv_path = Path(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_INPUT)
    if not csv_path.exists():
        print(f"error: {csv_path} not found", file=sys.stderr)
        return 1

    candidates = []
    with csv_path.open(newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            themes = set(row["Themes"].split())
            if not themes & ALLOWED_THEMES:
                continue
            try:
                rating = int(row["Rating"])
                popularity = int(row["Popularity"])
            except (KeyError, ValueError):
                continue
            if rating < RATING_MIN or rating > RATING_MAX:
                continue
            if popularity < POPULARITY_MIN:
                continue
            moves = row["Moves"].split()
            if len(moves) < 2:
                continue
            candidates.append({
                "puzzleId": row["PuzzleId"],
                "fen": row["FEN"],
                "setupMove": moves[0],
                "solution": moves[1:],
                "themes": themes,
                "rating": rating,
                "popularity": popularity,
            })

    print(f"candidates after filter: {len(candidates)}", file=sys.stderr)
    if not candidates:
        return 2

    random.seed(SEED)
    sample = random.sample(candidates, min(TARGET_COUNT, len(candidates)))
    # Stable sort by id so commits diff cleanly when the script re-runs.
    sample.sort(key=lambda p: p["puzzleId"])

    out = []
    for p in sample:
        if "mateIn1" in p["themes"]:
            title, hint = "Mate in 1", "Find the checkmate."
        elif "mateIn2" in p["themes"]:
            title, hint = "Mate in 2", "Two moves to mate."
        else:
            title, hint = "Tactic", None
        out.append({
            "id": f"lichess-{p['puzzleId']}",
            "fen": p["fen"],
            "setupMove": p["setupMove"],
            "solution": p["solution"],
            "alternatives": None,
            "title": title,
            "hint": hint,
        })

    json.dump(out, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    print(f"wrote {len(out)} puzzles to stdout", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
