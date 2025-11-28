import 'package:flutter/material.dart';
import 'package:rattil/utils/app_colors.dart';
import 'package:rattil/widgets/custom_text_field.dart';

import 'package:rattil/widgets/gradient_button.dart';
import 'package:rattil/screens/auth/sign_up.dart';
import 'package:rattil/screens/home_screen.dart';

class SignInScreen extends StatefulWidget {
	const SignInScreen({Key? key}) : super(key: key);

	@override
	State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
	final _formKey = GlobalKey<FormState>();
	final _emailController = TextEditingController();
	final _passwordController = TextEditingController();
	bool _isPasswordVisible = false;
	bool _isLoading = false;

	@override
	void dispose() {
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	String? _validateEmail(String? value) {
		if (value == null || value.isEmpty) {
			return 'Email is required';
		}
		// Use a simple regex for email validation
		final simpleEmailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
		if (!simpleEmailRegex.hasMatch(value)) {
			return 'Please enter a valid email';
		}
		return null;
	}

	String? _validatePassword(String? value) {
		if (value == null || value.isEmpty) {
			return 'Password is required';
		}
		if (value.length < 6) {
			return 'Password must be at least 6 characters';
		}
		return null;
	}

	Future<void> _handleSignIn() async {
		if (_formKey.currentState!.validate()) {
			setState(() => _isLoading = true);
			await Future.delayed(const Duration(seconds: 2));
			if (mounted) {
				Navigator.pushReplacement(
					context,
					MaterialPageRoute(builder: (context) => HomeScreen()),
				);
			}
			setState(() => _isLoading = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final textColor = isDark ? Colors.white : Color(0xFF111827);
		final subtitleColor = isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563);
		final inputBg = isDark ? Color(0xFF374151) : Color(0xFFF3F4F6);

		return Scaffold(
			backgroundColor: AppColors.background,
			body: SafeArea(
				child: GestureDetector(
					onTap: () => FocusScope.of(context).unfocus(),
					child: SingleChildScrollView(
						child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: 24),
							child: Form(
								key: _formKey,
								child: IntrinsicHeight(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.center,
										children: [
											const SizedBox(height: 80),
											// Logo
											Container(
												width: 80,
												height: 80,
												margin: const EdgeInsets.only(bottom: 16),
												decoration: BoxDecoration(
													shape: BoxShape.circle,
													gradient: LinearGradient(
														colors: [AppColors.teal500, AppColors.teal700],
														begin: Alignment.topLeft,
														end: Alignment.bottomRight,
													),
													boxShadow: [
														BoxShadow(
															color: AppColors.teal500.withOpacity(0.3),
															blurRadius: 12,
															offset: const Offset(0, 4),
														),
													],
												),
												child: Center(
													child: Text('📖', style: TextStyle(fontSize: 40)),
												),
											),
											// Welcome text
											Text(
												'Welcome to Rattil',
												style: TextStyle(
													fontSize: 30,
													fontWeight: FontWeight.bold,
													color: textColor,
												),
											),
											const SizedBox(height: 8),
											Text(
												'Sign in to continue learning',
												style: TextStyle(
													fontSize: 16,
													color: subtitleColor,
												),
											),
											const SizedBox(height: 48),
											// Email field
											CustomTextField(
												placeholder: 'Email Address',
												controller: _emailController,
												keyboardType: TextInputType.emailAddress,
												validator: _validateEmail,
												prefixIcon: Icon(Icons.email, color: AppColors.teal500),
											),
											const SizedBox(height: 16),
											// Password field
											CustomTextField(
												placeholder: 'Password',
												controller: _passwordController,
												isPassword: true,
												validator: _validatePassword,
												prefixIcon: Icon(Icons.lock, color: AppColors.teal500),
												isPasswordVisible: _isPasswordVisible,
												onTogglePassword: () {
													setState(() {
														_isPasswordVisible = !_isPasswordVisible;
													});
												},
											),
											const SizedBox(height: 8),
											// Forgot password link (optional)
											Align(
												alignment: Alignment.centerRight,
												child: TextButton(
													onPressed: () {},
													child: Text(
														'Forgot Password?',
														style: TextStyle(
															color: AppColors.teal700,
															fontSize: 14,
														),
													),
												),
											),
											const SizedBox(height: 24),
											// Sign In button
											GradientButton(
												text: 'Sign In',
												isLoading: _isLoading,
												onPressed: _isLoading ? () {} : _handleSignIn,
											),
											const SizedBox(height: 24),
											// Sign Up link
																				Center(
																					child: TextButton(
																						onPressed: () {
																							Navigator.push(
																								context,
																								MaterialPageRoute(builder: (context) => SignUpScreen()),
																							);
																						},
																						child: RichText(
																							text: TextSpan(
																								text: "Don't have an account? ",
																								style: TextStyle(color: Colors.grey[600]),
																								children: [
																									TextSpan(
																										text: 'Sign Up',
																										style: TextStyle(
																											color: AppColors.teal700,
																											fontWeight: FontWeight.bold,
																										),
																									),
																								],
																							),
																						),
																					),
																				),
										],
									),
								),
							),
						),
					),
				),
			),
		);
	}
}
