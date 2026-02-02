Pinterest Clone - Complete Flutter App in Single File
📱 About The Project
A fully functional Pinterest clone built entirely within a single main.dart file using Flutter. This project demonstrates the ability to create complex, production-ready applications with clean architecture, state management, API integration, and pixel-perfect UI - all in one organized file.

🎯 Key Features
✅ Complete Pinterest UI - Pixel-perfect replica with all screens

✅ Real Pexels API Integration - Fetches real images using your API key

✅ Single File Architecture - Entire app (2500+ lines) in main.dart

✅ Riverpod State Management - Professional state handling

✅ GoRouter Navigation - Smooth screen transitions

✅ Image Caching - Optimized performance with cached_network_image

✅ All 6 Screens - Home, Search, Create, Profile, Pin Detail, Auth

🚀 Quick Start
1. Prerequisites
bash
# Install Flutter
flutter --version  # Should be >=3.0.0

# Get Pexels API Key (Free)
# Visit: https://www.pexels.com/api
2. Setup & Run
bash
# Create new Flutter project
flutter create pinterest_clone
cd pinterest_clone

# Replace lib/main.dart with provided code
# Update API key in the code (search for 'YOUR_API_KEY')

# Install dependencies
flutter pub get

# Run the app
flutter run
3. Configure API Key
Replace the API key in the code:

dart
// Line 230 in main.dart
static const String _apiKey = '9ZJxJK2uwsrC7NDWO54sbW5cwLPDKDIFr1Gk4hGvOCsTIyai4vwT0DcH';
📁 Single File Architecture
text
main.dart (2500+ Lines)
├── 🔧 IMPORTS (Dart & Packages)
├── 🚀 MAIN FUNCTION (App Initialization)
├── 🎨 APP WIDGET (MaterialApp.router)
├── 🗺️ ROUTING SYSTEM (GoRouter with ShellRoute)
├── 📊 DATA LAYER
│   ├── Pin Model (from Pexels API)
│   ├── Pexels Data Source (API calls)
│   └── Repository Pattern
├── ⚡ PROVIDERS (Riverpod State Management)
│   ├── Home Provider (Pins grid)
│   ├── Search Provider (Debounced search)
│   └── Profile Provider (User data)
├── 🖥️ ALL 6 SCREENS
│   ├── HomeScreen (Masonry grid)
│   ├── SearchScreen (Real-time search)
│   ├── CreateScreen (Pin creation)
│   ├── ProfileScreen (User profile)
│   ├── PinDetailScreen (Hero animations)
│   └── AuthScreen (OAuth options)
└── ⏱️ UTILITY CLASSES (Timer for debouncing)
📱 Screens
🏠 Home Screen
Pinterest-style masonry grid layout

Infinite scrolling with pagination

Pull-to-refresh functionality

Like/Save pins with state persistence

Real images from Pexels API

Loading states with shimmer effects

🔍 Search Screen
Real-time search with 500ms debouncing

Recent & popular search suggestions

Category exploration (Home Decor, Fashion, etc.)

Search results in grid view

Loading and error states

➕ Create Screen
Image upload simulation

Title, description, and link inputs

Form validation

Publish functionality

👤 Profile Screen
User profile with avatar and stats

Follow/Unfollow system

User's pins collection

Edit profile options

Gradient header design

📌 Pin Detail Screen
Full-screen pin view with Hero animation

Photographer information

Follow button

Share, Download, Save, Like actions

Related pins carousel

Smooth back navigation

🔐 Auth Screen
Google OAuth integration

Facebook OAuth integration

Email signup option

Terms and privacy policy

🛠️ Tech Stack
Technology	Purpose	Version
Flutter	UI Framework	>=3.0.0
Riverpod	State Management	^2.4.9
GoRouter	Navigation	^13.0.1
Dio	HTTP Client	^5.4.0
CachedNetworkImage	Image Loading	^3.3.0
Shimmer	Loading Effects	^3.0.0
Flutter Staggered Grid View	Pinterest Layout	^0.7.2
Clerk Flutter	Authentication	^0.6.0
📦 Dependencies
yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  go_router: ^13.0.1
  dio: ^5.4.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  flutter_staggered_grid_view: ^0.7.2
  clerk_flutter: ^0.6.0
  share_plus: ^7.2.1
  url_launcher: ^6.2.2
  pull_to_refresh: ^2.0.0
🎨 UI/UX Features
Design System
Color Palette: Pinterest red (#E60023) with grayscale

Typography: Roboto font with proper sizing

Spacing: Consistent 8px grid system

Shadows: Subtle shadows for depth

Border Radius: 16px for cards, 20px for buttons

Animations
Hero animations for pin transitions

Smooth page transitions

Loading shimmer effects

Pull-to-refresh with custom indicator

Bottom navigation bar transitions

Responsive Design
Masonry grid adapts to screen width

Images maintain aspect ratio

Touch targets are minimum 44x44px

Works on all screen sizes

⚡ Performance Optimizations
Image Caching: CachedNetworkImage for memory and disk caching

API Debouncing: 500ms delay for search to prevent API spam

Lazy Loading: Infinite scroll with pagination

Optimized Rebuilds: Riverpod selectors for minimal widget rebuilds

Memory Management: Proper disposal of controllers and listeners

Error Handling: Graceful degradation with fallback UI

🔧 Architecture Patterns
Clean Architecture (in Single File)
text
┌─────────────────────────────────────┐
│         PRESENTATION LAYER          │
│   ┌─────────────────────────────┐   │
│   │        SCREENS (UI)         │   │
│   └─────────────────────────────┘   │
│               │                     │
│               ▼                     │
│   ┌─────────────────────────────┐   │
│   │      PROVIDERS (State)      │   │
│   └─────────────────────────────┘   │
│               │                     │
│               ▼                     │
│   ┌─────────────────────────────┐   │
│   │  REPOSITORY (Business Logic)│   │
│   └─────────────────────────────┘   │
│               │                     │
│               ▼                     │
│   ┌─────────────────────────────┐   │
│   │ DATA SOURCE (API/Network)   │   │
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘
State Management with Riverpod
StateNotifierProvider for complex state

Provider for dependency injection

ConsumerWidget and ConsumerStatefulWidget for UI

Proper separation of business logic and presentation

📊 API Integration
Pexels API Endpoints Used
GET /v1/curated - Home screen pins

GET /v1/search - Search functionality

GET /v1/popular - Popular pins (fallback)
