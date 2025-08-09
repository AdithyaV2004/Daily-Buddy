<img width="3188" height="1202" alt="frame (3)" src="https://github.com/user-attachments/assets/517ad8e9-ad22-457d-9538-a9e62d137cd7" />


# Kili Poya Buddy 🎯


## Connect anonymously, chat for a day, and find a fleeting friend. Kili Poya Buddy pairs you with a random stranger for a 24-hour conversation, with a twist: every message you send is transformed into its opposite meaning by an AI.
### Team Name: Black & Brown


### Team Members
- Member 1: Adithya Vinod - MITS
- Member 2: Christo Berly - MITS

### Project Description
Kili Poya Buddy is a mobile chat application designed to combat loneliness by fostering temporary, anonymous connections. Users can register with just a username and are randomly paired with another user from a waiting pool. The chat lasts for exactly 24 hours, after which it is deleted, ensuring privacy and encouraging users to make the most of their brief connection.

The unique feature of Kili Poya Buddy is its AI-powered message transformation. Before a message is delivered, it's sent to the Groq API, which rewrites it to have the opposite meaning. This adds a fun and thought-provoking layer to the conversation, challenging users to communicate in new and creative ways.

### The Problem (that doesn't exist)
In an increasingly digital world, many people experience feelings of isolation and a desire for spontaneous social interaction without the pressure of maintaining long-term relationships. The challenge is to create a safe, low-stakes environment where individuals can share a moment with someone new, free from the permanence and expectations of traditional social media.

### The Solution (that nobody asked for)
Kili Poya Buddy solves this by providing a platform for ephemeral, anonymous conversations.

Anonymity: Users only need a username, protecting their real identity.

Time-Bound Chats: The 24-hour limit creates a sense of occasion and reduces the burden of long-term engagement.

AI-Powered Twist: The "opposite message" feature turns simple chats into a fun game, breaking the ice and encouraging creative expression.

No Chat History: All conversations are deleted after 24 hours, guaranteeing privacy and a fresh start with every new connection.

## Technical Details
### Technologies/Components Used
For Software:

Framework: Flutter

Backend & Database: Firebase (Firestore)

Authentication: Firebase Authentication (Anonymous Sign-in)

AI Integration: Groq API (for message transformation)

Language: Dart

### Implementation
For Software:
# Installation
Clone the repository:

git clone https://github.com/AdithyaV2004/Daily-Buddy.git

Set up Firebase:

Add your google-services.json (Android) and GoogleService-Info.plist (iOS) files to the project as per the Firebase setup instructions.

Ensure your Firestore security rules are configured to allow reads/writes for authenticated users.

Add API Key:

Create a file at lib/config/secrets.dart.

Add your Groq API key to this file:

lib/config/api_key.dart

Ensure your .gitignore file contains lib/config/secrets.dart to keep your key private.

flutter pub get

# Run
flutter run

🛠️ Tech Stack
Framework: Flutter

Backend & Database: Firebase (Firestore)

Authentication: Firebase Authentication (Anonymous Sign-in)

AI Integration: Groq API (for message transformation)

Language: Dart

🚀 Getting Started
Prerequisites
Flutter SDK installed

A Firebase project set up

A Groq Cloud account and API key

📄 Project Documentation
The project follows a modular, feature-first directory structure to keep the codebase organized and scalable.

lib/screens/: Contains all the UI pages, separated into auth, home, and chat folders.

lib/services/: Houses the business logic, such as the groq_service.dart which handles all API communication.

lib/config/: Stores configuration files, including the secrets.dart file for the API key.

lib/main.dart: The app's entry point, responsible for initialization and theme setup.

# Screenshots (Add at least 3)
<img width="200" height="500" alt="1000049740" src="https://github.com/user-attachments/assets/9d28ab81-a9e8-45d5-a752-7c16118f281f" />

Registration page for user. User can type any name.

<img width="200" height="500" alt="1000049741" src="https://github.com/user-attachments/assets/98a28987-0925-4f39-b2b5-03f37c18a6f7" />

Tab to connect with a buddy.

<img width="200" height="500" alt="1000049742" src="https://github.com/user-attachments/assets/e82049db-f965-4df6-9819-c449ec5f7632" />

Chat interface from sender

<img width="200" height="500" alt="Screenshot_20250809-050810" src="https://github.com/user-attachments/assets/b427bc86-a2dc-4a89-bfc9-4baecc5d8357" />

Chat interface for receiver


### Project Demo
# Video


https://github.com/user-attachments/assets/1937df25-3975-4ed6-beed-f49ec62d81f5


Workflow of the Kili Poya Buddy App

---
Made with ❤️ at TinkerHub Useless Projects 

![Static Badge](https://img.shields.io/badge/TinkerHub-24?color=%23000000&link=https%3A%2F%2Fwww.tinkerhub.org%2F)
![Static Badge](https://img.shields.io/badge/UselessProjects--25-25?link=https%3A%2F%2Fwww.tinkerhub.org%2Fevents%2FQ2Q1TQKX6Q%2FUseless%2520Projects)


