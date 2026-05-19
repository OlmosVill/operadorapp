import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _employeeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(loginNotifierProvider.notifier).login(
          employeeNumber: _employeeController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginNotifierProvider);

    ref.listen<AsyncValue<void>>(loginNotifierProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.asphalt,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 56),

                // Brand mark — truck icon with amber glow ring
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.amber.withAlpha(20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.amber.withAlpha(80),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber.withAlpha(50),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.amber,
                      size: 42,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'OPERADORAPP',
                    style: TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.5,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Amber rule
                Center(
                  child: Container(
                    width: 48,
                    height: 2,
                    color: AppColors.amber,
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  'Iniciar sesión',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _employeeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: AppColors.textOnDark),
                  decoration: const InputDecoration(
                    labelText: 'Número de empleado',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu número de empleado';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onLogin(),
                  style: const TextStyle(color: AppColors.textOnDark),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscurePassword = !_obscurePassword,
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                FilledButton(
                  onPressed: loginState.isLoading ? null : _onLogin,
                  child: loginState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black54,
                          ),
                        )
                      : const Text(
                          'ACCEDER',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login/forgot-password'),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),

                const SizedBox(height: 48),

                Center(
                  child: Text(
                    'OperadorApp v1.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.asphaltBorder,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
