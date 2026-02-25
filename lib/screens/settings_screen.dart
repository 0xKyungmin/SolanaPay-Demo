import 'package:flutter/material.dart';

import '../models/brand.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Brand _selected;

  @override
  void initState() {
    super.initState();
    _selected = SettingsService.instance.selectedBrand;
  }

  Future<void> _save() async {
    await SettingsService.instance.setBrand(_selected);
    if (mounted) {
      Navigator.pop(context, true); // return true to trigger rebuild
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('브랜드 설정')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Preview
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            _selected.logoAsset,
                            width: 36,
                            height: 36,
                            errorBuilder: (c, e, s) => Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _selected.primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _selected.displayName[0],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'x',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/logos/solana.png',
                            width: 36,
                            height: 36,
                            errorBuilder: (c, e, s) => const Icon(Icons.currency_bitcoin, size: 36),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selected.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E2E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                '브랜드 선택',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 12),

              // Brand grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: Brand.values.map((brand) => _buildBrandCard(brand)).toList(),
                ),
              ),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('저장', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandCard(Brand brand) {
    final isSelected = _selected == brand;

    return GestureDetector(
      onTap: () => setState(() => _selected = brand),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? brand.primaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brand.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                brand.logoAsset,
                width: 40,
                height: 40,
                errorBuilder: (c, e, s) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: brand.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    brand.displayName[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              brand.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? brand.primaryColor : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
