import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tiara_fin/theme.dart';

class WavyBottomBar extends StatefulWidget {
  final int selectedIndex;
  final List<IconData> items;
  final Function(int) onItemSelected;

  const WavyBottomBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onItemSelected,
  });

  @override
  State<WavyBottomBar> createState() => _WavyBottomBarState();
}

class _WavyBottomBarState extends State<WavyBottomBar> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 40; 
    final itemWidth = width / widget.items.length;

    return Container(
      height: 80, 
      width: width,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Background Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.2), 
              boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.1),
                   blurRadius: 30,
                   offset: const Offset(0, 15),
                 ),
                 BoxShadow(
                   color: Colors.cyanAccent.withValues(alpha: 0.05),
                   blurRadius: 10,
                   spreadRadius: -5,
                 )
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.6),
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.2),
                ],
                stops: const [0.0, 0.15, 0.85, 1.0],
              ),
            ),
          ),

          // Moving Highlight Layer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            left: (itemWidth * widget.selectedIndex), 
            top: 0,
            width: itemWidth,
            height: 80,
            child: Center(
              child: Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.2, 0.5, 0.8],
                  ),
                ),
              ),
            ),
          ),
          
          // Selection Indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic, 
            left: itemWidth * widget.selectedIndex,
            top: 15, 
            width: itemWidth,
            height: 50,
            child: Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4]
                    )
                  ),
                ),
              ),
            ),
          ),

          // Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final icon = entry.value;
              final isActive = idx == widget.selectedIndex;

              return GestureDetector(
                onTap: () => widget.onItemSelected(idx),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                   width: itemWidth,
                   height: 80,
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       AnimatedScale(
                         duration: const Duration(milliseconds: 300),
                         scale: isActive ? 1.2 : 1.0,
                         curve: Curves.easeInOutBack,
                         child: Container(
                           padding: const EdgeInsets.all(12),
                           decoration: const BoxDecoration(
                             color: Colors.transparent, 
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                             icon,
                             color: isActive ? Colors.white : AppTheme.textSecondary.withValues(alpha: 0.7),
                             size: 24,
                           ),
                         ),
                       ),
                     ],
                   ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
