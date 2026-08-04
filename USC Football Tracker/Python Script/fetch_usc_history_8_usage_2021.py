"""
Pulls USC football seasons, rosters, and head coaches from the
CollegeFootballData API into seasons.json and players.json.

SETUP (run once):
    pip3 install requests

USAGE:
    export CFBD_API_KEY="your_key_here"
    python3 "fetch_usc_history_8.py"

NOTES:
- Handles CFBD camelCase game fields correctly.
- Adds retry/backoff for 429 rate limits on the main requests.
- Writes output files into the same folder as this script.
- Adds head coach data when the CFBD coaches endpoint returns it.
- Usage data is best-effort for 2025 only; if it is rate-limited, the script skips it.
"""

import json
import os
import time
from datetime import datetime
from typing import Any, Optional

import requests

API_KEY = os.environ.get("CFBD_API_KEY")
if not API_KEY:
    raise SystemExit('Set your API key first: export CFBD_API_KEY="your_key_here"')

GAMES_URL = "https://api.collegefootballdata.com/games"
ROSTER_URL = "https://api.collegefootballdata.com/roster"
COACHES_URL = "https://api.collegefootballdata.com/coaches"
PLAYER_USAGE_URL = "https://api.collegefootballdata.com/player/usage"

TEAM_NAME = "USC"
START_YEAR = 1888
END_YEAR = datetime.now().year - 1

# Try usage for 2021-2025.
USAGE_START_YEAR = 2021

REQUEST_DELAY_SECONDS = 0.75
MAX_RETRIES = 6
BASE_BACKOFF_SECONDS = 2.0

HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Accept": "application/json",
}

CLASS_YEAR_MAP = {
    1: "Freshman",
    2: "Sophomore",
    3: "Junior",
    4: "Senior",
    5: "5th Year",
}

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SEASONS_PATH = os.path.join(SCRIPT_DIR, "seasons.json")
PLAYERS_PATH = os.path.join(SCRIPT_DIR, "players.json")


def get(url: str, params: dict[str, Any]):
    """GET with retry/backoff for 429s and transient request failures."""
    last_error: Optional[Exception] = None

    for attempt in range(MAX_RETRIES):
        try:
            response = requests.get(url, headers=HEADERS, params=params, timeout=20)

            if response.status_code == 429:
                retry_after = response.headers.get("Retry-After")
                if retry_after and retry_after.isdigit():
                    wait_seconds = int(retry_after)
                else:
                    wait_seconds = BASE_BACKOFF_SECONDS * (2 ** attempt)

                print(f"    429 received; sleeping {wait_seconds:.1f}s then retrying...")
                time.sleep(wait_seconds)
                continue

            response.raise_for_status()
            time.sleep(REQUEST_DELAY_SECONDS)
            return response.json()

        except requests.exceptions.RequestException as e:
            last_error = e
            wait_seconds = BASE_BACKOFF_SECONDS * (2 ** attempt)
            print(f"    request failed ({e}); retrying in {wait_seconds:.1f}s...")
            time.sleep(wait_seconds)

    raise RuntimeError(f"Failed to fetch {url} after {MAX_RETRIES} attempts: {last_error}")


def get_optional(url: str, params: dict[str, Any]):
    """
    One-shot request for optional data.
    If it is rate-limited or fails, return an empty list and keep moving.
    """
    try:
        response = requests.get(url, headers=HEADERS, params=params, timeout=20)
        if response.status_code == 429:
            print("    optional request rate-limited; skipping")
            return []
        response.raise_for_status()
        time.sleep(REQUEST_DELAY_SECONDS)
        return response.json()
    except requests.exceptions.RequestException:
        print("    optional request failed; skipping")
        return []


def field(raw: dict, *keys, default=None):
    """Try several possible key names (camelCase, snake_case) and return the first match."""
    for key in keys:
        if key in raw and raw[key] is not None:
            return raw[key]
    return default


def sanitize_id_piece(text: str) -> str:
    return "".join(c.lower() if c.isalnum() else "_" for c in text).strip("_")


def normalize_name(text: str) -> str:
    return " ".join(text.lower().split())


def position_rank(position: str) -> int:
    pos = (position or "").strip().upper()
    if pos == "QB":
        return 0
    if pos in {"RB", "FB"}:
        return 1
    if pos == "WR":
        return 2
    if pos == "TE":
        return 3
    if pos in {"OL", "OT", "OG", "C"}:
        return 4
    if pos in {"DL", "DE", "DT"}:
        return 5
    if pos == "LB":
        return 6
    if pos == "CB":
        return 7
    if pos in {"S", "SS", "FS"}:
        return 8
    if pos == "K":
        return 9
    if pos == "P":
        return 10
    return 99


