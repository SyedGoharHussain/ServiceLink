# SMTP Email Configuration Guide

This guide explains how to configure SMTP for sending OTP emails in the ServiceLink app.

## Option 1: Gmail SMTP (Recommended for Development)

### Step 1: Enable 2-Step Verification

1. Go to your Google Account: https://myaccount.google.com/
2. Click **Security** in the left sidebar
3. Scroll to "2-Step Verification"
4. Click "Get Started" and follow the instructions to enable 2-Step Verification

### Step 2: Generate App Password

1. After enabling 2-Step Verification, go back to **Security**
2. Scroll to "2-Step Verification" section
3. At the bottom, click **App passwords**
   - If you don't see this option, make sure 2-Step Verification is enabled
4. In the dropdown:
   - Select app: **Mail**
   - Select device: **Other (Custom name)**
   - Enter name: "Flutter ServiceLink App"
5. Click **Generate**
6. **IMPORTANT**: Copy the 16-character password (it's shown without spaces)
   - Example: `abcd efgh ijkl mnop` (but you'll use it without spaces: `abcdefghijklmnop`)

### Step 3: Update Configuration

Open `lib/services/email_service.dart` and update these lines:

```dart
static const String _smtpUsername = 'your-email@gmail.com'; // Your Gmail address
static const String _smtpPassword = 'your-app-password'; // 16-character app password
```

**Example:**
```dart
static const String _smtpUsername = 'john.doe@gmail.com';
static const String _smtpPassword = 'abcdefghijklmnop'; // No spaces!
```

## Option 2: Other Email Providers

### SendGrid (Production Recommended)

1. Sign up at https://sendgrid.com/
2. Create an API Key
3. Update email_service.dart:
```dart
static const String _smtpHost = 'smtp.sendgrid.net';
static const int _smtpPort = 587;
static const String _smtpUsername = 'apikey'; // Literally 'apikey'
static const String _smtpPassword = 'YOUR_SENDGRID_API_KEY';
```

### Outlook/Hotmail

```dart
static const String _smtpHost = 'smtp-mail.outlook.com';
static const int _smtpPort = 587;
static const String _smtpUsername = 'your-email@outlook.com';
static const String _smtpPassword = 'your-password';
```

### Yahoo Mail

```dart
static const String _smtpHost = 'smtp.mail.yahoo.com';
static const int _smtpPort = 587;
static const String _smtpUsername = 'your-email@yahoo.com';
static const String _smtpPassword = 'your-app-password'; // Generate from Yahoo settings
```

## Testing Your Configuration

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

3. Try signing up with a real email address
4. Check your email for the OTP code

## Common Issues

### Problem: "Authentication failed"
- **Solution**: Make sure you're using the App Password, not your regular Gmail password
- Verify 2-Step Verification is enabled
- Check that there are no spaces in the app password

### Problem: "Connection timeout"
- **Solution**: Check your internet connection
- Try using port 465 with SSL instead of 587 with TLS
- Some networks block SMTP ports - try on a different network

### Problem: Emails not arriving
- **Solution**: Check spam/junk folder
- Verify the recipient email is correct
- Check if Gmail has blocked the email (check Google account security notifications)

## Security Best Practices

### For Development:
- Use environment variables or a config file (not committed to git)
- Create a separate Gmail account just for testing

### For Production:
- Use a professional email service (SendGrid, AWS SES, Mailgun)
- Never commit credentials to version control
- Use environment variables or secrets management
- Add the credentials to `.gitignore`:

```bash
# Create .env file
echo "SMTP_USERNAME=your-email@gmail.com" > .env
echo "SMTP_PASSWORD=your-app-password" >> .env

# Add to .gitignore
echo ".env" >> .gitignore
```

## Email Service Features

The EmailService class provides:

1. **OTP Email** (`sendOTP`): Sends 6-digit verification code
2. **Password Reset** (`sendPasswordResetEmail`): Sends reset link
3. **Welcome Email** (`sendWelcomeEmail`): Sends welcome message after signup

## Customization

You can customize email templates in `lib/services/email_service.dart`:
- Modify HTML templates
- Change colors (currently using #2196F3)
- Add your logo
- Update sender name

## Alternative: Firebase Email Verification

The app also supports Firebase's built-in email verification (already configured):
- Automatically sends verification emails
- No SMTP configuration needed
- Limited customization

OTP with SMTP gives you more control over:
- Email design
- Verification flow
- Custom branding
- Analytics

## Need Help?

If you encounter issues:
1. Check Google Account security settings
2. Verify 2-Step Verification is active
3. Make sure App Password was copied correctly
4. Try generating a new App Password
5. Check Flutter console for detailed error messages
