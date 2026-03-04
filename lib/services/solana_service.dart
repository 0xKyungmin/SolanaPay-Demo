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

    final ixWithRef = Instruction(
      programId: ix.programId,
      accounts: [
        ...ix.accounts,
        AccountMeta.readonly(pubKey: reference, isSigner: false),
      ],
      data: ix.data,
    );

    return _sendAndConfirm(
      instructions: [ixWithRef],
      signers: [sender],
    );
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

    final transferIx = TokenInstruction.transferChecked(
      amount: amount,
      decimals: usdcDecimals,
      source: senderAta,
      mint: mint,
      destination: recipientAta,
      owner: sender.publicKey,
    );

    final ixWithRef = Instruction(
      programId: transferIx.programId,
      accounts: [
        ...transferIx.accounts,
        AccountMeta.readonly(pubKey: reference, isSigner: false),
      ],
      data: transferIx.data,
    );

    final instructions = <Instruction>[];

    // Create recipient ATA if it doesn't exist yet
    if (!await _ataExists(recipientAta)) {
      instructions.add(AssociatedTokenAccountInstruction.createAccount(
        funder: sender.publicKey,
        address: recipientAta,
        owner: recipientPubKey,
        mint: mint,
      ));
    }

    instructions.add(ixWithRef);

    return _sendAndConfirm(
      instructions: instructions,
      signers: [sender],
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

  // Core send: sign → sendTransaction (skipPreflight) → poll for confirmation
  // Avoids websocket-based confirmation which is unreliable on mobile + devnet.

  Future<String> _sendAndConfirm({
    required List<Instruction> instructions,
    required List<Ed25519HDKeyPair> signers,
  }) async {
    final rpc = _client.rpcClient;

    // 1. Get blockhash
    final bh = await rpc.getLatestBlockhash(commitment: Commitment.confirmed);

    // 2. Sign
    final message = Message(instructions: instructions);
    final tx = await signTransaction(bh.value, message, signers);

    // 3. Send with skipPreflight to avoid simulation-related false errors on devnet
    debugPrint('[SolanaPay] Sending tx (skipPreflight=true)...');
    final signature = await rpc.sendTransaction(
      tx.encode(),
      preflightCommitment: Commitment.confirmed,
      skipPreflight: true,
    );
    debugPrint('[SolanaPay] Sent! sig=$signature');

    // 4. Poll for confirmation via HTTP (no websocket needed)
    const maxAttempts = 30;
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final statuses = await rpc.getSignatureStatuses([signature]);
        final status = statuses.value.firstOrNull;
        if (status != null) {
          if (status.err != null) {
            debugPrint('[SolanaPay] Tx failed on-chain: ${status.err}');
            throw Exception('Transaction failed: ${status.err}');
          }
          if (status.confirmationStatus == Commitment.confirmed ||
              status.confirmationStatus == Commitment.finalized) {
            debugPrint('[SolanaPay] Confirmed at attempt $i');
            return signature;
          }
        }
      } catch (e) {
        if (e.toString().contains('Transaction failed')) rethrow;
        debugPrint('[SolanaPay] Poll error (attempt $i): $e');
      }
    }

    // If we get here, the tx was sent but never confirmed — likely still pending
    debugPrint('[SolanaPay] Tx sent but not confirmed within timeout, returning sig anyway');
    return signature;
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
