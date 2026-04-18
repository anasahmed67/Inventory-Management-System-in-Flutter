# Stockify - Inventory Management System

A full-stack inventory management solution built with a **Flutter** frontend and a **Dart (Shelf)** backend, using **MySQL** for data persistence.

## 🚀 Features

- **Role-Based Access Control (RBAC)**: Admin and Staff roles with specific permissions.
- **Product Management**: Create, Read, Update, and Delete products (Admin only).
- **Stock Adjustments**: Real-time stock updates with barcode scanning integration.
- **Transaction History**: Audit logs for every movement in the inventory.
- **Reports**: Dashboard summaries and low-stock alerts.
- **Database**: Reliable MySQL storage with transactional integrity.

## 🛠️ Prerequisites

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK**: (Included with Flutter)
- **XAMPP**: [Download XAMPP](https://www.apachefriends.org/index.html) (for MySQL & phpMyAdmin)
- **Git** (optional)

## 📦 Setup Instructions

### 1. Database Setup
1. Start **XAMPP** and turn on **MySQL**.
2. Open **phpMyAdmin** (usually `http://localhost/phpmyadmin`).
3. Create a new database named `inventory_db`.
4. Import the schema file located at `database/schema.sql` into the newly created database.

### 2. Backend Configuration
1. Navigate to the `backend` folder:
   ```bash
   cd inventory_system/backend
   ```
2. Install dependencies:
   ```bash
   dart pub get
   ```
3. (Optional) Update the `.env` file with your database credentials if they differ from XAMPP defaults (root/no-password).
4. Start the server:
   ```bash
   dart run bin/server.dart
   ```
   *The server will listen on `http://localhost:8080`.*

### 3. Frontend Setup
1. Navigate to the `frontend` folder:
   ```bash
   cd inventory_system/frontend
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   - For **Chrome**: `flutter run -d chrome`
   - For **Android**: Ensure an emulator is running, then `flutter run`

## 🔑 Login Credentials

| Role  | Email | Password |
| :--- | :--- | :--- |
| **Admin** | `admin@example.com` | `admin123` |
| **Staff** | `staff@example.com` | `staff123` |

> Note: For local development, passwords are stored in plain text in the sample data.
> Do not use this in production; always store hashed passwords.

## 📱 Platforms Tested
- **Chrome (Desktop/Web)**: Full management and reporting capabilities.
- **Android Emulator**: Verified barcode scanning and native mobile interactions.

## 📝 Troubleshooting
- **Connection Refused**: Ensure the backend server is running and the `baseUrl` in `api_service.dart` points to the correct IP (`10.0.2.2` for Android Emulators).
- **CORS Errors**: The backend is pre-configured with `shelf_cors_headers` to allow requests from local development origins.
