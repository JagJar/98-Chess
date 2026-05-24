# Puzzle Sources

The hand-picked starter set in `Puzzles.json` was written by hand for the
launch of the daily puzzle feature. Future expansions will pull from the
[Lichess Open Puzzle Database](https://database.lichess.org/#puzzles)
which is released under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)
(distinct from the Lichess.org source code which is AGPL).

A conversion script that filters the Lichess CSV dump down to mate-in-1/2/3
puzzles at appropriate ratings and outputs the JSON format used here will
live at `tools/convert-lichess-puzzles.swift`.