def to_game_entry(raw_game: dict, game_id: int) -> dict:
    home_team = field(raw_game, "homeTeam", "home_team")
    away_team = field(raw_game, "awayTeam", "away_team")
    home_points = field(raw_game, "homePoints", "home_points")
    away_points = field(raw_game, "awayPoints", "away_points")
    start_date = field(raw_game, "startDate", "start_date", default="")

    is_home = home_team == TEAM_NAME
    usc_score = home_points if is_home else away_points
    opp_score = away_points if is_home else home_points
    opponent = away_team if is_home else home_team
    game_date = start_date[:10] if start_date else None

    if usc_score is None or opp_score is None:
        outcome = "N/A"
    elif usc_score > opp_score:
        outcome = "W"
    elif usc_score < opp_score:
        outcome = "L"
    else:
        outcome = "N/A"

    return {
        "id": game_id,
        "opponent": opponent,
        "gameDate": game_date,
        "home": is_home,
        "uscScore": usc_score,
        "oppScore": opp_score,
        "outcome": outcome,
    }


def to_usage_map(raw_usage: list) -> dict[str, float]:
    usage_map: dict[str, float] = {}

    for row in raw_usage or []:
        name = field(row, "name", default="")
        usage = field(row, "usage", default=None)

        if not name or not isinstance(usage, dict):
            continue

        overall = field(usage, "overall", default=None)
        if overall is None:
            continue

        try:
            usage_map[normalize_name(name)] = float(overall)
        except (TypeError, ValueError):
            continue

    return usage_map


def to_player_entries(raw_roster: list, year: int, usage_map: dict[str, float]):
    roster_refs = []
    player_entries = {}

    for raw in raw_roster:
        first = field(raw, "firstName", "first_name", default="")
        last = field(raw, "lastName", "last_name", default="")
        if not first and not last:
            continue

        name = f"{first} {last}".strip()
        position = field(raw, "position", default="")
        jersey = field(raw, "jersey", default=0) or 0
        class_num = field(raw, "year", default=None)
        grade = CLASS_YEAR_MAP.get(class_num, "")
        usage = usage_map.get(normalize_name(name))

        player_id = f"{year}_{sanitize_id_piece(name)}"

        player_entries[player_id] = {
            "id": player_id,
            "name": name,
            "grade": grade,
            "position": position,
            "jerseyNumber": jersey,
            "usage": usage,
        }
        roster_refs.append({
            "id": player_id,
            "role": position or "Player",
        })

    roster_refs.sort(key=lambda ref: (
        position_rank(player_entries[ref["id"]]["position"]),
        -(player_entries[ref["id"]]["usage"] or -1.0),
        player_entries[ref["id"]]["name"]
    ))
    return roster_refs, player_entries


def to_head_coach(raw_coaches: list, year: int):
    if not raw_coaches:
        return None

    raw = raw_coaches[0]
    first = field(raw, "firstName", "first_name", default="")
    last = field(raw, "lastName", "last_name", default="")
    name = f"{first} {last}".strip() or "Head Coach"
    coach_id = f"{year}_{sanitize_id_piece(name)}"

    return {
        "id": coach_id,
        "name": name,
        "role": "Head Coach",
    }


def main():
    seasons = []
    all_players = {}

    for year in range(START_YEAR, END_YEAR + 1):
        try:
            raw_games = get(GAMES_URL, {"year": year, "team": TEAM_NAME})
        except Exception as e:
            print(f"  {year}: games request failed ({e}), skipping")
            continue

        if not raw_games:
            print(f"  {year}: no games found")
            continue

        games = [to_game_entry(g, idx + 1) for idx, g in enumerate(raw_games)]

        try:
            raw_roster = get(ROSTER_URL, {"year": year, "team": TEAM_NAME})
        except Exception as e:
            print(f"  {year}: roster request failed ({e}), using empty roster")
            raw_roster = []

        try:
            raw_coaches = get(COACHES_URL, {"year": year, "team": TEAM_NAME})
        except Exception as e:
            print(f"  {year}: coach request failed ({e}), using no head coach")
            raw_coaches = []

        if year >= USAGE_START_YEAR:
            raw_usage = get_optional(PLAYER_USAGE_URL, {"year": year, "team": TEAM_NAME})
        else:
            raw_usage = []

        usage_map = to_usage_map(raw_usage or [])
        roster_refs, player_entries = to_player_entries(raw_roster or [], year, usage_map)
        all_players.update(player_entries)
        head_coach = to_head_coach(raw_coaches or [], year)

        seasons.append({
            "id": str(year),
            "roster": roster_refs,
            "headCoach": head_coach,
            "games": games,
        })

        coach_note = "yes" if head_coach else "no"
        usage_note = "yes" if usage_map else "no"
        print(
            f"  {year}: {len(games)} games, {len(roster_refs)} roster entries, "
            f"head coach: {coach_note}, usage data: {usage_note}"
        )

    with open(SEASONS_PATH, "w", encoding="utf-8") as f:
        json.dump(seasons, f, indent=4)

    with open(PLAYERS_PATH, "w", encoding="utf-8") as f:
        json.dump(all_players, f, indent=4)

    print(f"\nDone. {len(seasons)} seasons, {len(all_players)} total player entries written.")
    print(f"Wrote: {SEASONS_PATH}")
    print(f"Wrote: {PLAYERS_PATH}")


if __name__ == "__main__":
    main()
