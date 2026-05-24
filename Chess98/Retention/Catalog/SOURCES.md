# Puzzle Sources

`Puzzles.json` contains 365 puzzles sampled from the
[Lichess Open Puzzle Database](https://database.lichess.org/#puzzles)
which is released under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)
(distinct from the Lichess.org source code which is AGPL).

Filtering criteria:
- Theme contains `mateIn1` or `mateIn2` (skip longer for v1 audience)
- Rating between 700 and 1500 (approachable)
- Popularity ≥ 85 (community-vetted)
- Random seed 42 for reproducibility

To regenerate (e.g. after Lichess updates the database):

```sh
curl -fLO https://database.lichess.org/lichess_db_puzzle.csv.zst
zstd -d lichess_db_puzzle.csv.zst
python3 tools/convert-lichess-puzzles.py lichess_db_puzzle.csv \
    > Chess98/Retention/Catalog/Puzzles.json
```

Each puzzle preserves the original Lichess `setupMove` (opponent's blundering
move) so the in-app `PuzzleViewModel` can apply it silently before the player
takes over, matching how the puzzles look on lichess.org.
