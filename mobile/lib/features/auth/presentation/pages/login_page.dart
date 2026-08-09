import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();

  final _passwordController = TextEditingController();

  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isShowingLoadingDialog = false;

  @override
  void dispose() {
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    _setInputFocusEnabled(false);

    await context.read<AuthCubit>().login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.loading) {
          _showLoginLoadingDialog();
          return;
        }

        _closeLoginLoadingDialog();

        if (state.status == AuthStatus.failure) {
          _showUnauthorizedDialog();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.brandBlue,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 46, 26, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/brand/xionico_splash.png',
                        width: 160,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Gestión de Pedidos',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontSize: 22,
                              letterSpacing: 0,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 42),
                      TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocusNode,
                        cursorColor: AppColors.white,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Usuario',
                          prefixIcon: Icons.person_outline,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresá el usuario.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _obscurePassword,
                        cursorColor: AppColors.white,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration(
                          hintText: 'Contraseña',
                          prefixIcon: Icons.key_outlined,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresá la contraseña.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 36),
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final isLoading = state.status == AuthStatus.loading;

                          return SizedBox(
                            height: 58,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.brandBlue,
                                disabledBackgroundColor: AppColors.whiteMuted,
                                disabledForegroundColor: AppColors.brandBlue,
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onPressed: isLoading ? null : _submit,
                              child: const Text('Ingresar'),
                            ),
                          );
                        },
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

  Future<void> _showLoginLoadingDialog() async {
    if (_isShowingLoadingDialog || !mounted) {
      return;
    }

    _isShowingLoadingDialog = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      requestFocus: false,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: const SizedBox(
            height: 118,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      'Validando usuario y contraseña...',
                      style: TextStyle(
                        color: Color(0xFF202633),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _closeLoginLoadingDialog() {
    if (!_isShowingLoadingDialog || !mounted) {
      return;
    }

    _isShowingLoadingDialog = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _showUnauthorizedDialog() async {
    if (!mounted) {
      return;
    }

    FocusScope.of(context).unfocus();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      requestFocus: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 223, 224, 226),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color.fromARGB(255, 104, 102, 102),
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Acceso no autorizado para la combinación '
                'de Usuario y Clave.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 24, 18),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cerrar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    _setInputFocusEnabled(true);

    if (mounted) {
      _usernameFocusNode.requestFocus();
    }
  }

  void _setInputFocusEnabled(bool enabled) {
    _usernameFocusNode.canRequestFocus = enabled;
    _passwordFocusNode.canRequestFocus = enabled;
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(34));
    const borderSide = BorderSide(color: AppColors.white, width: 1.4);

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.whiteMuted, fontSize: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 22, right: 12),
        child: Icon(prefixIcon, color: AppColors.white, size: 26),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 64, minHeight: 58),
      suffixIcon: suffixIcon,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.w500,
      ),
      border: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: AppColors.white, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: AppColors.error, width: 1.4),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}
