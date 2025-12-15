import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rattil/utils/app_colors.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/widgets/custom_text_field.dart';
import 'package:rattil/widgets/gradient_button.dart';
import 'package:rattil/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/auth_provider.dart' as my_auth;
import 'package:rattil/providers/theme_provider.dart';


class SignUpScreen extends StatefulWidget {
	const SignUpScreen({Key? key}) : super(key: key);

	@override
	State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
	final _formKey = GlobalKey<FormState>();
	final _nameController = TextEditingController();
	final _emailController = TextEditingController();
	final _passwordController = TextEditingController();
	final _confirmPasswordController = TextEditingController();
	
	bool _isPasswordVisible = false;
	bool _isConfirmPasswordVisible = false;
	bool _acceptedTerms = false;
	String? _selectedGender;

	@override
	void dispose() {
		_nameController.dispose();
		_emailController.dispose();
		_passwordController.dispose();
		_confirmPasswordController.dispose();
		super.dispose();
	}

	String? _validateName(String? value) {
		if (value == null || value.isEmpty) {
			return 'Name is required';
		}
		if (value.length < 3) {
			return 'Name must be at least 3 characters';
		}
		return null;
	}

	String? _validateEmail(String? value) {
		if (value == null || value.isEmpty) {
			return 'Email is required';
		}
		final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
		if (!emailRegex.hasMatch(value)) {
			return 'Please enter a valid email';
		}
		return null;
	}

	String? _validatePassword(String? value) {
		if (value == null || value.isEmpty) {
			return 'Password is required';
		}
		if (value.length < 8) {
			return 'Password must be at least 8 characters';
		}
		if (!value.contains(RegExp(r'[A-Za-z]')) || !value.contains(RegExp(r'[0-9]'))) {
			return 'Password must contain letters and numbers';
		}
		return null;
	}

	String? _validateConfirmPassword(String? value) {
		if (value == null || value.isEmpty) {
			return 'Please confirm your password';
		}
		if (value != _passwordController.text) {
			return 'Passwords do not match';
		}
		return null;
	}

