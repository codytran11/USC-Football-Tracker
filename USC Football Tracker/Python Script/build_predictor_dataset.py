#!/usr/bin/env python3
"""Build an Elo-based training dataset for USC football predictions.

Input:
  - seasons.json (produced by fetch_usc_history_8.py)

Outputs:
  - predictor_training_data.csv
  - team_ratings.json

The script uses all seasons in seasons.json to warm up the Elo ratings,
then writes training rows only for the 2021-2025 seasons.
"""

from __future__ import annotations

import csv
import json
import math
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

TEAM_NAME = "USC"
START_TRAIN_YEAR = 2005
END_TRAIN_YEAR = 2025
BASE_RATING = 1500.0
K_FACTOR = 20.0
HOME_ADVANTAGE = 65.0
SEASON_REGRESSION = 0.75  # regress toward BASE_RATING each offseason

SCRIPT_DIR = Path(__file__).resolve().parent
SEASONS_PATH = SCRIPT_DIR / "seasons.json"
CSV_PATH = SCRIPT_DIR / "predictor_training_data.csv"
RATINGS_PATH = SCRIPT_DIR / "team_ratings.json"

PAC12_OPPONENTS = {
    "Arizona",
    "Arizona State",
    "California",
    "Colorado",
    "Oregon",
    "Oregon State",
    "Stanford",
    "UCLA",
    "Utah",
    "Washington",
    "Washington State",
}

BIG10_OPPONENTS_2024 = {
    "Illinois",
    "Indiana",
    "Maryland",
    "Michigan",
    "Minnesota",
    "Nebraska",
    "Penn State",
    "Rutgers",
    "UCLA",
    "Washington",
    "Wisconsin",
}

BIG10_OPPONENTS_2025 = {
    "Illinois",
    "Iowa",
    "Michigan",
    "Michigan State",
    "Nebraska",
    "Northwestern",
    "Ohio State",
    "Oregon",
    "UCLA",
}


@dataclass(frozen=True)
class Game:
    year: int
    game_index: int
    opponent: str
    home: bool
    usc_score: Optional[int]
    opp_score: Optional[int]
    outcome: str
    game_date: Optional[str]

    @property
    def is_decided(self) -> bool:
        return self.outcome in {"W", "L"} and self.usc_score is not None and self.opp_score is not None

    @property
    def date_key(self) -> Tuple[str, int]:
        # Keep a stable chronological ordering when dates are missing or equal.
        return ((self.game_date or f"{self.year:04d}-99-99"), self.game_index)


@dataclass
class SeasonRecord:
    year: int
    wins: int = 0
    losses: int = 0

    @property
    def win_pct(self) -> float:
        total = self.wins + self.losses
        return (self.wins / total) if total else 0.0


def load_seasons(path: Path) -> List[dict[str, Any]]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise ValueError("seasons.json must contain a list of seasons")
    return data


def parse_int(value: Any) -> Optional[int]:
    if value is None:
        return None
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, (int, float)):
        return int(value)
    try:
        return int(str(value).strip())
    except (TypeError, ValueError):
        return None


def normalize_name(text: str) -> str:
    return " ".join((text or "").strip().split())


def get_usc_prev_stats(season_year: int, season_records: dict[int, SeasonRecord], prev_ratings: dict[int, float]) -> tuple[int, int, float, float]:
    prev = season_records.get(season_year - 1)
    wins = prev.wins if prev else 0
    losses = prev.losses if prev else 0
    win_pct = prev.win_pct if prev else 0.0
    prev_rating = prev_ratings.get(season_year - 1, BASE_RATING)
    return wins, losses, win_pct, prev_rating


def is_conference_game(year: int, opponent: str) -> bool:
    opponent = normalize_name(opponent)
    if year in {2021, 2022, 2023}:
        return opponent in PAC12_OPPONENTS
    if year == 2024:
        return opponent in BIG10_OPPONENTS_2024
    if year == 2025:
        return opponent in BIG10_OPPONENTS_2025
    return False


def logistic(x: float) -> float:
    return 1.0 / (1.0 + 10.0 ** (-x / 400.0))


def expected_score(rating_a: float, rating_b: float) -> float:
    return logistic(rating_a - rating_b)


def margin_multiplier(score_diff: int, rating_diff: float) -> float:
    # Standard Elo-style MOV multiplier with a mild dampener for lopsided expected outcomes.
    margin = max(1, abs(score_diff))
    return math.log(margin + 1.0) * (2.2 / ((abs(rating_diff) * 0.001) + 2.2))


def infer_result(outcome: str) -> Optional[int]:
    if outcome == "W":
        return 1
    if outcome == "L":
        return 0
    return None


def iter_games(seasons: Iterable[dict[str, Any]]) -> List[Game]:
    games: List[Game] = []
    for season in seasons:
        year = parse_int(season.get("id"))
        if year is None:
            continue
        raw_games = season.get("games") or []
        for idx, raw_game in enumerate(raw_games, start=1):
            if not isinstance(raw_game, dict):
                continue
            game = Game(
                year=year,
                game_index=parse_int(raw_game.get("id")) or idx,
                opponent=normalize_name(str(raw_game.get("opponent", ""))),
                home=bool(raw_game.get("home", False)),
                usc_score=parse_int(raw_game.get("uscScore")),
                opp_score=parse_int(raw_game.get("oppScore")),
                outcome=str(raw_game.get("outcome", "N/A")),
                game_date=(raw_game.get("gameDate") or None),
            )
            games.append(game)
    games.sort(key=lambda g: g.date_key)
    return games


