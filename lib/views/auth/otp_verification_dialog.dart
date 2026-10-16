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
  int _codeExpiresInSeconds = 300; // 5 minutes expiration
  int _resendCooldownSeconds = 60; // 60 seconds resend cooldown
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
    _codeExpiresInSeconds = 300; // 5 minutes expiration
    _resendCooldownSeconds = 60; // 60 seconds resend cooldown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_codeExpiresInSeconds > 0) {
          _codeExpiresInSeconds--;
        }
        if (_resendCooldownSeconds > 0) {
          _resendCooldownSeconds--;
        }
        if (_codeExpiresInSeconds == 0 && _resendCooldownSeconds == 0) {
          timer.cancel();
        }
      });
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

  String get _formattedExpiryTime {
    final minutes = (_codeExpiresInSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_codeExpiresInSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the code.');
      return;
    }

    if (_codeExpiresInSeconds <= 0) {
      setState(() => _errorMessage = 'Verification code has expired. Please resend a new code.');
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Verify School Account',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'We sent a 6-digit verification code to',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),

              // Email Chip / Badge (no awkward word-splitting)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.email,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 6-digit PIN Input Grid (Responsive flexible boxes)
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

                        return Flexible(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 42, minWidth: 32),
                            height: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    )
                                  : Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                      ),
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
                const SizedBox(height: 8),
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
              const SizedBox(height: 10),

              // Quick Auto-Paste Action Button
              Center(
                child: TextButton.icon(
                  onPressed: () => _checkAndAutoPasteClipboard(showToastOnEmpty: true),
                  icon: const Icon(Icons.content_paste_go_rounded, size: 15),
                  label: const Text(
                    'Auto-Paste Code from Clipboard',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Expiry Countdown (5 minutes)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: _codeExpiresInSeconds <= 30
                        ? Colors.redAccent
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _codeExpiresInSeconds > 0
                        ? 'Code expires in $_formattedExpiryTime'
                        : 'Code has expired',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _codeExpiresInSeconds <= 30
                          ? Colors.redAccent
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
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
              const SizedBox(height: 8),

              // Resend Option (Available again in 60s)
              Center(
                child: TextButton(
                  onPressed: _resendCooldownSeconds == 0
                      ? () {
                          widget.onResend();
                          _startTimer();
                          setState(() => _errorMessage = null);
                        }
                      : null,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    _resendCooldownSeconds == 0
                        ? 'Didn\'t receive code? Resend Code'
                        : 'Resend code in ${_resendCooldownSeconds}s',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _resendCooldownSeconds == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: _resendCooldownSeconds == 0
                          ? const Color(0xFF2563EB)
                          : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    ),
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
