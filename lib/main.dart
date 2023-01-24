import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/all_buildings/all_buildings.dart';
import 'package:hi_society_admin/views/users/users.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'views/sign_in.dart';

//region Main
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) print("---- HI SOCIETY | ADMIN DASHBOARD ----");
  final pref = await SharedPreferences.getInstance();
  final String? accessTokenFromSharedPreferences = pref.getString("accessToken");
  if (kDebugMode) print("Access Token from Android Local Shared Preference Status: $accessTokenFromSharedPreferences");
  runApp(MyApp(accessToken: accessTokenFromSharedPreferences ?? ""));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.accessToken}) : super(key: key);
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Hi Society Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xfff7f7f7),
            brightness: Brightness.light,
            appBarTheme: AppBarTheme(backgroundColor: Colors.blue.shade50, centerTitle: true)),
        home: accessToken.isEmpty ? const SignIn() : const Users());
  }
}
//endregion
