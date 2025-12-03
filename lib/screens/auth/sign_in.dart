import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rattil/utils/app_colors.dart';
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

	@override
	Widget build(BuildContext context) {
		return ChangeNotifierProvider<ThemeProvider>(
			create: (_) => ThemeProvider(),
			child: Consumer<ThemeProvider>(
				builder: (context, themeProvider, _) {
					final isDark = themeProvider.isDarkMode;
					final textColor = isDark ? Colors.white : Color(0xFF111827);
					final subtitleColor = isDark ? Color(0xFF9CA3AF) : Color(0xFF4B5563);

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
															isPasswordVisible: themeProvider.isDarkMode, // Example usage, you can add more state to ThemeProvider if needed
															onTogglePassword: () {
																themeProvider.toggleDarkMode(); // Example, you can add togglePasswordVisibility to ThemeProvider
															},
														),
														const SizedBox(height: 8),
														// Forgot password link
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
				},
			),
		);
	}
}
