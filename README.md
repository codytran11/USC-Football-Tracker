# USC Football Tracker

A SwiftUI iOS application that lets users explore over 130 years of USC Football history. The app combines historical data, interactive visualizations, and machine learning to create an engaging experience for USC football fans.

---

## Features

### Seasons
- Browse every USC football season from 1888 onward
- View season records and schedules
- Explore game results
- Browse player rosters grouped by position
- National Championship seasons highlighted with trophy indicators
- **Data Sources:** CollegeFootballData API, official USC Athletics historical records,

### Accolades
- National Championships
- Heisman Trophy Winners
- Current NFL Players
- Program Records
- Retired Numbers
- **Data Sources:** Official USC Athletics records, NCAA historical records, NFL rosters

### About
- Interactive flip cards highlighting USC football history
- Notre Dame rivalry
- Spirit of Troy
- Program traditions
- **Data Sources:** Official USC Athletics archives, NCAA historical resources

### Season Predictor
- Built using Apple's Create ML and Core ML
- Predicts every game on USC's schedule
- Displays projected record
- Shows game-by-game win probabilities
- Trained using historical USC football data
- **Training Data:** CollegeFootballData API

---

## Machine Learning Pipeline

1. Downloads games, rosters, coaches, and player usage from the CollegeFootballData API.
2. Cleans and normalizes the data.
3. Generates JSON files used throughout the app.
4. Builds a training dataset for Create ML.
5. Exports a Core ML model used directly inside the iOS application.

---


## What I Learned

This project helped me gain experience with:

- SwiftUI application architecture
- JSON parsing with Codable
- Building custom data pipelines in Python
- Machine Learning using Create ML
- Integrating Core ML into iOS apps

---

## Screenshots


| Seasons | Predictor |
|---------|-----------|
| *(image)* | *(image)* |

| Accolades | About |
|------------|--------|
| *(image)* | *(image)* |

---

## Future Improvements

- Additional historical roster information
- More advanced prediction model
- Search functionality


