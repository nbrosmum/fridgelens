# fridgelens
Final Year Project  - APU assignment 

📱 Project Overview

FridgeLens is a mobile application that helps users manage household food inventory and reduce food waste. Using image recognition, the app allows users to quickly scan and add food items, track expiry dates, and share inventory with other users — improving household food management and supporting Sustainable Development Goal (SDG) 12: Responsible Consumption and Production.

Features

Image Recognition to detect and add food items

Manual food entry option for accuracy

Expiry Date Notifications to reduce food waste

Shared Inventory — collaborate with family/housemates

Basic Reports on food consumption & wastage

Built with Flutter — optimized for Android

Tech Stack
Frontend: Flutter (Dart)

Backend/Database: Firebase Realtime Database

IDE: Visual Studio Code

Operating System: Android

Methodology: Agile (Kanban)

APIs/Cloud Services Used:
- Firebase Authentication (user login/register)
- Firebase Firestore (data storage)
- ImageKit.io (cloud image storage and management)

Getting Started

Clone the repository:

bash

``git clone https://github.com/nbrosmum/fridgelens.git``

Navigate to the project directory:

bash

``cd fridgelens``

Install dependencies

bash

``flutter pub get``

Run the app on an Android device or emulator:

bash

``flutter run``

---

## ImageKit.io Setup

This project uses [ImageKit.io](https://imagekit.io/) for cloud image storage and management.

1. Register for an ImageKit.io account and create a project.
2. Get your **Public Key** and **Private Key** from the ImageKit dashboard.
3. Open `lib/utils/imagekit_config.dart` and fill in your keys:

```dart
static const String publicKey = 'YOUR_PUBLIC_KEY';
static const String privateKey = 'YOUR_PRIVATE_KEY';
```

4. (Optional) Set your custom upload folder or endpoint if needed.

**Note:** ImageKit is used for uploading, deleting, and managing all food item images in the app. When a fridge is deleted, all images and the corresponding folder in ImageKit will be deleted automatically.
