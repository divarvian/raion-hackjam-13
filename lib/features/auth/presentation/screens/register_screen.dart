import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/supabase_service.dart';

/// Register Screen — Daftar akun baru
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();

      // 1. Pre-flight check: Pastikan username belum dipakai
      final existingUser = await SupabaseService.client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Username ini sudah digunakan. Cari yang lain yuk!',
              ),
              backgroundColor: AppColors.reject,
            ),
          );
          setState(() => _isLoading = false);
        }
        return; // Hentikan proses jika username sudah ada
      }

      // 2. Lanjut daftar ke Supabase Auth
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: _passwordController.text,
        data: {
          'full_name': _fullNameController.text.trim(),
          'username': username,
        },
      );

      if (mounted) {
        // 3. Trik khusus Supabase: Jika identities kosong, berarti emailnya SUDAH terdaftar!
        if (response.user != null &&
            response.user!.identities != null &&
            response.user!.identities!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Oops, Email ini sudah terdaftar. Silakan login ya!',
              ),
              backgroundColor: AppColors.reject,
            ),
          );
          return;
        }

        if (response.session == null) {
          // Email confirmation is enabled
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registrasi sukses! Silakan cek email kamu untuk verifikasi.',
              ),
              backgroundColor: AppColors.support,
            ),
          );
          context.go(RouteNames.login);
        } else {
          // Auto login (email confirmation disabled)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Akun berhasil dibuat! Selamat datang di Kawal.Z 🎉',
              ),
              backgroundColor: AppColors.support,
            ),
          );
          context.go(RouteNames.home);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.getMessage(e)),
            backgroundColor: AppColors.reject,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.getMessage(e)),
            backgroundColor: AppColors.reject,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return; // User membatalkan login
      }
      
      final email = googleUser.email.toLowerCase().trim();
      if (!email.endsWith('.ac.id') && !email.endsWith('.edu')) {
        await googleSignIn.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal: Hanya menerima email mahasiswa (.ac.id / .edu)'),
              backgroundColor: AppColors.reject,
            ),
          );
        }
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Gagal mendapatkan akses token dari Google.');
      }

      await SupabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (mounted) context.go(RouteNames.home);
    } catch (e) {
      debugPrint('Error Register Google: $e');
      await GoogleSignIn()
          .signOut(); // Clear cached account so user can pick again
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.getMessage(e)),
            backgroundColor: AppColors.reject,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text('Buat Akun Baru', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Gabung jadi warga digital yang melek kebijakan!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Raka Pratama',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: AppSizes.p16),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'raka.aktif',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Username wajib diisi';
                    if (v.length < 3) return 'Minimal 3 karakter';
                    if (v.contains(' ')) return 'Tidak boleh ada spasi';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.p16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'mahasiswa@kampus.ac.id',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                    if (!v.contains('@')) return 'Format email tidak valid';

                    final lower = v.toLowerCase().trim();
                    if (!lower.endsWith('.ac.id') && !lower.endsWith('.edu')) {
                      return 'Hanya menerima email mahasiswa (.ac.id / .edu)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.p16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Minimal 6 karakter',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.p32),

                // Register Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isGoogleLoading) ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Daftar Sekarang'),
                  ),
                ),
                const SizedBox(height: AppSizes.p16),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('atau', style: AppTextStyles.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSizes.p16),

                // Google Sign-In Button
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: (_isLoading || _isGoogleLoading) ? null : _signInWithGoogle,
                    icon: _isGoogleLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: const Text('Daftar dengan Google'),
                  ),
                ),
                const SizedBox(height: AppSizes.p32),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sudah punya akun? ', style: AppTextStyles.bodyMedium),
                    GestureDetector(
                      onTap: () => context.go(RouteNames.login),
                      child: Text(
                        'Masuk di sini',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
