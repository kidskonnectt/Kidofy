import 'package:flutter/material.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class KidAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onSearchTap;
  final VoidCallback? onPremiumTap;
  final bool isPremium;
  final int daysRemaining;

  const KidAppBar({
    super.key,
    required this.onProfileTap,
    required this.onSearchTap,
    this.onPremiumTap,
    this.isPremium = false,
    this.daysRemaining = 0,
  });

  @override
  State<KidAppBar> createState() => _KidAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _KidAppBarState extends State<KidAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.white, end: AppColors.primaryRed),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: AppColors.primaryRed, end: Colors.yellow),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.yellow, end: Colors.white),
        weight: 1,
      ),
    ]).animate(_colorController);
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Area
          Row(
            children: [
              Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Show Premium or Kidofy based on subscription status
              if (widget.isPremium)
                GestureDetector(
                  onTap: widget.onPremiumTap,
                  child: Text(
                    'Premium',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: widget.onPremiumTap,
                  child: Text(
                    'Kidofy',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              // Premium Navigation Arrow - only show if not premium
              if (!widget.isPremium) const SizedBox(width: 8),
              if (!widget.isPremium)
                GestureDetector(
                  onTap: widget.onPremiumTap,
                  child: AnimatedBuilder(
                    animation: _colorAnimation,
                    builder: (context, child) {
                      return Text(
                        '>',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _colorAnimation.value ?? Colors.white,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),

          Row(
            children: [
              IconButton(
                onPressed: widget.onSearchTap,
                icon: const Icon(
                  Icons.search_rounded,
                  size: 32,
                  color: AppColors.textDark,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
