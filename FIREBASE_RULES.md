# Firebase Security Rules Deployment Guide

This project includes three types of Firebase security rules:

## 📄 Files Created

1. **firestore.rules** - Firestore Database security rules
2. **database.rules.json** - Realtime Database security rules  
3. **storage.rules** - Cloud Storage security rules

## 🚀 How to Deploy

### Option 1: Using Firebase Console (Manual)

#### Firestore Rules
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `mids-project-6b09c`
3. Navigate to **Firestore Database** → **Rules**
4. Copy the content from `firestore.rules` and paste it
5. Click **Publish**

#### Realtime Database Rules
1. Go to **Realtime Database** → **Rules**
2. Copy the content from `database.rules.json` and paste it
3. Click **Publish**

#### Storage Rules
1. Go to **Storage** → **Rules**
2. Copy the content from `storage.rules` and paste it
3. Click **Publish**

### Option 2: Using Firebase CLI (Recommended)

1. **Install Firebase CLI** (if not already installed):
   ```powershell
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```powershell
   firebase login
   ```

3. **Deploy all rules at once**:
   ```powershell
   firebase deploy --only firestore:rules,database:rules,storage:rules
   ```

   Or deploy individually:
   ```powershell
   # Firestore only
   firebase deploy --only firestore:rules
   
   # Realtime Database only
   firebase deploy --only database:rules
   
   # Storage only
   firebase deploy --only storage:rules
   ```

## 🔐 Security Rules Explained

### Firestore Rules (`firestore.rules`)

#### Users Collection
- ✅ **Read**: Any authenticated user (to view worker profiles)
- ✅ **Create**: Only if userId matches authenticated user
- ✅ **Update**: Only the owner can update their profile
- ✅ **Delete**: Only the owner can delete their account
- ❌ Cannot change role after creation

#### Requests Collection
- ✅ **Read**: Only customer or worker involved in the request
- ✅ **Create**: Only customers can create requests (status must be 'pending')
- ✅ **Update**: Workers can accept/reject, customers can complete/review
- ✅ **Delete**: Only customer can delete if status is still 'pending'

#### Chats Collection
- ✅ **Read/Write**: Only participants in the chat
- ✅ **Create**: User must be one of the 2 participants

#### Messages Subcollection
- ✅ **Read**: Participants of the parent chat
- ✅ **Create**: Only sender who is a participant
- ✅ **Update**: Participants (for marking as read)
- ✅ **Delete**: Only the message sender

### Realtime Database Rules (`database.rules.json`)

- ✅ Chats accessible only by participants
- ✅ Messages require senderId, text, and timestamp
- ✅ Each chat must have exactly 2 participants

### Storage Rules (`storage.rules`)

#### Profile Images
- ✅ **Read**: Public (anyone can view)
- ✅ **Write**: Only owner, must be image, max 5MB
- ✅ **Delete**: Only owner

#### Chat Images
- ✅ **Read**: Authenticated users
- ✅ **Write**: Authenticated users, must be image, max 5MB

## ⚠️ Important Notes

1. **Test Mode**: Current rules require authentication. Never use test mode in production:
   ```
   // DON'T USE THIS IN PRODUCTION
   allow read, write: if true;
   ```

2. **Indexes**: You may need to create indexes for queries. Firebase will show errors in the console with direct links to create them.

3. **Required Indexes** (create these in Firestore console):
   - Collection: `users`
     - Fields: `role` (Ascending), `city` (Ascending)
     - Fields: `role` (Ascending), `serviceType` (Ascending)
   
   - Collection: `requests`
     - Fields: `workerId` (Ascending), `createdAt` (Descending)
     - Fields: `customerId` (Ascending), `createdAt` (Descending)

4. **Authentication Required**: All rules assume Firebase Authentication is enabled. Make sure users are properly authenticated before accessing data.

## 🧪 Testing Rules

Test your rules in the Firebase Console:
1. Go to **Firestore/Database/Storage** → **Rules**
2. Click on **Rules Playground**
3. Test different scenarios with different user IDs

## 📱 Common Error Messages

- **"Missing or insufficient permissions"**: User not authenticated or trying to access data they don't own
- **"PERMISSION_DENIED"**: User doesn't have permission for the operation
- **"Index required"**: Create the suggested index in Firebase Console

## 🔄 After Deployment

1. Test authentication flow
2. Test creating a user profile
3. Test creating a request
4. Test chat functionality
5. Test image uploads

If you encounter any permission errors, check the browser console or app logs for specific error messages.
