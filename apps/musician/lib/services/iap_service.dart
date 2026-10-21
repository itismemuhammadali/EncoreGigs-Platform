import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final ApiService _apiService = ApiService();

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void>? _initFuture;
  Function(bool success, String message)? _onPurchaseCompleted;

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  // Product IDs configured in Google Play Console & Apple App Store Connect
  static const Set<String> _kProductIds = {
    'featured_24h',
    'featured_7d',
    'featured_30d',
  };

  void initialize({Function(bool success, String message)? onPurchaseCompleted}) {
    if (onPurchaseCompleted != null) {
      _onPurchaseCompleted = onPurchaseCompleted;
    }
    if (_subscription == null) {
      final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen(
        (purchases) => _listenToPurchaseUpdated(purchases),
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint("IAP Stream error: $error"),
      );
    }
    ensureInitialized();
  }

  Future<void> ensureInitialized() async {
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    _initFuture = _initIAP();
    await _initFuture;
  }

  Future<void> _initIAP() async {
    try {
      _isAvailable = await _iap.isAvailable();
      if (_isAvailable) {
        final ProductDetailsResponse response = await _iap.queryProductDetails(_kProductIds);
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint("IAP Products not found: ${response.notFoundIDs}");
        }
        if (response.error != null) {
          debugPrint("IAP query error: ${response.error}");
        }
        _products = response.productDetails;
      }
    } catch (e) {
      debugPrint("IAP initialization error: $e");
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint("Purchase pending...");
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint("Purchase error: ${purchase.error?.message}");
        _onPurchaseCompleted?.call(false, purchase.error?.message ?? "Purchase failed");
      } else if (purchase.status == PurchaseStatus.canceled) {
        debugPrint("Purchase canceled by user");
        _onPurchaseCompleted?.call(false, "Purchase canceled");
      } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        bool valid = await _verifyAndActivatePurchase(purchase);
        if (valid) {
          _onPurchaseCompleted?.call(true, "Successfully upgraded to Featured Artist!");
        } else {
          _onPurchaseCompleted?.call(false, "Server verification failed.");
        }
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyAndActivatePurchase(PurchaseDetails purchase) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    // Determine plan & price
    String plan = "7 Days";
    double amount = 14.99;

    if (purchase.productID == 'featured_24h') {
      plan = "24 Hours";
      amount = 4.99;
    } else if (purchase.productID == 'featured_30d') {
      plan = "30 Days";
      amount = 39.99;
    }

    try {
      await _apiService.purchaseFeaturedStatus(
        musicianId: uid,
        plan: plan,
        amount: amount,
        paymentToken: purchase.verificationData.serverVerificationData,
      );
      return true;
    } catch (e) {
      debugPrint("Failed to submit featured purchase to backend: $e");
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint("Error restoring purchases: $e");
      rethrow;
    }
  }

  Future<bool> buyFeaturedPlan({
    required String musicianId,
    required String planLabel,
    required double amount,
  }) async {
    // 1. Ensure IAP is initialized and products are loaded from Apple StoreKit
    await ensureInitialized();

    if (!_isAvailable) {
      throw Exception("In-App Purchases are not available on this device.");
    }

    // Determine product ID
    String productId = 'featured_7d';
    if (planLabel.contains('24') || planLabel.contains('Hour')) {
      productId = 'featured_24h';
    } else if (planLabel.contains('30') || planLabel.contains('Day')) {
      productId = 'featured_30d';
    }

    // 2. Safely find product without unsafe orElse generic type casting
    ProductDetails? product;
    for (final p in _products) {
      if (p.id == productId) {
        product = p;
        break;
      }
    }

    // If still null, try one direct query to StoreKit
    if (product == null) {
      final ProductDetailsResponse response = await _iap.queryProductDetails(_kProductIds);
      _products = response.productDetails;
      for (final p in _products) {
        if (p.id == productId) {
          product = p;
          break;
        }
      }
    }

    if (product == null) {
      throw Exception("Product details could not be loaded from the App Store. Please check your internet connection and try again.");
    }

    // 3. Initiate non-consumable purchase via StoreKit
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    // Completion will be handled via purchaseStream listener
    return false;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initFuture = null;
  }
}
