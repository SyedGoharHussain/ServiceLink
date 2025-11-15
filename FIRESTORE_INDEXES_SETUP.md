# URGENT: Firebase Indexes Required

## 🚨 Your app needs Firestore indexes to work properly!

### Issue
You're seeing this error:
```
The query requires an index. You can create it here: https://console.firebase.google.com/...
```

### Quick Fix - Click These Links:

#### 1. Worker Requests Index
**Click this link to create the index automatically:**
```
https://console.firebase.google.com/v1/r/project/mids-project-6b09c/firestore/indexes?create_composite=ClNwcm9qZWN0cy9taWRzLXByb2plY3QtNmIwOWMvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3JlcXVlc3RzL2luZGV4ZXMvXxABGgwKCHdvcmtlcklkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg
```

This creates an index for:
- Collection: `requests`
- Fields: `workerId` (Ascending), `createdAt` (Descending)

#### 2. Customer Requests Index (might be needed)
If you see a similar error for customer requests, create this index:

**Manual steps:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `mids-project-6b09c`
3. Go to **Firestore Database** → **Indexes** tab
4. Click **Create Index**
5. Set:
   - Collection ID: `requests`
   - Field 1: `customerId` (Ascending)
   - Field 2: `createdAt` (Descending)
6. Click **Create**

### ⏱️ Index Creation Time
- Usually takes **5-10 minutes** to build
- You'll get an email when it's ready
- Refresh your app after it's built

### Alternative: Disable Persistence (Temporary)
If you need the app to work immediately while indexes build, you can temporarily disable offline persistence, but this is NOT recommended for production.

### Why This Happens
Firestore requires composite indexes for queries that:
- Filter by a field (e.g., `where('workerId', isEqualTo: ...)`)
- AND sort by another field (e.g., `orderBy('createdAt')`)

### After Creating Indexes
1. Wait for email confirmation (5-10 minutes)
2. Restart your Flutter app: `flutter run`
3. Everything should work smoothly!

### Current Status
✅ Error handling added - app won't crash
⏳ Waiting for indexes to be created
🔧 Chat functionality should work once indexes are built
