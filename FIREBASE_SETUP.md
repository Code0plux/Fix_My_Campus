# Firebase Setup Instructions

## Steps to configure Firebase:

1. **Install Firebase CLI:**
   ```
   npm install -g firebase-tools
   ```

2. **Login to Firebase:**
   ```
   firebase login
   ```

3. **Configure FlutterFire:**
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   - Select your Firebase project or create a new one
   - Select platforms (Android, iOS, Web, etc.)
   - This will generate `firebase_options.dart` automatically

4. **Enable Authentication in Firebase Console:**
   - Go to Firebase Console > Authentication
   - Enable Email/Password sign-in method

5. **Create Default Admin User:**
   - Go to Firebase Console > Authentication > Users
   - Add user manually with email: `admin@campus.com` and password
   - Go to Firestore Database
   - Create collection: `users`
   - Add document with ID matching the admin user's UID:
     ```
     {
       "username": "admin",
       "email": "admin@campus.com",
       "isAdmin": true,
       "createdAt": [current timestamp]
     }
     ```

6. **Setup Firestore Database:**
   - Go to Firebase Console > Firestore Database
   - Create database in production mode
   - Create collection: `complaints` (will be auto-created when first complaint is added)

7. **Update Firestore Rules:**
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null;
       }
       match /complaints/{complaintId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null;
       }
     }
   }
   ```

8. **Run the app:**
   ```
   flutter pub get
   flutter run
   ```

## Default Admin Credentials:
- Email: admin@campus.com
- Password: [Set your own secure password]
- This admin can view all complaints in the Admin Dashboard
