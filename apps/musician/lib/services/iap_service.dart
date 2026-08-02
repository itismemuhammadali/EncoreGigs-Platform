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

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  // Product IDs configured in Google Play Console & Apple App Store Connect
  static const Set<String> _kProductIds = {
    'featured_24h',
    'featured_7d',
    'featured_30d',
  };

  void initialize({Function(bool success, String message)? onPurchaseCompleted}) {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchases) => _listenToPurchaseUpdated(purchases, onPurchaseCompleted),
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint("IAP Stream error: $error"),
    );
    _initIAP();
  }

  Future<void> _initIAP() async {
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      final ProductDetailsResponse response = await _iap.queryProductDetails(_kProductIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("IAP Products not found: ${response.notFoundIDs}");
      }
      _products = response.productDetails;
    }
  }

  void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
    Function(bool success, String message)? onPurchaseCompleted,
  ) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint("Purchase pending...");
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint("Purchase error: ${purchase.error?.message}");
        onPurchaseCompleted?.call(false, purchase.error?.message ?? "Purchase failed");
      } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        bool valid = await _verifyAndActivatePurchase(purchase);
        if (valid) {
          onPurchaseCompleted?.call(true, "Successfully upgraded to Featured Artist!");
        } else {
          onPurchaseCompleted?.call(false, "Server verification failed.");
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
    double amount = 49.99;

    if (purchase.productID == 'featured_24h') {
      plan = "24 Hours";
      amount = 19.99;
    } else if (purchase.productID == 'featured_30d') {
      plan = "30 Days";
      amount = 149.99;
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

  Future<bool> buyFeaturedPlan({
    required String musicianId,
    required String planLabel,
    required double amount,
  }) async {
    // Determine product ID
    String productId = 'featured_7d';
    if (planLabel.contains('24') || planLabel.contains('Hour')) {
      productId = 'featured_24h';
    } else if (planLabel.contains('30') || planLabel.contains('Day')) {
      productId = 'featured_30d';
    }

    // Check if store product is loaded
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => ProductDetails(
        id: productId,
        title: 'Featured Artist ($planLabel)',
        description: 'Upgrade profile visibility',
        price: '\$$amount',
        rawPrice: amount,
        currencyCode: 'USD',
      ),
    );

    if (_isAvailable && _products.any((p) => p.id == productId)) {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      // Sandbox / Store pending fallback: Direct verified purchase API call
      try {
        await _apiService.purchaseFeaturedStatus(
          musicianId: musicianId,
          plan: planLabel,
          amount: amount,
        );
        return true;
      } catch (e) {
        debugPrint("Error processing featured purchase: $e");
        rethrow;
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
