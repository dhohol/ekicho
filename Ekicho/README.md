# Ekicho - Tokyo Subway Station Tracker

A SwiftUI app for tracking visited subway stations in Tokyo, now powered by Firebase Firestore.

## Features

- **Real-time Data**: All line and station data is loaded from Firebase Firestore
- **User Authentication**: Apple Sign-In for secure user accounts
- **Visit Tracking**: Mark stations as visited/unvisited with real-time sync
- **Progress Tracking**: View progress per line and overall city progress
- **Company Filtering**: Filter lines by train company
- **Offline Support**: Firebase handles offline data synchronization

## Architecture

### Firebase Integration

The app uses Firebase for:
- **Authentication**: Apple Sign-In via Firebase Auth
- **Data Storage**: Lines and stations stored in Firestore
- **User Data**: Individual user visit tracking in Firestore
- **Real-time Updates**: Live synchronization of visit data

### Data Models

- **Line**: Represents a train line with properties like name, company, color, shape, and station IDs
- **Station**: Represents a station with properties like name, location, and associated line IDs
- **User**: User profile information
- **UserStationVisit**: Individual station visits with timestamps and metadata

### Key Components

- **FirebaseService**: Handles all Firestore operations and data loading
- **FirebaseDataStore**: ObservableObject that provides data to SwiftUI views
- **AuthViewModel**: Manages authentication state and user creation
- **MigrationService**: Handles migration of local data to Firebase on first login

## Firebase Collections

### Lines Collection
```
lines/{line_id}
├── line_id: String
├── name: String
├── company: String
├── city_id: String
├── line_symbol: String
├── color_name: String
├── color_hex: String
├── shape: String ("circle" or "square")
├── icon_asset_name: String
├── station_ids: [String]
└── is_active: Bool
```

### Stations Collection
```
stations/{station_id}
├── station_id: String
├── name: String
├── city_id: String
├── line_ids: [String]
├── lat: Double? (nullable)
├── lng: Double? (nullable)
└── is_active: Bool
```

### Users Collection
```
users/{user_id}
├── display_name: String
├── email: String
├── auth_provider: String
├── current_city_id: String
├── home_stations: [String: String]
├── auxiliary_stations: [String: [String: String]]
├── created_at: Date
└── last_active_at: Date
```

### User Visits Subcollection
```
users/{user_id}/visits/{station_id}
├── user_id: String
├── station_id: String
├── visited_at: Date
├── photo_urls: [String]
├── recommendation_text: String?
├── recommendation_url: String?
├── is_public: Bool
├── flagged: Bool
└── is_deleted: Bool
```

## Setup

1. Configure Firebase in your project
2. Add the required Firebase dependencies
3. Set up Firestore security rules
4. Import your line and station data to Firestore

## Migration

The app automatically migrates local UserDefaults data to Firebase on first login after the update. This ensures users don't lose their existing visit data.

## Security

- Users can only access their own visit data
- Line and station data is publicly readable
- User documents are created only when needed
- No duplicate user creation

## Performance

- Data is loaded in parallel for optimal performance
- Real-time listeners only for user-specific data
- Efficient filtering and progress calculations
- Proper memory management with weak references

## LineListView.swift

This SwiftUI view displays a scrollable list of Tokyo train lines for the Ekicho iOS app. Each line is shown as a card with the line name, a circular color indicator, a label showing the number of stations visited, and a horizontal progress bar. Tapping a card navigates to a StationListView for that line. The layout is optimized for readability on iPhone 15 Pro Max. The file also includes a reusable LineCardView component for each card.
