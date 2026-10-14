import 'package:flutter_test/flutter_test.dart';
import 'package:nestory/core/constants/iap_constants.dart';
import 'package:nestory/core/services/iap_config_service.dart';
import 'package:nestory/models/shop_item.dart';

void main() {
  test('Nest Story IAP ids and N322 endpoint', () {
    expect(IapConstants.productPrefix, 'ns');
    expect(IapConstants.remoteConfigUrl, 'https://api2.blwsmartware.net/N322.json');
    expect(IapConstants.coinPackIds.first, 'ns_pack_1');
    expect(IapConstants.coinPackIds.last, 'ns_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'ns_remove_ads');
    expect(IapConstants.proProductId, 'ns_pro');
    expect(IapConstants.allProductIds, containsAll([...IapConstants.coinPackIds, 'ns_remove_ads', 'ns_pro']));
    expect(IapConstants.coinsForProduct('ns_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'Nest Story'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson({'disable': 0, 'name': 'Nest Story', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'Nest Story');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
