import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorHandler {
  /// Translates an exception into a user-friendly Indonesian message.
  static String getMessage(Object e) {
    if (e is PostgrestException) {
      if (e.message.contains('Failed host lookup') || e.message.contains('SocketException')) {
        return 'Tidak ada koneksi internet. Coba periksa jaringanmu.';
      }
      if (e.code == 'PGRST116') {
        return 'Data tidak ditemukan.';
      }
      
      final msg = e.message.toLowerCase();
      if (msg.contains('duplicate key') || msg.contains('unique constraint')) {
        if (msg.contains('username')) return 'Username sudah digunakan oleh orang lain.';
        if (msg.contains('email')) return 'Email ini sudah terdaftar.';
      }
      if (msg.contains('registrasi ditolak')) {
        return e.message; // Tampilkan pesan dari Trigger Backend langsung
      }

      return 'Gagal memuat data dari server. Silakan coba lagi.';
    } else if (e is SocketException || e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
      return 'Tidak ada koneksi internet. Pastikan kamu terhubung ke WiFi/Seluler.';
    } else if (e is AuthException) {
      if (e is AuthApiException) {
        switch (e.code) {
          case 'invalid_credentials':
            return 'Email atau password salah.';
          case 'email_not_confirmed':
            return 'Email belum diverifikasi. Cek kotak masuk/spam kamu.';
          case 'user_already_exists':
          case 'email_exists':
            return 'Email ini sudah terdaftar. Silakan login.';
          case 'over_email_send_rate_limit':
          case 'over_request_rate_limit':
            return 'Terlalu banyak permintaan. Tunggu beberapa saat.';
          case 'weak_password':
            return 'Password terlalu lemah atau pendek.';
        }
      }
      // Tampilkan error AuthException bawaan jika ada, selain itu tampilkan default
      if (e.message.isNotEmpty && !e.message.toLowerCase().contains('database error')) {
        return e.message;
      }
      return 'Otentikasi gagal. Silakan coba lagi.';
    }
    
    // Fallback for generic errors like TypeError, FormatException, etc.
    return 'Terjadi kesalahan sistem. Coba tarik ke bawah untuk me-refresh.';
  }
}
