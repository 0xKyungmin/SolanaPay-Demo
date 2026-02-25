import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../config.dart';

class SolanaService {
  static final SolanaService _instance = SolanaService._();
  static SolanaService get instance => _instance;

  late final SolanaClient _client;

  static final _tokenProgram = Ed25519HDPublicKey.fromBase58(tokenProgramId);
  static final _atProgram = Ed25519HDPublicKey.fromBase58(associatedTokenProgramId);

  SolanaService._() {
    _client = SolanaClient(
      rpcUrl: Uri.parse(rpcUrl),
      websocketUrl: Uri.parse(wsUrl),
    );
  }

  // Balance

  Future<double> getSolBalance(String address) async {
    final result = await _client.rpcClient.getBalance(address, commitment: Commitment.confirmed);
    return result.value / 1e9;
  }

  Future<double> getUsdcBalance(String ownerAddress) async {
    try {
      final mint = Ed25519HDPublicKey.fromBase58(usdcMintAddress);
      final owner = Ed25519HDPublicKey.fromBase58(ownerAddress);
      final ata = await _findAta(owner: owner, mint: mint);
      final result = await _client.rpcClient.getTokenAccountBalance(ata.toBase58(), commitment: Commitment.confirmed);
      return double.tryParse(result.value.uiAmountString ?? '0') ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  // SOL Transfer

  Future<String> transferSol({
    required Ed25519HDKeyPair sender,
    required String recipientAddress,
    required int lamports,
    required String referenceAddress,
  }) async {
    final recipient = Ed25519HDPublicKey.fromBase58(recipientAddress);
    final reference = Ed25519HDPublicKey.fromBase58(referenceAddress);

    final ix = SystemInstruction.transfer(
      fundingAccount: sender.publicKey,
      recipientAccount: recipient,
      lamports: lamports,
    );

    return _sendWithReference(ix, reference, [sender]);
  }

  // USDC Transfer

  Future<String> transferUsdc({
    required Ed25519HDKeyPair sender,
    required String recipientAddress,
    required int amount,
    required String referenceAddress,
  }) async {
    final mint = Ed25519HDPublicKey.fromBase58(usdcMintAddress);
    final recipientPubKey = Ed25519HDPublicKey.fromBase58(recipientAddress);
    final reference = Ed25519HDPublicKey.fromBase58(referenceAddress);

    final senderAta = await _findAta(owner: sender.publicKey, mint: mint);
    final recipientAta = await _findAta(owner: recipientPubKey, mint: mint);

    final instructions = <Instruction>[];

    // Create recipient ATA if needed
    if (!await _ataExists(recipientAta)) {
      instructions.add(AssociatedTokenAccountInstruction.createAccount(
        funder: sender.publicKey,
        address: recipientAta,
        owner: recipientPubKey,
        mint: mint,
      ));
    }

    final transferIx = TokenInstruction.transferChecked(
      amount: amount,
      decimals: usdcDecimals,
      source: senderAta,
      mint: mint,
      destination: recipientAta,
      owner: sender.publicKey,
    );

    // Add reference key
    instructions.add(Instruction(
      programId: transferIx.programId,
      accounts: [
        ...transferIx.accounts,
        AccountMeta.readonly(pubKey: reference, isSigner: false),
      ],
      data: transferIx.data,
    ));

    return _client.sendAndConfirmTransaction(
      message: Message(instructions: instructions),
      signers: [sender],
      commitment: Commitment.confirmed,
    );
  }

  // Payment Polling

  Future<String> pollForPayment(
    String referenceAddress, {
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 5),
    ValueNotifier<bool>? cancelled,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (cancelled?.value == true) throw Exception('Cancelled');
      await Future.delayed(interval);
      if (cancelled?.value == true) throw Exception('Cancelled');
      try {
        final sigs = await _client.rpcClient.getSignaturesForAddress(
          referenceAddress,
          commitment: Commitment.confirmed,
          limit: 1,
        );
        if (sigs.isNotEmpty) return sigs.first.signature;
      } catch (_) {}
    }
    throw TimeoutException('Payment not received within timeout');
  }

  // Helpers

  Future<String> _sendWithReference(
    Instruction ix,
    Ed25519HDPublicKey reference,
    List<Ed25519HDKeyPair> signers,
  ) {
    final ixWithRef = Instruction(
      programId: ix.programId,
      accounts: [
        ...ix.accounts,
        AccountMeta.readonly(pubKey: reference, isSigner: false),
      ],
      data: ix.data,
    );
    return _client.sendAndConfirmTransaction(
      message: Message(instructions: [ixWithRef]),
      signers: signers,
      commitment: Commitment.confirmed,
    );
  }

  Future<bool> _ataExists(Ed25519HDPublicKey ata) async {
    try {
      final info = await _client.rpcClient.getAccountInfo(ata.toBase58(), commitment: Commitment.confirmed);
      return info.value != null;
    } catch (_) {
      return false;
    }
  }

  Future<Ed25519HDPublicKey> _findAta({
    required Ed25519HDPublicKey owner,
    required Ed25519HDPublicKey mint,
  }) async {
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        owner.bytes,
        _tokenProgram.bytes,
        mint.bytes,
      ],
      programId: _atProgram,
    );
  }
}
