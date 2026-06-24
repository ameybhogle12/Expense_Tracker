import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_screen.dart';
import 'charts_screen.dart';
import 'subscriptions_screen.dart';
import 'goals_screen.dart';
import 'splits_screen.dart';
import '../widgets/add_expense_form.dart';
import '../widgets/spotlight_tour_overlay.dart';
import '../widgets/onboarding_balance_sheet.dart';
import '../providers/tour_provider.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey _navBarKey = GlobalKey();
  final GlobalKey _addBtnKey = GlobalKey();

  List<Widget> get _screens => const [
    HomeScreen(),
    ChartsScreen(),
    SubscriptionsScreen(),
    GoalsScreen(),
    SplitsScreen(),
  ];

  TourProvider? _tourProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        _tourProvider = context.read<TourProvider>();
        _tourProvider?.registerKey('nav_bar', _navBarKey);
        _tourProvider?.registerKey('add_btn', _addBtnKey);
        _tourProvider?.addListener(_handleTourProgress);

        // First launch: ask for starting wallet balances before anything else,
        // so balances don't begin in the negative.
        final settingsBox = Hive.box('settings_v1');
        final onboarded = settingsBox.get('onboardingCompleted', defaultValue: false);
        if (!onboarded && mounted) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            isDismissible: false,
            enableDrag: false,
            builder: (ctx) => const OnboardingBalanceSheet(),
          );
          await settingsBox.put('onboardingCompleted', true);
        }

        // Auto-trigger the guided tour if it hasn't been completed yet.
        if (mounted && !_tourProvider!.isTourCompleted) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              _tourProvider?.startTour();
            }
          });
        }
      } catch (e) {
        debugPrint("Onboarding/Tour init error: $e");
      }
    });
  }

  @override
  void dispose() {
    _tourProvider?.removeListener(_handleTourProgress);
    super.dispose();
  }

  void _handleTourProgress() {
    if (!mounted || _tourProvider == null) return;
    if (_tourProvider!.isTourActive) {
      final currentStepIdx = _tourProvider!.currentStep;
      final step = _tourProvider!.steps[currentStepIdx];
      
      // Auto-switch tabs based on the tour step
      if (step.keyId != 'nav_bar') {
        // Switch back to Home (index 0) for home-specific steps
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      }
    }
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const AddExpenseForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.04, 0.0),
                end: Offset.zero,
              ).animate(animation);
              final scaleAnimation = Tween<double>(
                begin: 0.98,
                end: 1.0,
              ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _screens[_currentIndex],
            ),
          ),
          floatingActionButton: _currentIndex >= 2
              ? null
              : FloatingActionButton(
                  key: _addBtnKey,
                  onPressed: _openAddExpenseOverlay,
                  child: const Icon(Icons.add),
                ),
          bottomNavigationBar: NavigationBar(
            key: _navBarKey,
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: AppLocalizations.of(context)!.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.pie_chart_outline),
                selectedIcon: const Icon(Icons.pie_chart),
                label: AppLocalizations.of(context)!.navCharts,
              ),
              NavigationDestination(
                icon: const Icon(Icons.event_repeat_outlined),
                selectedIcon: const Icon(Icons.event_repeat),
                label: AppLocalizations.of(context)!.navSubs,
              ),
              NavigationDestination(
                icon: const Icon(Icons.flag_outlined),
                selectedIcon: const Icon(Icons.flag),
                label: AppLocalizations.of(context)!.navGoals,
              ),
              NavigationDestination(
                icon: const Icon(Icons.group_outlined),
                selectedIcon: const Icon(Icons.group),
                label: AppLocalizations.of(context)!.navSplit,
              ),
            ],
          ),
        ),
        // Spotlight onboarding tour overlay on top
        const SpotlightTourOverlay(),
      ],
    );
  }
}