def build_dataset(seasons_path: Path) -> tuple[List[dict[str, Any]], dict[str, float]]:
    seasons = load_seasons(seasons_path)
    games = iter_games(seasons)

    ratings: dict[str, float] = {}
    season_records: dict[int, SeasonRecord] = {}
    prev_season_final_ratings: dict[int, float] = {}
    rows: List[dict[str, Any]] = []

    current_season_year: Optional[int] = None
    season_first_pass = True

    for game in games:
        if current_season_year is None:
            current_season_year = game.year
        elif game.year != current_season_year:
            # Save USC final rating for the season that just ended.
            prev_season_final_ratings[current_season_year] = ratings.get(TEAM_NAME, BASE_RATING)
            # Offseason regression for all teams.
            for team in list(ratings.keys()):
                ratings[team] = BASE_RATING + (ratings[team] - BASE_RATING) * SEASON_REGRESSION
            current_season_year = game.year
            season_first_pass = False

        # Keep season record object around for every year.
        season_rec = season_records.setdefault(game.year, SeasonRecord(year=game.year))

        result = infer_result(game.outcome)
        if result is None or not game.is_decided:
            # We still want the ratings to evolve if the game is decided.
            continue

        usc_rating_before = ratings.get(TEAM_NAME, BASE_RATING)
        opp_rating_before = ratings.get(game.opponent, BASE_RATING)
        conf_game = is_conference_game(game.year, game.opponent)

        # Features available before the game.
        prev_wins, prev_losses, prev_win_pct, prev_rating = get_usc_prev_stats(
            game.year, season_records, prev_season_final_ratings
        )

        if START_TRAIN_YEAR <= game.year <= END_TRAIN_YEAR:
            rows.append(
                {
                    "seasonYear": game.year,
                    "gameIndex": game.game_index,
                    "home": 1 if game.home else 0,
                    "conferenceGame": 1 if conf_game else 0,
                    "uscElo": round(usc_rating_before, 3),
                    "oppElo": round(opp_rating_before, 3),
                    "eloDiff": round(usc_rating_before - opp_rating_before, 3),
                    "uscPrevWins": prev_wins,
                    "uscPrevLosses": prev_losses,
                    "uscPrevWinPct": round(prev_win_pct, 6),
                    "uscPrevRating": round(prev_rating, 3),
                    "result": result,
                }
            )

        # Update season records before moving on.
        if result == 1:
            season_rec.wins += 1
        else:
            season_rec.losses += 1

        # Elo update.
        adjusted_usc = usc_rating_before + (HOME_ADVANTAGE if game.home else 0.0)
        adjusted_opp = opp_rating_before + (HOME_ADVANTAGE if not game.home else 0.0)
        expected_usc = expected_score(adjusted_usc, adjusted_opp)
        score_diff = (game.usc_score or 0) - (game.opp_score or 0)
        mov = margin_multiplier(score_diff, adjusted_usc - adjusted_opp)
        delta = K_FACTOR * mov * (result - expected_usc)

        ratings[TEAM_NAME] = usc_rating_before + delta
        ratings[game.opponent] = opp_rating_before - delta

    # Save the final season rating after the last year too.
    if current_season_year is not None:
        prev_season_final_ratings[current_season_year] = ratings.get(TEAM_NAME, BASE_RATING)

    return rows, ratings, prev_season_final_ratings


def write_csv(path: Path, rows: List[dict[str, Any]]) -> None:
    fieldnames = [
        "seasonYear",
        "gameIndex",
        "home",
        "conferenceGame",
        "uscElo",
        "oppElo",
        "eloDiff",
        "uscPrevWins",
        "uscPrevLosses",
        "uscPrevWinPct",
        "uscPrevRating",
        "result",
    ]
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_ratings(path: Path, ratings: dict[str, float]) -> None:
    # Keep only a manageable snapshot of the most recent ratings.
    top = sorted(ratings.items(), key=lambda kv: kv[0])
    payload = {
        "generatedAt": datetime.now().isoformat(timespec="seconds"),
        "baseRating": BASE_RATING,
        "ratings": {team: round(score, 3) for team, score in top},
    }
    with path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)


def main() -> None:
    if not SEASONS_PATH.exists():
        raise SystemExit(f"Missing {SEASONS_PATH}. Run fetch_usc_history_8.py first.")

    rows, ratings, _ = build_dataset(SEASONS_PATH)
    if not rows:
        raise SystemExit("No training rows were generated. Check seasons.json.")

    write_csv(CSV_PATH, rows)
    write_ratings(RATINGS_PATH, ratings)

    print(f"Wrote {len(rows)} training rows to {CSV_PATH}")
    print(f"Wrote Elo snapshot to {RATINGS_PATH}")
    print("First 5 rows:")
    for row in rows[:5]:
        print(row)


if __name__ == "__main__":
    main()
