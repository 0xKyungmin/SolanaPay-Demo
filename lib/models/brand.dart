import 'package:flutter/material.dart';

enum Brand {
  toss,
  kb,
  shinhan,
  hyundai,
  tmoney,
}

extension BrandInfo on Brand {
  String get displayName {
    switch (this) {
      case Brand.toss:
        return '토스';
      case Brand.kb:
        return '국민카드';
      case Brand.shinhan:
        return '신한카드';
      case Brand.hyundai:
        return '현대카드';
      case Brand.tmoney:
        return '티머니';
    }
  }

  String get logoAsset {
    switch (this) {
      case Brand.toss:
        return 'assets/logos/toss.png';
      case Brand.kb:
        return 'assets/logos/kb.png';
      case Brand.shinhan:
        return 'assets/logos/shinhan.png';
      case Brand.hyundai:
        return 'assets/logos/hyundai.png';
      case Brand.tmoney:
        return 'assets/logos/tmoney.png';
    }
  }

  Color get primaryColor {
    switch (this) {
      case Brand.toss:
        return const Color(0xFF0064FF);
      case Brand.kb:
        return const Color(0xFFFFBC00);
      case Brand.shinhan:
        return const Color(0xFF0046FF);
      case Brand.hyundai:
        return const Color(0xFF000000);
      case Brand.tmoney:
        return const Color(0xFF6B7280);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case Brand.toss:
        return const Color(0xFF0052CC);
      case Brand.kb:
        return const Color(0xFFE5A800);
      case Brand.shinhan:
        return const Color(0xFF0033CC);
      case Brand.hyundai:
        return const Color(0xFF333333);
      case Brand.tmoney:
        return const Color(0xFF4B5563);
    }
  }

  String get title => '$displayName x Solana Pay';
}