	Future<void> _handleSignUp(BuildContext context) async {
		if (_formKey.currentState!.validate()) {
			// Check if terms are accepted
			if (!_acceptedTerms) {
				AppSnackbar.showWarning(
					context,
					title: 'Terms Required',
					message: 'Please accept the Terms & Conditions to create your account.',
				);
				return;
			}
			final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
			final error = await authProvider.signUp(
				name: _nameController.text,
				email: _emailController.text,
				password: _passwordController.text,
				gender: _selectedGender,
				context: context,
			);
			if (error == null && mounted) {
				// Show success message and go back to sign in page
				AppSnackbar.showSuccess(
					context,
					title: 'Account Created!',
					message: 'Your account has been created successfully. Please sign in.',
				);
				Navigator.pop(context);
			} else if (error != null && mounted) {
				AppSnackbar.showError(context, message: error);
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		final themeProvider = Provider.of<ThemeProvider>(context);
		final isDark = themeProvider.isDarkMode;
		final bgColor = isDark ? ThemeColors.darkBg : ThemeColors.lightBg;
		final textColor = isDark ? ThemeColors.darkText : ThemeColors.lightText;
		final subtitleColor = isDark ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;
		final isLoading = Provider.of<my_auth.AuthProvider>(context).isLoading;

		return Scaffold(
			backgroundColor: bgColor,
			resizeToAvoidBottomInset: true,
						body: SafeArea(
							child: GestureDetector(
								onTap: () => FocusScope.of(context).unfocus(),
								child: SingleChildScrollView(
									child: Padding(
										padding: const EdgeInsets.symmetric(horizontal: 24),
										child: Form(
											key: _formKey,
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.center,
												children: [
													const SizedBox(height: 70),
													// Logo
													SvgPicture.asset(
														'assets/icon/app_icon.svg',
														width: 60,
														height: 60,
														color: AppColors.teal500,
													),
													// Welcome text
													Text(
														'Create Account',
														style: TextStyle(
															fontSize: 26,
															fontWeight: FontWeight.bold,
															color: textColor,
														),
													),
													const SizedBox(height: 4),
													Center(
														child: Text(
															'Join us to start your Quran learning journey',
															style: TextStyle(
																fontSize: 14,
																color: subtitleColor,
															),
															textAlign: TextAlign.center,
														),
													),
													const SizedBox(height: 20),
													// Name field
													CustomTextField(
														placeholder: 'Full Name',
														controller: _nameController,
														validator: _validateName,
														prefixIcon: Icon(Icons.person, color: AppColors.teal500),
													),
													const SizedBox(height: 10),
													// Email field
													CustomTextField(
														placeholder: 'Email Address',
														controller: _emailController,
														keyboardType: TextInputType.emailAddress,
														validator: _validateEmail,
														prefixIcon: Icon(Icons.email, color: AppColors.teal500),
													),
													const SizedBox(height: 10),
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
													const SizedBox(height: 10),
													// Confirm Password field
													CustomTextField(
														placeholder: 'Confirm Password',
														controller: _confirmPasswordController,
														isPassword: true,
														validator: _validateConfirmPassword,
														prefixIcon: Icon(Icons.lock, color: AppColors.teal500),
														isPasswordVisible: _isConfirmPasswordVisible,
														onTogglePassword: () {
															setState(() {
																_isConfirmPasswordVisible = !_isConfirmPasswordVisible;
															});
														},
													),
													const SizedBox(height: 10),
													// Gender dropdown
													Container(
														height: 56,
														padding: const EdgeInsets.symmetric(horizontal: 16),
														decoration: BoxDecoration(
															color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
															borderRadius: BorderRadius.circular(12),
														),
														child: DropdownButtonHideUnderline(
															child: DropdownButton<String>(
																value: _selectedGender,
																hint: Row(
																	children: [
																		Icon(Icons.person_outline, color: AppColors.teal500),
																		const SizedBox(width: 12),
																		Text(
																			'Gender (Optional)',
																			style: TextStyle(
																				color: subtitleColor,
																				fontSize: 16,
																			),
																		),
																	],
																),
																icon: Icon(
																	Icons.keyboard_arrow_down_rounded,
																	color: subtitleColor,
																),
																isExpanded: true,
																dropdownColor: isDark ? const Color(0xFF374151) : Colors.white,
																borderRadius: BorderRadius.circular(12),
																style: TextStyle(
																	color: textColor,
																	fontSize: 16,
																),
																items: [
																	DropdownMenuItem(
																		value: 'Male',
																		child: Row(
																			children: [
																				Icon(Icons.male, color: AppColors.teal500, size: 20),
																				const SizedBox(width: 12),
																				Text('Male', style: TextStyle(color: textColor)),
																			],
																		),
																	),
																	DropdownMenuItem(
																		value: 'Female',
																		child: Row(
																			children: [
																				Icon(Icons.female, color: AppColors.teal500, size: 20),
																				const SizedBox(width: 12),
																				Text('Female', style: TextStyle(color: textColor)),
																			],
																		),
																	),
																],
																selectedItemBuilder: (BuildContext context) {
																	return ['Male', 'Female'].map<Widget>((String value) {
																		return Row(
																			children: [
																				Icon(Icons.person_outline, color: AppColors.teal500),
																				const SizedBox(width: 12),
																				Text(
																					value,
																					style: TextStyle(
																						color: textColor,
																						fontSize: 16,
																					),
																				),
																			],
																		);
																	}).toList();
																},
																onChanged: (value) {
																	setState(() {
																		_selectedGender = value;
																	});
																},
															),
														),
													),
													const SizedBox(height: 4),
													// Terms & Conditions checkbox
													Row(
														children: [
															Checkbox(
																value: _acceptedTerms,
																onChanged: (val) {
																	setState(() {
																		_acceptedTerms = val ?? false;
																	});
																},
																activeColor: AppColors.teal500,
															),
															Expanded(
																child: RichText(
																	text: TextSpan(
																		text: 'I agree to the ',
																		style: TextStyle(color: subtitleColor, fontSize: 14),
																		children: [
																			TextSpan(
																				text: 'Terms & Conditions',
																				style: TextStyle(
																					color: AppColors.teal700,
																					fontWeight: FontWeight.bold,
																				),
																			),
																			TextSpan(
																				text: ' and ',
																				style: TextStyle(color: subtitleColor, fontSize: 14),
																			),
																			TextSpan(
																				text: 'Privacy Policy',
																				style: TextStyle(
																					color: AppColors.teal700,
																					fontWeight: FontWeight.bold,
																				),
																				recognizer: TapGestureRecognizer()
																					..onTap = () {
																						// Navigator.push(
																						// 	context,
																						// 	// MaterialPageRoute(
																						// 	// 	// builder: (context) => const PrivacyPolicyScreen(),
																						// 	// ),
																						// );
																					},
																			),
																		],
																	),
																),
															),
														],
													),
													const SizedBox(height: 10),
													// Sign Up button
													GradientButton(
														text: 'Sign Up',
														isLoading: isLoading,
														onPressed: isLoading ? () {} : () => _handleSignUp(context),
													),
													const SizedBox(height: 3),
													// Sign In link
													Center(
														child: TextButton(
															onPressed: () {
																Navigator.pop(context);
															},
															child: RichText(
																text: TextSpan(
																	text: "Already have an account? ",
																	style: TextStyle(color: Colors.grey[600]),
																	children: [
																		TextSpan(
																			text: 'Sign In',
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
					);
	}
}
