import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitch_clone/bloc/firebase/firebase_methods.dart';
import 'package:twitch_clone/bloc/login/login_cubit.dart';
import 'package:twitch_clone/bloc/signup/signup_cubit.dart';
import 'package:twitch_clone/bloc/start_livestream/start_livestream_cubit.dart';
import 'package:twitch_clone/screens/home_screen.dart';
import 'package:twitch_clone/screens/login_screen.dart';
import 'package:twitch_clone/screens/onboarding_screen.dart';
import 'package:twitch_clone/screens/signup_screen.dart';
import 'package:twitch_clone/utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url:
        'https://pxeziaoguiuacmazloxl.supabase.co', // Replace with your Supabase project URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4ZXppYW9ndWl1YWNtYXpsb3hsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE3NjE2NjUsImV4cCI6MjA0NzMzNzY2NX0.CSJPkXGag8KI2V8RIgFC9hn0J-f0GWJW-4rlshLcJrM', // Replace with your Supabase anon key
  );
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<LoginCubit>(create: (_) => LoginCubit()),
        BlocProvider<SignupCubit>(create: (_) => SignupCubit()),
        BlocProvider<FirebaseMethodsCubit>(
            create: (_) => FirebaseMethodsCubit()),
        BlocProvider<StartLivestreamCubit>(
          create: (_) => StartLivestreamCubit(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Twitch Clone Tutorial',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme.of(context).copyWith(
          backgroundColor: backgroundColor,
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(
            color: primaryColor,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor:
                Colors.white, // Sets text color for ElevatedButtons
          ),
        ),
      ),
      routes: {
        OnboardingScreens.routeName: (context) => const OnboardingScreens(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        SignupScreen.routeName: (context) => const SignupScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
      },
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }

            if (snapshot.hasData) {
              return const HomeScreen();
            }

            return const OnboardingScreens();
          }

          return const OnboardingScreens();
        },
      ),
    );
  }
}
