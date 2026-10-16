import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String email;
  final Future<bool> Function(String code) onVerify;
  final VoidCallback onResend;

  const OtpVerificationDialog({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> with WidgetsBindingObserver {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;
  String? _errorMessage;
  int _secondsRemaining = 60; // 60 seconds countdown
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();

    // Automatically check clipboard for 6-digit code on dialog open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAutoPasteClipboard();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User switched back from email/message app -> auto check clipboard
      _checkAndAutoPasteClipboard();
    }
  }

  /// Automatically reads clipboard and extracts a 6-digit verification code
  Future<bool> _checkAndAutoPasteClipboard({bool showToastOnEmpty = false}) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim() ?? '';
      if (text.isEmpty) {
        if (showToastOnEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clipboard is empty. Copy the 6-digit code first.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return false;
      }

      // Extracts standalone 6-digit code or sequence from email notification
      final match = RegExp(r'\b\d{6}\b').firstMatch(text);
      if (match != null) {
        final code = match.group(0)!;
        if (mounted && _codeController.text != code) {
          setState(() {
            _codeController.text = code;
            _errorMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Auto-pasted verification code: $code'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );
          _submit();
          return true;
        }
      } else if (showToastOnEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No 6-digit verification code found in clipboard.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Clipboard auto-read notice: $e');
    }
    return false;
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the code.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.onVerify(code);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage = 'Invalid or expired code. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: Color(0xFF2563EB),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Verify School Account',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a one-time verification code to\n'),
                    TextSpan(
                      text: widget.email,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A 6-digit verification code has been dispatched to ${widget.email}. Please check your inbox.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 6-digit PIN Input Grid (Separate dedicated boxes)
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Visual 6-box display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final text = _codeController.text;
                        final isFilled = index < text.length;
                        final isCurrent = index == text.length;
                        final digit = isFilled ? text[index] : '';

                        return Container(
                          width: 44,
                          height: 54,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? (isCurrent
                                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                                    : const Color(0xFF1E293B))
                                : (isCurrent
                                    ? const Color(0xFFDBEAFE)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF2563EB)
                                  : (isFilled
                                      ? const Color(0xFF3B82F6)
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                              width: isCurrent ? 2.0 : 1.2,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isFilled
                                ? Text(
                                    digit,
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  )
                                : Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ),

                    // Hidden transparent TextField to capture keyboard, backspaces & clipboard
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.0,
                        child: TextField(
                          controller: _codeController,
                          focusNode: _focusNode,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          enableSuggestions: false,
                          autocorrect: false,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (val) {
                            setState(() => _errorMessage = null);
                            final match = RegExp(r'\b\d{6}\b').firstMatch(val.trim());
                            if (match != null) {
                              final code = match.group(0)!;
                              if (_codeController.text != code) {
                                _codeController.text = code;
                              }
                              _submit();
                            } else if (val.trim().length == 6) {
                              _submit();
                            }
                          },
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Quick Auto-Paste Action Button
              Center(
                child: TextButton.icon(
                  onPressed: () => _checkAndAutoPasteClipboard(showToastOnEmpty: true),
                  icon: const Icon(Icons.paste_rounded, size: 16),
                  label: const Text(
                    'Auto-Paste Code from Clipboard',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: _secondsRemaining <= 15 ? Colors.redAccent : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Code expires in $_formattedTime',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _secondsRemaining <= 15 ? Colors.redAccent : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Verify Code & Access Pass',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
              const SizedBox(height: 12),

              // Resend Option
              Center(
                child: TextButton(
                  onPressed: _secondsRemaining == 0
                      ? () {
                          widget.onResend();
                          _startTimer();
                          setState(() => _errorMessage = null);
                        }
                      : null,
                  child: Text(
                    _secondsRemaining == 0
                        ? 'Resend Verification Code'
                        : 'Resend code in $_secondsRemaining s',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
