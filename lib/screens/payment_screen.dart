import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/providers/payment_provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/providers/drawer_provider.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/widgets/app_snackbar.dart';
import 'package:rattil/screens/payment_success_screen.dart';
import 'package:rattil/widgets/drawer_menu.dart';
import 'package:rattil/screens/payment_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Package selectedPackage;
  const PaymentScreen({Key? key, required this.selectedPackage}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final FocusNode _cardNumberFocus = FocusNode();

  String? cardNumberError;
  String? expiryDateError;
  String? cvvError;
  String? cardholderNameError;

  final String userName = 'John Doe';
  final String userEmail = 'john.doe@email.com';
  final String? userAvatarUrl = null;

  void openDrawer(BuildContext context) {
    Provider.of<DrawerProvider>(context, listen: false).openDrawer();
  }
  void closeDrawer(BuildContext context) {
    Provider.of<DrawerProvider>(context, listen: false).closeDrawer();
  }
  void toggleDarkMode(BuildContext context) {
    Provider.of<ThemeProvider>(context, listen: false).toggleDarkMode();
  }
  void handleNavigation(BuildContext context, String route) {
    closeDrawer(context);
  }
  void handleLogout(BuildContext context) {
    closeDrawer(context);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(_cardNumberFocus);
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    _cardNumberFocus.dispose();
    super.dispose();
  }

  String formatCardNumber(String value) {
    String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length > 16) cleaned = cleaned.substring(0, 16);
    List<String> parts = [];
    for (int i = 0; i < cleaned.length; i += 4) {
      int end = (i + 4 < cleaned.length) ? i + 4 : cleaned.length;
      parts.add(cleaned.substring(i, end));
    }
    return parts.join(' ');
  }

  bool isValidCardNumber(String cardNumber) {
    String cleaned = cardNumber.replaceAll(' ', '');
    return cleaned.length == 16 && int.tryParse(cleaned) != null;
  }

  String formatExpiryDate(String value) {
    String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length > 4) cleaned = cleaned.substring(0, 4);
    if (cleaned.length >= 2) {
      return '${cleaned.substring(0, 2)}/${cleaned.substring(2)}';
    }
    return cleaned;
  }

  bool isValidExpiryDate(String expiry) {
    if (expiry.length != 5) return false;
    List<String> parts = expiry.split('/');
    if (parts.length != 2) return false;
    int? month = int.tryParse(parts[0]);
    int? year = int.tryParse(parts[1]);
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    int currentYear = DateTime.now().year % 100;
    int currentMonth = DateTime.now().month;
    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;
    return true;
  }

  String formatCVV(String value) {
    String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length > 3) cleaned = cleaned.substring(0, 3);
    return cleaned;
  }

  bool isValidCVV(String cvv) {
    return cvv.length == 3 && int.tryParse(cvv) != null;
  }

  bool isValidCardholderName(String name) {
    if (name.trim().length < 3) return false;
    return RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  bool get isFormValid {
    return isValidCardNumber(_cardNumberController.text) &&
        isValidExpiryDate(_expiryDateController.text) &&
        isValidCVV(_cvvController.text) &&
        isValidCardholderName(_cardholderNameController.text);
  }

  Future<void> processPayment(BuildContext context) async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    provider.setProcessing(true);
    
    try {
      // Simulate API call - replace with actual payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate random payment failure for testing (remove in production)
      // final random = DateTime.now().millisecond % 10;
      // if (random < 2) {
      //   throw Exception('Payment declined by bank');
      // }
      
      provider.setProcessing(false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            transactionId: 'TXN123456',
            package: widget.selectedPackage,
          ),
        ),
      );
    } catch (e) {
      provider.setProcessing(false);
      
      // Show appropriate error message
      if (e.toString().contains('declined') || e.toString().contains('insufficient')) {
        AppSnackbar.showError(
          context,
          title: 'Payment Declined',
          message: 'Your payment was declined. Please check your card details or try a different card.',
        );
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        AppSnackbar.showNetworkError(context, onRetry: () => processPayment(context));
      } else {
        AppSnackbar.showError(
          context,
          title: 'Payment Failed',
          message: 'We couldn\'t process your payment. Please try again later.',
        );
      }
    }
  }

  void showPaymentConfirmation(BuildContext context) {
    FocusScope.of(context).unfocus();
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationScreen(
          userName: userName,
          userEmail: userEmail,
          userAvatarUrl: userAvatarUrl,
          cardNumber: _cardNumberController.text,
          cardholderName: _cardholderNameController.text,
          package: widget.selectedPackage,
          onConfirm: () {
            Navigator.pop(context, true); // Return true if confirmed
          },
          onCancel: () {
            Navigator.pop(context, false); // Return false if cancelled
          },
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        processPayment(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentProvider>(
      create: (_) => PaymentProvider(),
      child: Consumer3<PaymentProvider, ThemeProvider, DrawerProvider>(
        builder: (context, provider, themeProvider, drawerProvider, _) {
          final isDark = themeProvider.isDarkMode;
          final bgColor = isDark ? ThemeColors.darkBg : ThemeColors.lightBg;
          final cardColor = isDark ? ThemeColors.darkCard : ThemeColors.lightCard;
          final cardBg = isDark ? ThemeColors.darkCard : ThemeColors.lightCard;
          final textColor = isDark ? Colors.white : Color(0xFF111827);
          final subtitleColor = isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280);
          final inputBg = isDark ? Color(0xFF374151) : Color(0xFFF3F4F6);
          final inputBorder = isDark ? Color(0xFF4B5563) : Color(0xFFD1D5DB);
          final tealPrimary = Color(0xFF14b8a6);
          final tealDark = Color(0xFF0d9488);

          return Stack(
            children: [
              Scaffold(
                backgroundColor: bgColor,
                appBar: AppBar(
                  backgroundColor: cardColor,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  titleSpacing: 0,
                  leading: IconButton(
                    icon: Icon(Icons.chevron_left, color: textColor, size: 40),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text('Payment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                ),
                body: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Payment Icon Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [tealPrimary, tealDark]),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: tealPrimary.withOpacity(0.3), blurRadius: 24, offset: Offset(0, 8))],
                                ),
                                child: Center(
                                  child: Icon(Icons.credit_card, color: Colors.white, size: 40),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('Enter Your Card Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 8),
                              Text('Your payment information is secure', style: TextStyle(fontSize: 16, color: subtitleColor)),
                            ],
                          ),
                        ),
                        // Package Summary Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: tealPrimary, width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(widget.selectedPackage.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                                        const SizedBox(height: 4),
                                        Text('1 Month Subscription', style: TextStyle(fontSize: 14, color: subtitleColor)),
                                      ],
                                    ),
                                    Text('\$${widget.selectedPackage.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: tealDark)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(color: isDark ? Color(0xFF374151) : Color(0xFFD1D5DB)),
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.shield, color: tealDark, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Protected by secure payment gateway', style: TextStyle(fontSize: 12, color: subtitleColor)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Payment Form Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Card Number
                                  Text('Card Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                  const SizedBox(height: 8),
                                  Stack(
                                    children: [
                                      TextFormField(
                                        controller: _cardNumberController,
                                        focusNode: _cardNumberFocus,
                                        keyboardType: TextInputType.number,
                                        maxLength: 19,
                                        style: TextStyle(color: textColor),
                                        decoration: InputDecoration(
                                          hintText: '1234 5678 9012 3456',
                                          hintStyle: TextStyle(color: isDark ? Colors.white70 : Color(0xFF6B7280)),
                                          filled: true,
                                          fillColor: inputBg,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: inputBorder, width: 2),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: tealPrimary, width: 2),
                                          ),
                                          counterText: '',
                                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          errorText: cardNumberError,
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(19),
                                          TextInputFormatter.withFunction((oldValue, newValue) {
                                            final formatted = formatCardNumber(newValue.text);
                                            return TextEditingValue(
                                              text: formatted,
                                              selection: TextSelection.collapsed(offset: formatted.length),
                                            );
                                          }),
                                        ],
                                        validator: (value) {
                                          if (!isValidCardNumber(value ?? '')) {
                                            return 'Please enter a valid 16-digit card number';
                                          }
                                          return null;
                                        },
                                      ),
                                      Positioned(
                                        right: 16,
                                        top: 0,
                                        bottom: 0,
                                        child: Icon(Icons.credit_card, color: subtitleColor, size: 20),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Expiry Date & CVV
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Expiry Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _expiryDateController,
                                              keyboardType: TextInputType.number,
                                              maxLength: 5,
                                              style: TextStyle(color: textColor),
                                              decoration: InputDecoration(
                                                hintText: 'MM/YY',
                                                hintStyle: TextStyle(color: isDark ? Colors.white70 : Color(0xFF6B7280)),
                                                filled: true,
                                                fillColor: inputBg,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: inputBorder, width: 2),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: tealPrimary, width: 2),
                                                ),
                                                counterText: '',
                                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                                errorText: expiryDateError,
                                              ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly,
                                                LengthLimitingTextInputFormatter(5),
                                                TextInputFormatter.withFunction((oldValue, newValue) {
                                                  final formatted = formatExpiryDate(newValue.text);
                                                  return TextEditingValue(
                                                    text: formatted,
                                                    selection: TextSelection.collapsed(offset: formatted.length),
                                                  );
                                                }),
                                              ],
                                              validator: (value) {
                                                if (!isValidExpiryDate(value ?? '')) {
                                                  return 'Please enter a valid expiry date (MM/YY)';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('CVV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                            const SizedBox(height: 8),
                                            Stack(
                                              children: [
                                                TextFormField(
                                                  controller: _cvvController,
                                                  keyboardType: TextInputType.number,
                                                  maxLength: 3,
                                                  obscureText: true,
                                                  style: TextStyle(color: textColor),
                                                  decoration: InputDecoration(
                                                    hintText: '123',
                                                    hintStyle: TextStyle(color: isDark ? Colors.white70 : Color(0xFF6B7280)),
                                                    filled: true,
                                                    fillColor: inputBg,
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide(color: inputBorder, width: 2),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide(color: tealPrimary, width: 2),
                                                    ),
                                                    counterText: '',
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                                    errorText: cvvError,
                                                  ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                    LengthLimitingTextInputFormatter(3),
                                                    TextInputFormatter.withFunction((oldValue, newValue) {
                                                      final formatted = formatCVV(newValue.text);
                                                      return TextEditingValue(
                                                        text: formatted,
                                                        selection: TextSelection.collapsed(offset: formatted.length),
                                                      );
                                                    }),
                                                  ],
                                                  validator: (value) {
                                                    if (!isValidCVV(value ?? '')) {
                                                      return 'Please enter a valid 3-digit CVV';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                Positioned(
                                                  right: 16,
                                                  top: 0,
                                                  bottom: 0,
                                                  child: Icon(Icons.lock, color: subtitleColor, size: 16),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Cardholder Name
                                  Text('Cardholder Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _cardholderNameController,
                                    keyboardType: TextInputType.name,
                                    textCapitalization: TextCapitalization.characters,
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      hintText: 'JOHN DOE',
                                      hintStyle: TextStyle(color: isDark ? Colors.white70 : Color(0xFF6B7280)),
                                      filled: true,
                                      fillColor: inputBg,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: inputBorder, width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: tealPrimary, width: 2),
                                      ),
                                      counterText: '',
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      errorText: cardholderNameError,
                                    ),
                                    validator: (value) {
                                      if (!isValidCardholderName(value ?? '')) {
                                        return 'Please enter the name as it appears on the card';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  // Payment Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.ease,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: isFormValid && !provider.isProcessing ? [tealPrimary, tealDark] : [Colors.grey.shade400, Colors.grey.shade500]),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.10),
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Opacity(
                                        opacity: isFormValid && !provider.isProcessing ? 1.0 : 0.5,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: isFormValid && !provider.isProcessing ? () => showPaymentConfirmation(context) : null,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                if (provider.isProcessing)
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                if (provider.isProcessing) const SizedBox(width: 8),
                                                Icon(Icons.lock, color: Colors.white, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  provider.isProcessing
                                                      ? 'Processing Payment...'
                                                      : 'Confirm Payment - \$${widget.selectedPackage.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Security Badge
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield, color: tealDark, size: 16),
                              const SizedBox(width: 8),
                              Text('🔒 Secure Payment Gateway - Your data is encrypted', style: TextStyle(fontSize: 12, color: subtitleColor)),
                            ],
                          ),
                        ),
                        // Information Cards
                        Padding(
                          padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                          child: Column(
                            children: [
                              InfoCard(
                                icon: '💳',
                                title: 'Accepted Cards',
                                description: 'We accept Visa, Mastercard, and American Express',
                              ),
                              const SizedBox(height: 12),
                              InfoCard(
                                icon: '📞',
                                title: 'What Happens Next?',
                                description: 'Our team will contact you within 24 hours to schedule your first class',
                              ),
                              const SizedBox(height: 12),
                              InfoCard(
                                icon: '🔄',
                                title: 'Auto-Renewal',
                                description: 'Your subscription will auto-renew monthly. Cancel anytime.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              DrawerMenu(
                closeDrawer: () => closeDrawer(context),
                toggleDarkMode: () => toggleDarkMode(context),
                handleNavigation: (route) => handleNavigation(context, route),
                handleLogout: () => handleLogout(context),
                userName: userName,
                userEmail: userEmail,
                userAvatarUrl: userAvatarUrl,
              ),
            ],
          );
        },
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  const InfoCard({Key? key, required this.icon, required this.title, required this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final cardBg = isDarkMode ? Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Color(0xFF111827);
    final subtitleColor = isDarkMode ? Color(0xFF9CA3AF) : Color(0xFF6B7280);
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 12, color: subtitleColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
