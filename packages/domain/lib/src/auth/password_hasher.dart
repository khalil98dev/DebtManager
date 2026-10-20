import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

/// Pure-Dart cryptographic SHA-256, HMAC-SHA256, and salted password hashing utility.
///
/// Provides standard FIPS 180-4 SHA-256 and RFC 2104 HMAC-SHA256 without external
/// native dependencies, enabling offline-first JWT signing and password verification.
abstract final class PasswordHasher {
  static const List<int> _k = <int>[
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static int _rotr(int n, int x) => ((x & 0xffffffff) >>> n) | ((x << (32 - n)) & 0xffffffff);

  /// Computes a 32-byte FIPS 180-4 SHA-256 digest of [data].
  static Uint8List sha256Bytes(List<int> data) {
    var h0 = 0x6a09e667;
    var h1 = 0xbb67ae85;
    var h2 = 0x3c6ef372;
    var h3 = 0xa54ff53a;
    var h4 = 0x510e527f;
    var h5 = 0x9b05688c;
    var h6 = 0x1f83d9ab;
    var h7 = 0x5be0cd19;

    final bitLength = data.length * 8;
    final paddedLength = ((data.length + 9 + 63) ~/ 64) * 64;
    final padded = Uint8List(paddedLength);
    padded.setRange(0, data.length, data);
    padded[data.length] = 0x80;

    final bd = ByteData.sublistView(padded);
    bd.setUint32(paddedLength - 8, (bitLength >>> 32) & 0xffffffff, Endian.big);
    bd.setUint32(paddedLength - 4, bitLength & 0xffffffff, Endian.big);

    final w = Uint32List(64);

    for (var offset = 0; offset < paddedLength; offset += 64) {
      for (var i = 0; i < 16; i++) {
        w[i] = bd.getUint32(offset + (i * 4), Endian.big);
      }
      for (var i = 16; i < 64; i++) {
        final s0 = _rotr(7, w[i - 15]) ^ _rotr(18, w[i - 15]) ^ ((w[i - 15] & 0xffffffff) >>> 3);
        final s1 = _rotr(17, w[i - 2]) ^ _rotr(19, w[i - 2]) ^ ((w[i - 2] & 0xffffffff) >>> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
      }

      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;
      var f = h5;
      var g = h6;
      var h = h7;

      for (var i = 0; i < 64; i++) {
        final s1 = _rotr(6, e) ^ _rotr(11, e) ^ _rotr(25, e);
        final ch = (e & f) ^ ((~e & 0xffffffff) & g);
        final temp1 = (h + s1 + ch + _k[i] + w[i]) & 0xffffffff;
        final s0 = _rotr(2, a) ^ _rotr(13, a) ^ _rotr(22, a);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xffffffff;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xffffffff;
      }

      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
      h5 = (h5 + f) & 0xffffffff;
      h6 = (h6 + g) & 0xffffffff;
      h7 = (h7 + h) & 0xffffffff;
    }

    final out = Uint8List(32);
    final outBd = ByteData.sublistView(out);
    outBd.setUint32(0, h0, Endian.big);
    outBd.setUint32(4, h1, Endian.big);
    outBd.setUint32(8, h2, Endian.big);
    outBd.setUint32(12, h3, Endian.big);
    outBd.setUint32(16, h4, Endian.big);
    outBd.setUint32(20, h5, Endian.big);
    outBd.setUint32(24, h6, Endian.big);
    outBd.setUint32(28, h7, Endian.big);
    return out;
  }

  /// Computes a 32-byte RFC 2104 HMAC-SHA256 authentication code.
  static Uint8List hmacSha256(List<int> key, List<int> message) {
    const blockSize = 64;
    var normalizedKey = Uint8List.fromList(key);
    if (normalizedKey.length > blockSize) {
      normalizedKey = sha256Bytes(normalizedKey);
    }
    final paddedKey = Uint8List(blockSize);
    paddedKey.setRange(0, normalizedKey.length, normalizedKey);

    final oKeyPad = Uint8List(blockSize);
    final iKeyPad = Uint8List(blockSize);
    for (var i = 0; i < blockSize; i++) {
      oKeyPad[i] = paddedKey[i] ^ 0x5c;
      iKeyPad[i] = paddedKey[i] ^ 0x36;
    }

    final innerInput = Uint8List(blockSize + message.length);
    innerInput.setRange(0, blockSize, iKeyPad);
    innerInput.setRange(blockSize, innerInput.length, message);
    final innerHash = sha256Bytes(innerInput);

    final outerInput = Uint8List(blockSize + innerHash.length);
    outerInput.setRange(0, blockSize, oKeyPad);
    outerInput.setRange(blockSize, outerInput.length, innerHash);
    return sha256Bytes(outerInput);
  }

  /// Hashes a plain-text password with a salt using iterative HMAC-SHA256.
  static String hashPassword(String plainText, {String? salt}) {
    final effectiveSalt = salt ?? const Uuid().v4().replaceAll('-', '');
    final saltBytes = utf8.encode(effectiveSalt);
    var digest = hmacSha256(saltBytes, utf8.encode(plainText));
    for (var i = 0; i < 128; i++) {
      digest = hmacSha256(saltBytes, digest);
    }
    final hex = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '$effectiveSalt\$$hex';
  }

  /// Verifies a plain-text password against a stored `salt$hash` string in constant time.
  static bool verifyPassword(String plainText, String storedHash) {
    final parts = storedHash.split('\$');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expected = hashPassword(plainText, salt: salt);
    if (expected.length != storedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
    }
    return diff == 0;
  }
}
