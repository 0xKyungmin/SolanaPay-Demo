import 'package:solana/solana.dart';

import 'models/brand.dart';
import 'services/settings_service.dart';

// Branding
String get appName => SettingsService.instance.selectedBrand.title;
String get merchantLabel => SettingsService.instance.selectedBrand.displayName;

// Solana Devnet
const rpcUrl = 'https://api.devnet.solana.com';
const wsUrl = 'wss://api.devnet.solana.com';
const usdcMintAddress = '4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU';
const usdcDecimals = 6;
const tokenProgramId = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
const associatedTokenProgramId = 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL';

// Wallet #1 – 홈 화면 + 데모 결제 From (잔액 보유)
const _walletKey = [
  70, 136, 36, 148, 8, 64, 47, 209, 49, 55, 252, 42, 216, 100, 163, 203,
  253, 9, 188, 28, 201, 71, 76, 147, 93, 190, 13, 93, 246, 206, 128, 160,
];

// Wallet #2 – QR 수신자 To (빈 지갑)
const _merchantKey = [
  187, 26, 242, 251, 41, 36, 212, 167, 183, 186, 66, 230, 75, 109, 239, 35,
  54, 164, 86, 186, 43, 218, 145, 94, 27, 114, 209, 198, 173, 183, 245, 104,
];

// 저장된 주소록 (시연용)
const savedAddresses = [
  SavedAddress(name: '내 지갑', address: ''), // 런타임에 채워짐
];

class SavedAddress {
  final String name;
  final String address;
  const SavedAddress({required this.name, required this.address});
}

// Explorer
String explorerUrl(String sig) =>
    'https://explorer.solana.com/tx/$sig?cluster=devnet';

// Wallets
Ed25519HDKeyPair? _cachedWallet;
Ed25519HDKeyPair? _cachedMerchant;

Future<Ed25519HDKeyPair> loadWallet() async =>
    _cachedWallet ??= await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: _walletKey);

Future<Ed25519HDKeyPair> loadMerchantWallet() async =>
    _cachedMerchant ??= await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: _merchantKey);

Future<Ed25519HDKeyPair> loadCustomerWallet() => loadWallet();
