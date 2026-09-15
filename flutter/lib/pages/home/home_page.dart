import 'package:flutter/material.dart';

import 'package:fitzone/models/plan.dart';
import 'package:fitzone/pages/auth/login_page.dart';

import 'package:fitzone/widgets/home_header.dart';
import 'package:fitzone/widgets/home_intro.dart';
import 'package:fitzone/widgets/how_it_works.dart';
import 'package:fitzone/widgets/advantages_section.dart';
import 'package:fitzone/widgets/plans_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  void _irALogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  void _irAPlanes() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _seleccionarPlan(Plan plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Seleccionaste el plan ${plan.nombre}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              HomeHeader(
                onLoginPressed: _irALogin,
              ),

              HomeIntro(
                onStartPressed: _irAPlanes,
              ),

              const HowItWorks(),

              const AdvantagesSection(),

              PlansSection(
                onPlanSelected: _seleccionarPlan,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}