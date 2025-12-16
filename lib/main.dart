import 'package:emi_calculator/acf/screens/acf_screen.dart';
import 'package:emi_calculator/calculator/providers/theme_provider.dart';
import 'package:emi_calculator/calculator/screens/emi_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ProviderScope(child: EmiApp()));
}

class EmiApp extends ConsumerWidget {
  const EmiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider);

    return MaterialApp(
      title: 'CFI Calculator',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.themeData,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.watch(themeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'CFI Calculator' : 'ACF Calculator',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 20 : 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        actions: [
          // Show nav buttons in actions on desktop/tablet
          if (!isMobile) ...[
            _NavButton(
              label: 'EMI Option',
              isSelected: _currentIndex == 0,
              onTap: () => _onTabChanged(0),
            ),
            const SizedBox(width: 8),
            _NavButton(
              label: 'ACF Option',
              isSelected: _currentIndex == 1,
              onTap: () => _onTabChanged(1),
            ),
            const SizedBox(width: 24),
          ],
          // Version Number
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'v1.0.2',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // IconButton(
          //   onPressed: () => themeNotifier.toggleTheme(),
          //   icon: Icon(
          //     Theme.of(context).brightness == Brightness.dark
          //         ? Icons.light_mode
          //         : Icons.dark_mode,
          //     color: Theme.of(context).colorScheme.primary,
          //   ),
          // ),
          const SizedBox(width: 16),
        ],
        // Show nav buttons below header on mobile
        bottom: isMobile
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavButton(
                          label: 'EMI Option',
                          isSelected: _currentIndex == 0,
                          onTap: () => _onTabChanged(0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NavButton(
                          label: 'ACF Option',
                          isSelected: _currentIndex == 1,
                          onTap: () => _onTabChanged(1),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [EmiCalculatorScreen(), AcfScreen()],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final selectedBgColor = isDark ? Colors.white : Colors.black;
    final selectedTextColor = isDark ? Colors.black : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected ? selectedBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : (_isHovered ? textColor : Colors.transparent),
              width: 1.5,
            ),
            boxShadow: _isHovered && !widget.isSelected
                ? [
                    BoxShadow(
                      color: textColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.label,
              key: ValueKey<bool>(widget.isSelected),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isSelected ? selectedTextColor : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
