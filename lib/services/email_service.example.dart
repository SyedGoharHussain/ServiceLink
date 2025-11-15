import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

/// Email service for sending OTP and other emails via SMTP
///
/// SETUP INSTRUCTIONS:
/// 1. Copy this file and rename it to 'email_service.dart' (remove .example)
/// 2. Replace the placeholder credentials below with your actual SMTP credentials
/// 3. For Gmail:
///    - Enable 2-Factor Authentication on your Google Account
///    - Generate an App Password: https://myaccount.google.com/apppasswords
///    - Use the App Password (NOT your regular Gmail password)
/// 4. Never commit the real email_service.dart file to version control
class EmailService {
  // SMTP Configuration - Replace with your credentials
  static const String _smtpUsername = 'your-email@gmail.com';
  static const String _smtpPassword =
      'your-app-password-here'; // Use App Password for Gmail
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _appName = 'ServiceLink';

  /// Generate a 6-digit OTP
  static String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP email
  Future<Map<String, dynamic>> sendOTP(String toEmail, String otp) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: true,
      );

      final message = Message()
        ..from = Address(_smtpUsername, _appName)
        ..recipients.add(toEmail)
        ..subject = 'Your $_appName Verification Code'
        ..html =
            '''
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
              }
              .container {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 10px;
                padding: 40px;
                text-align: center;
              }
              .content {
                background: white;
                border-radius: 8px;
                padding: 30px;
                margin: 20px 0;
              }
              .otp {
                font-size: 32px;
                font-weight: bold;
                color: #667eea;
                letter-spacing: 5px;
                margin: 20px 0;
                padding: 15px;
                background: #f0f0f0;
                border-radius: 5px;
              }
              .footer {
                color: white;
                font-size: 12px;
                margin-top: 20px;
              }
              h1 {
                color: white;
                margin: 0;
              }
              p {
                margin: 10px 0;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>$_appName</h1>
              <div class="content">
                <h2>Email Verification</h2>
                <p>Thank you for registering with $_appName!</p>
                <p>Your verification code is:</p>
                <div class="otp">$otp</div>
                <p>This code will expire in 10 minutes.</p>
                <p>If you didn't request this code, please ignore this email.</p>
              </div>
              <div class="footer">
                <p>© 2025 $_appName. All rights reserved.</p>
                <p>This is an automated message, please do not reply.</p>
              </div>
            </div>
          </body>
          </html>
          ''';

      final sendReport = await send(message, smtpServer);
      return {
        'success': true,
        'message': 'OTP sent successfully to $toEmail',
        'messageId': sendReport.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send OTP: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Send welcome email
  Future<Map<String, dynamic>> sendWelcomeEmail(
    String toEmail,
    String userName,
  ) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: true,
      );

      final message = Message()
        ..from = Address(_smtpUsername, _appName)
        ..recipients.add(toEmail)
        ..subject = 'Welcome to $_appName!'
        ..html =
            '''
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
              }
              .container {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 10px;
                padding: 40px;
              }
              .content {
                background: white;
                border-radius: 8px;
                padding: 30px;
                margin: 20px 0;
              }
              h1 {
                color: white;
                text-align: center;
                margin: 0 0 20px 0;
              }
              h2 {
                color: #667eea;
              }
              .button {
                display: inline-block;
                padding: 12px 30px;
                background: #667eea;
                color: white;
                text-decoration: none;
                border-radius: 5px;
                margin: 20px 0;
              }
              .footer {
                color: white;
                text-align: center;
                font-size: 12px;
                margin-top: 20px;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>$_appName</h1>
              <div class="content">
                <h2>Welcome, $userName! 🎉</h2>
                <p>Thank you for joining $_appName, your trusted platform for connecting with local service providers.</p>
                <p>You can now:</p>
                <ul>
                  <li>Browse and hire skilled workers</li>
                  <li>Manage your service requests</li>
                  <li>Chat with service providers</li>
                  <li>Rate and review services</li>
                </ul>
                <p style="text-align: center;">
                  <a href="#" class="button">Get Started</a>
                </p>
                <p>If you have any questions, feel free to reach out to our support team.</p>
              </div>
              <div class="footer">
                <p>© 2025 $_appName. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
          ''';

      final sendReport = await send(message, smtpServer);
      return {'success': true, 'message': 'Welcome email sent to $toEmail'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send welcome email: ${e.toString()}',
      };
    }
  }

  /// Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(
    String toEmail,
    String resetCode,
  ) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: true,
      );

      final message = Message()
        ..from = Address(_smtpUsername, _appName)
        ..recipients.add(toEmail)
        ..subject = 'Password Reset Request - $_appName'
        ..html =
            '''
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
              }
              .container {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 10px;
                padding: 40px;
                text-align: center;
              }
              .content {
                background: white;
                border-radius: 8px;
                padding: 30px;
                margin: 20px 0;
              }
              .code {
                font-size: 28px;
                font-weight: bold;
                color: #667eea;
                letter-spacing: 3px;
                margin: 20px 0;
                padding: 15px;
                background: #f0f0f0;
                border-radius: 5px;
              }
              .warning {
                color: #e74c3c;
                font-weight: bold;
                margin: 15px 0;
              }
              h1 {
                color: white;
                margin: 0;
              }
              .footer {
                color: white;
                font-size: 12px;
                margin-top: 20px;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>$_appName</h1>
              <div class="content">
                <h2>Password Reset Request</h2>
                <p>We received a request to reset your password.</p>
                <p>Your password reset code is:</p>
                <div class="code">$resetCode</div>
                <p>This code will expire in 15 minutes.</p>
                <p class="warning">⚠️ If you didn't request this, please ignore this email and your password will remain unchanged.</p>
              </div>
              <div class="footer">
                <p>© 2025 $_appName. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
          ''';

      final sendReport = await send(message, smtpServer);
      return {
        'success': true,
        'message': 'Password reset email sent to $toEmail',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send password reset email: ${e.toString()}',
      };
    }
  }

  /// Send job request notification to worker
  Future<Map<String, dynamic>> sendJobRequestNotification({
    required String workerEmail,
    required String workerName,
    required String customerName,
    required String serviceType,
    required double budget,
  }) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: true,
      );

      final message = Message()
        ..from = Address(_smtpUsername, _appName)
        ..recipients.add(workerEmail)
        ..subject = 'New Job Request - $_appName'
        ..html =
            '''
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
              }
              .container {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 10px;
                padding: 40px;
              }
              .content {
                background: white;
                border-radius: 8px;
                padding: 30px;
                margin: 20px 0;
              }
              .info-box {
                background: #f8f9fa;
                border-left: 4px solid #667eea;
                padding: 15px;
                margin: 15px 0;
              }
              h1 {
                color: white;
                text-align: center;
                margin: 0;
              }
              .footer {
                color: white;
                text-align: center;
                font-size: 12px;
                margin-top: 20px;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>$_appName</h1>
              <div class="content">
                <h2>🔔 New Job Request!</h2>
                <p>Hello $workerName,</p>
                <p>You have received a new job request:</p>
                <div class="info-box">
                  <p><strong>Customer:</strong> $customerName</p>
                  <p><strong>Service:</strong> $serviceType</p>
                  <p><strong>Budget:</strong> Rs. ${budget.toStringAsFixed(0)}</p>
                </div>
                <p>Log in to your account to view details and respond to this request.</p>
              </div>
              <div class="footer">
                <p>© 2025 $_appName. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
          ''';

      final sendReport = await send(message, smtpServer);
      return {
        'success': true,
        'message': 'Job notification sent to $workerEmail',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send job notification: ${e.toString()}',
      };
    }
  }
}
