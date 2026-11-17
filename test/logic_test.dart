import 'package:flutter_test/flutter_test.dart';
import 'package:sayed_al_dukan/core/format.dart';
import 'package:sayed_al_dukan/core/search_util.dart';
import 'package:sayed_al_dukan/models/models.dart';

Product p(double price, double min) => Product(
    id: '1', name: 'x', description: '', unitPrice: price, minOrderValue: min,
    ingredients: const [], images: const []);

void main() {
  test('min quantity derives from money minimum', () {
    expect(p(10, 100).minQty, 10);   // brief example
    expect(p(30, 100).minQty, 4);    // ceil(3.33)
    expect(p(12.5, 100).minQty, 8);
    expect(p(10, 0).minQty, 1);
    expect(p(250, 100).minQty, 1);
  });

  test('fuzzy search tolerates small typos, rejects unrelated', () {
    expect(fuzzyMatches('كركدي', 'كركديه سوداني'), true);
    expect(fuzzyMatches('كركدية', 'كركديه'), true);
    expect(fuzzyMatches('عصيده', 'عصيدة'), true);
    expect(fuzzyMatches('ملوخيه', 'كركديه'), false);
    expect(fuzzyMatches('', 'كركديه'), false);
  });

  test('masking', () {
    expect(maskEmail('mohamed@gmail.com'), 'mo****@gmail.com');
    expect(maskPhone('201012345678'), '+20 10******78');
  });
}
