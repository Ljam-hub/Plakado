import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmailDispatchResult {
  final bool isSuccess;
  final String? messageId;
  final String? errorMessage;

  EmailDispatchResult({
    required this.isSuccess,
    this.messageId,
    this.errorMessage,
  });
}

class EmailService {
  // Configured via compile-time environment or CI/CD: --dart-define=RESEND_API_KEY=re_xxx
  static const String _resendApiKey = String.fromEnvironment('RESEND_API_KEY', defaultValue: '');
  static const String _fromAddress = 'ISUFST Gate Security <onboarding@resend.dev>';
  static const String _localSmtpRelayUrl = 'http://localhost:5050/send-otp';

  /// Sends the 6-digit verification code using Gmail SMTP (osiallj@gmail.com) with Resend fallback
  static Future<EmailDispatchResult> sendVerificationOtp({
    required String recipientEmail,
    required String code,
  }) async {
    final cleanRecipient = recipientEmail.trim().toLowerCase();

    // 1. Try Gmail SMTP Relay (sends to ANY address from osiallj@gmail.com)
    try {
      final localResponse = await http.post(
        Uri.parse(_localSmtpRelayUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': cleanRecipient,
          'code': code,
        }),
      ).timeout(const Duration(seconds: 4));

      if (localResponse.statusCode >= 200 && localResponse.statusCode < 300) {
        final data = jsonDecode(localResponse.body) as Map<String, dynamic>;
        debugPrint('Gmail SMTP delivered verification code to $cleanRecipient: ${data['messageId']}');
        return EmailDispatchResult(
          isSuccess: true,
          messageId: data['messageId']?.toString(),
        );
      }
    } catch (e) {
      debugPrint('Gmail SMTP local relay note: $e (Trying Resend fallback)');
    }

    // 2. Resend API Fallback
    if (_resendApiKey.isEmpty) {
      return EmailDispatchResult(
        isSuccess: false,
        errorMessage: 'Local SMTP relay unreachable and no RESEND_API_KEY environment variable provided.',
      );
    }

    try {
      final url = Uri.parse('https://api.resend.com/emails');

      final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 24px; }
    .container { max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.06); border: 1px solid #e2e8f0; }
    .header { background: linear-gradient(135deg, #1e3a8a, #2563eb); padding: 32px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0 0 6px 0; font-size: 20px; font-weight: 800; letter-spacing: 0.5px; }
    .header p { margin: 0; font-size: 13px; opacity: 0.9; }
    .content { padding: 32px 24px; text-align: center; color: #334155; }
    .instructions { font-size: 14px; line-height: 1.6; margin-bottom: 24px; color: #475569; }
    .otp-box { background: #f1f5f9; border: 2px dashed #cbd5e1; border-radius: 12px; padding: 20px; margin: 0 auto 24px auto; display: inline-block; }
    .otp-code { font-family: 'Courier New', Courier, monospace; font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #1e3a8a; margin: 0; }
    .notice { font-size: 12px; color: #64748b; margin-top: 16px; line-height: 1.5; }
    .footer { background: #f8fafc; padding: 20px 24px; text-align: center; font-size: 11px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>ISUFST CAMPUS GATE SECURITY</h1>
      <p>Plakado Automatic License Plate Recognition System</p>
    </div>
    <div class="content">
      <p class="instructions">
        You requested a verification code to access your <strong>ISUFST Campus Vehicle Pass</strong> account. Use the one-time code below to verify your login:
      </p>
      <div class="otp-box">
        <div class="otp-code">$code</div>
      </div>
      <p class="notice">
        • This code will expire in <strong>60 seconds</strong>.<br>
        • Do not share this code with anyone. Campus security officers will never ask for your code.
      </p>
    </div>
    <div class="footer">
      Iloilo State University of Fisheries Science and Technology (ISUFST)<br>
      Management Information System • Automated Security Gate Division
    </div>
  </div>
</body>
</html>
''';

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': _fromAddress,
          'to': [cleanRecipient],
          'subject': '[$code] Your ISUFST Campus Pass Verification Code',
          'html': htmlBody,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Resend Email dispatched to $cleanRecipient: ${data['id']}');
        return EmailDispatchResult(
          isSuccess: true,
          messageId: data['id']?.toString(),
        );
      } else {
        final errorBody = response.body;
        debugPrint('Resend API notice (${response.statusCode}): $errorBody');
        return EmailDispatchResult(
          isSuccess: false,
          errorMessage: 'Email dispatch response: $errorBody',
        );
      }
    } catch (e) {
      debugPrint('Email service error: $e');
      return EmailDispatchResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }
}
