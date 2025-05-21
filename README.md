# Casa Del Gusto Billing App

A Flutter-based point-of-sale and billing application for Casa Del Gusto restaurant. This application provides a seamless interface for managing menu items and processing sales.

## Overview

Casa Del Gusto Billing App is designed for restaurant staff to process customer orders and generate bills.

## Features

- **Menu Management**: Display and manage menu items with prices
- **Item Selection**: Select items for billing with quantity control
- **Payment Processing**: Process payments and calculate balance
- **Real-time Synchronization**: Sync data with Firebase

## Technologies Used

### Frontend
- **Flutter**: Cross-platform UI toolkit for building natively compiled applications
- **Dart**: Programming language (SDK: ^3.7.2)
- **Cupertino Icons**: ^1.0.8 - iOS style icons

### Backend & Data Storage
- **Firebase**:
  - **Firebase Core**: ^3.13.0 - Core Firebase functionality
  - **Cloud Firestore**: ^5.6.7 - NoSQL cloud database for storing menu items and sales data

### Network Management
- **Connectivity Plus**: ^5.0.1 - Flutter plugin to detect network connectivity changes

### UI/UX
- **Material Design**: Modern UI design language for a consistent user experience
- **Custom Theme**: Tailored restaurant-themed color palette and styling
- **App Icons**: Custom launcher icons with adaptive icon support
- **Custom Splash Screen**: Branded splash screen with fullscreen support

### Development Dependencies
- **Flutter Lints**: ^5.0.0 - Recommended lint rules for Flutter projects
- **Flutter Launcher Icons**: ^0.14.3 - Simplifies the creation of app launcher icons
- **Flutter Native Splash**: ^2.3.13 - Customizable splash screens for Flutter apps

## App Configuration

- **Version**: 1.0.0+1
- **Splash Screen**: Custom splash with background color #f7dfd7
- **Icon**: Adaptive icons with customized foreground and background

## Project Structure

```
lib/
  ├── main.dart             # Application entry point and theme configuration
  ├── screens/
  │   └── home_page.dart    # Main screen with menu and billing functionality
  ├── services/
  │   └── network_service.dart  # Network connectivity management service
  └── widgets/
      └── network_aware_widget.dart  # Widget for handling online/offline states
```

## Core Functionality

### Sales Processing
- Select menu items to add to the current bill
- Track quantities and calculate total cost
- Generate unique sale IDs and store transaction data

### Network Awareness
- Detect network status changes (online/offline)
- Provide visual feedback through UI when offline

### Data Management
- Store menu items in Firestore database
- Record completed sales with timestamps
- Track individual sale items with quantities and prices

## Getting Started

1. Clone the repository
2. Ensure Flutter is installed on your development machine
3. Run `flutter pub get` to install dependencies
4. Configure Firebase by adding your `google-services.json` to the Android app directory
5. Run `flutter run` to launch the application on your device or simulator

## Requirements

- Flutter SDK
- Firebase account
- Android/iOS device or emulator
