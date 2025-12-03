import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rattil/utils/app_colors.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/auth_provider.dart' as my_auth;
import 'package:rattil/providers/theme_provider.dart';

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

	Future<void> _handleSignIn(BuildContext context) async {
		if (_formKey.currentState!.validate()) {
			final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
			final error = await authProvider.signIn(
				email: _emailController.text,
				password: _passwordController.text,
				context: context,
			);
			if (error == null && mounted) {
				Navigator.pushReplacement(
					context,
					MaterialPageRoute(builder: (context) => HomeScreen()),
				);
			} else if (error != null) {
				ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
			}
		}
	}

	void _showForgotPasswordDialog(BuildContext context) {
		final resetEmailController = TextEditingController();
		final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
		final isDark = themeProvider.isDarkMode;
		final bgColor = isDark ? ThemeColors.darkCard : ThemeColors.lightCard;
		final textColor = isDark ? ThemeColors.darkText : ThemeColors.lightText;
		final subtitleColor = isDark ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;

		showDialog(
			context: context,
			builder: (dialogContext) => AlertDialog(
				backgroundColor: bgColor,
				surfaceTintColor: Colors.transparent,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
				title: Text('Reset Password', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text(
							'Enter your email address and we\'ll send you a link to reset your password.',
							style: TextStyle(color: subtitleColor, fontSize: 14),
						),
						const SizedBox(height: 16),
						TextField(
							controller: resetEmailController,
							keyboardType: TextInputType.emailAddress,
							style: TextStyle(color: textColor),
							decoration: InputDecoration(
								hintText: 'Email Address',
								hintStyle: TextStyle(color: subtitleColor),
								filled: true,
								fillColor: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
								border: OutlineInputBorder(
									borderRadius: BorderRadius.circular(12),
									borderSide: BorderSide.none,
								),
								prefixIcon: Icon(Icons.email, color: AppColors.teal500),
							),
						),
					],
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(dialogContext),
						child: Text('Cancel', style: TextStyle(color: subtitleColor)),
					),
					TextButton(
						onPressed: () async {
							if (resetEmailController.text.trim().isEmpty) {
								ScaffoldMessenger.of(context).showSnackBar(
									SnackBar(content: Text('Please enter your email'), backgroundColor: Colors.red),
								);
								return;
							}
							Navigator.pop(dialogContext);
							
							final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
							final error = await authProvider.resetPassword(resetEmailController.text);
							
							if (error == null) {
								ScaffoldMessenger.of(context).showSnackBar(
									SnackBar(
										content: Text('Password reset link sent to your email!'),
										backgroundColor: ThemeColors.primaryTeal,
									),
								);
							} else {
								ScaffoldMessenger.of(context).showSnackBar(
									SnackBar(content: Text(error), backgroundColor: Colors.red),
								);
							}
						},
						child: Text('Send Link', style: TextStyle(color: ThemeColors.primaryTeal, fontWeight: FontWeight.bold)),
					),
				],
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		final themeProvider = Provider.of<ThemeProvider>(context);
		final isDark = themeProvider.isDarkMode;
		final bgColor = isDark ? ThemeColors.darkBg : ThemeColors.lightBg;
		final textColor = isDark ? ThemeColors.darkText : ThemeColors.lightText;
		final subtitleColor = isDark ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;

		return Scaffold(
			backgroundColor: bgColor,
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
														SvgPicture.asset(
															'assets/icon/app_icon.svg',
															width: 80,
															height: 80,
															color: AppColors.teal500,
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
														// Forgot password link
														Align(
															alignment: Alignment.centerRight,
															child: TextButton(
																onPressed: () => _showForgotPasswordDialog(context),
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
															isLoading: false, // You can add loading state to provider if needed
															onPressed: () => _handleSignIn(context),
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
									], // End of Column children
								), // End of Column
							), // End of IntrinsicHeight
						), // End of Form
					), // End of Padding
				), // End of SingleChildScrollView
			), // End of GestureDetector
		), // End of SafeArea
		); // End of Scaffold
	}
}