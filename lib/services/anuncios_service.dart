// anuncios_service.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';

class AnunciosService {
  static final AnunciosService _instancia = AnunciosService._internal();
  factory AnunciosService() => _instancia;
  AnunciosService._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _bannerReady = false;
  bool _interstitialReady = false;
  bool _rewardedReady = false;

  int productosExtra = 0;

  void inicializarAnuncios() {
    /*final config = RequestConfiguration(
      testDeviceIds: ['C9D0DE8127D83D064767B7705B4F9E5F'],
    );
    MobileAds.instance.updateRequestConfiguration(config);*/
    MobileAds.instance.initialize();
    productosExtra = Hive.box('configuracion').get('productosExtra', defaultValue: 0);
    _cargarBanner();
    _cargarInterstitial();
    _cargarRewarded();
  }

  void _cargarBanner() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-5644898978189989/9036593169',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => _bannerReady = true,
        onAdFailedToLoad: (ad, error) => _bannerReady = false,
      ),
    )..load();
  }

  void _cargarInterstitial() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-5644898978189989/2471184815',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
        },
        onAdFailedToLoad: (error) => _interstitialReady = false,
      ),
    );
  }

  void _cargarRewarded() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-5644898978189989/6569409591',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedReady = true;
        },
        onAdFailedToLoad: (error) => _rewardedReady = false,
      ),
    );
  }

  Widget? obtenerBannerWidget() {
    if (_bannerReady && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return null;
  }

  void mostrarInterstitial() {
    if (_interstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialReady = false;
      _cargarInterstitial();
    }
  }

  void mostrarRewarded(BuildContext context, VoidCallback onRecompensa) {
    if (_rewardedReady && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          productosExtra++;
          Hive.box('configuracion').put('productosExtra', productosExtra);
          onRecompensa();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Recompensa obtenida!')),
          );
        },
      );
      _rewardedReady = false;
      _cargarRewarded();
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('No se pudo cargar el anuncio. Intenta más tarde. Conectate a internet'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    }
  }
}
