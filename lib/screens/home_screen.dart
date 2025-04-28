import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twitch_clone/bloc/signup/signup_cubit.dart';
import 'package:twitch_clone/main.dart';
import 'package:twitch_clone/screens/feed_screen.dart';
import 'package:twitch_clone/screens/golive_screen.dart';
import 'package:twitch_clone/utils/colors.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = "/home";
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _page = 0;
  List<Widget> pages = [
    const FeedScreen(),
    const GoLiveScreen(),
    const Center(
      child: Text('Browser'),
    ),
  ];

  onPageChange(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SignupCubit>().state;
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: buttonColor,
        unselectedItemColor: primaryColor,
        backgroundColor: backgroundColor,
        unselectedFontSize: 12,
        onTap: onPageChange,
        currentIndex: _page,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.favorite,
            ),
            label: 'Following',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_rounded,
            ),
            label: 'Go Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.copy,
            ),
            label: 'Browse',
          ),
        ],
      ),
      body: pages[_page],
    );
  }
}
