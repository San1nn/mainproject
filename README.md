# MainProject - Student Communication and Learning Platform

## 📚 Overview

Effective communication is essential for academic collaboration among students. With the growing dependence on digital platforms for learning, students require communication systems that support focused and productive discussions. Most existing communication tools are general-purpose and often contain distractions that reduce learning efficiency.

**MainProject** is a **Student Communication and Learning Platform** designed specifically for academic interaction. The platform enables students to participate in:

- **Public Rooms**: Subject-based discussions accessible to all students
- **Private Rooms**: Project groups or class-specific communication
- **Real-time Messaging**: Text and voice messages for efficient knowledge sharing
- **AI-Enhanced Features**: Chat summarization and foul language detection

The application is built with **Flutter** and backed by **Firebase**, providing a smooth, intuitive, and cross-platform user experience across iOS, Android, Windows, and Web. It features robust backend services for real-time synchronization, secure authentication, and scalable data storage.

---

## 🎯 Key Features

### ✅ Authentication & Authorization
- User registration with email/password validation
- Secure login and logout functionality
- Role-based access control (RBAC) with Admin, Moderator, and User roles
- Session management and auto-authentication

### 💬 Communication Features
- **Public Rooms**: Browse and join subject-based discussions
- **Private Rooms**: Create and manage project/group communication channels
- **Real-time Messaging**: Instant text message delivery
- **Voice Messages**: Send audio messages for richer communication

### 🤖 AI & Smart Features
- **Chat Summarization**: Automatically summarize lengthy discussions
- **Content Moderation**: Foul language detection to maintain respectful communication
- **Smart Recommendations**: Suggest relevant rooms and discussions

### 🔐 Security & Design
- Role-based access control with specific permissions per role
- Secure authentication flow with proper validation
- Modern UI with Material Design 3
- Responsive layouts for all screen sizes

---

## 🏗️ Project Architecture

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10.7 or higher
- Dart 3.10.7 or higher
- Android Studio / Xcode (for native builds)

### Installation

1. **Clone the repository**
   ```bash
   cd MainProject
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

---

## 📱 App Navigation Flow

```
Splash Screen (3 seconds)
        ↓
Check Authentication Status
        ↓
    ┌───────────────┐
    ↓               ↓
Not Authenticated  Authenticated
    ↓               ↓
Login Screen ──→ Dashboard Screen
    ↓               ├─→ Rooms Screen
Register Screen    ├─→ Settings Screen
                   └─→ Room Detail/Chat
```

---

## 🧪 Testing the Application

### Demo Accounts

**Admin Account** (Full Access)
- Email: `admin@example.com`
- Password: `password123`
- Features: All rooms, moderation tools, admin dashboard

**User Account** (Standard Access)
- Email: `user@example.com`
- Password: `password123`
- Features: Browse and join rooms, send messages

### Test Scenarios

1. **Login Flow**
   - Start the app
   - Enter demo credentials
   - Verify automatic navigation to dashboard

2. **Room Browsing**
   - Navigate to rooms screen
   - View available public and private rooms
   - Search and filter rooms

3. **Messaging**
   - Join a room
   - Send text messages
   - Send voice messages

4. **Content Moderation**
   - Send message with inappropriate language
   - Verify automatic flag/filtering

---

## 💾 Data Management

### User Model
- **ID**: Unique identifier
- **Email**: User email address
- **Name**: Full name
- **Role**: Admin, Moderator, or User
- **CreatedAt**: Account creation timestamp

### Room Model
- **ID**: Unique room identifier
- **Name**: Room title
- **Description**: Room purpose
- **Type**: Public or Private
- **Members**: List of member IDs
- **CreatedAt**: Creation timestamp

### Message Model
- **ID**: Unique message ID
- **RoomID**: Associated room
- **SenderID**: User who sent message
- **Content**: Message text
- **Type**: Text or Voice
- **Timestamp**: Send time

---

## 🛠️ Development

### State Management
Currently using `StatefulWidget` for local state. Future updates may integrate:
- Provider package for global state
- Riverpod for reactive state management
- BLoC for complex business logic

### Code Organization
- Separation of concerns between UI, business logic, and data
- Reusable widgets and utility functions
- Constants for theme and string resources

### Testing
- Widget tests for UI components
- Integration tests for user flows
- Unit tests for service logic

---

## 📝 License

This project is part of academic work. All rights reserved.
