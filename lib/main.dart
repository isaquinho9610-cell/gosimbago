import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);

  await Supabase.initialize(
    url: 'https://efqymyptwlbjldywkaxm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmcXlteXB0d2xiamxkeXdrYXhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3OTI0ODAsImV4cCI6MjA5MDM2ODQ4MH0.WgAGbfS29mbmvtONJrFJ-OIPfBVEd88n7GiTWrhaHHw',
  );

  runApp(const ProviderScope(child: GoSimbaGoApp()));
}
