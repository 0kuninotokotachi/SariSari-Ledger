import 'package:flutter_test/flutter_test.dart';
import 'package:sarisari_ledger/providers/customer_provider.dart';

import '../helpers/isar_test_helper.dart';

Future<void> _addCustomer(
  CustomerProvider provider, {
  required String name,
  double amount = 0,
  String? phoneNumber,
  DateTime? createdAt,
}) async {
  await provider.addCustomerWithInitialUtang(
    name: name,
    amount: amount,
    loanDate: createdAt ?? DateTime(2026, 1, 1),
    dueDate: DateTime(2026, 2, 1),
    phoneNumber: phoneNumber,
  );
}

void main() {
  setUpAll(setUpIsar);
  tearDownAll(tearDownIsar);

  late CustomerProvider provider;

  setUp(() async {
    await clearIsar();
    provider = CustomerProvider();
    await provider.loadCustomers();
  });

  group('pinnedCustomers', () {
    test('returns [] when nobody is pinned', () {
      expect(provider.pinnedCustomers, isEmpty);
    });

    test('returns pinned customers ordered ascending by pinOrder', () async {
      await _addCustomer(provider, name: 'Ana');
      await _addCustomer(provider, name: 'Bea');
      await _addCustomer(provider, name: 'Cy');
      final ids = provider.customers.map((c) => c.id).toList();

      // Pin in an order different from insertion, then verify pinOrder
      // ascending reflects pin order, not name/insertion order.
      await provider.pinCustomer(ids[2]); // Cy -> 0
      await provider.pinCustomer(ids[0]); // Ana -> 1

      final pinnedNames = provider.pinnedCustomers.map((c) => c.name).toList();
      expect(pinnedNames, ['Cy', 'Ana']);
    });
  });

  group('pinCustomer', () {
    test('appends the next pinOrder after existing pinned customers',
        () async {
      await _addCustomer(provider, name: 'Ana');
      await _addCustomer(provider, name: 'Bea');
      final ids = provider.customers.map((c) => c.id).toList();

      await provider.pinCustomer(ids[0]);
      await provider.pinCustomer(ids[1]);

      final pinned = {for (final c in provider.customers) c.id: c.pinOrder};
      expect(pinned[ids[0]], 0);
      expect(pinned[ids[1]], 1);
    });

    test('pinning an already-pinned customer is a no-op', () async {
      await _addCustomer(provider, name: 'Ana');
      final id = provider.customers.first.id;

      await provider.pinCustomer(id);
      await provider.pinCustomer(id);

      expect(provider.pinnedCustomers.length, 1);
      expect(provider.pinnedCustomers.first.pinOrder, 0);
    });

    test('throws PinLimitExceededException at the cap and writes nothing',
        () async {
      for (var i = 0; i < CustomerProvider.maxPinnedCustomers; i++) {
        await _addCustomer(provider, name: 'Customer$i');
      }
      await _addCustomer(provider, name: 'Overflow');
      for (final c in provider.customers) {
        if (c.name != 'Overflow') {
          await provider.pinCustomer(c.id);
        }
      }
      expect(provider.pinnedCustomers.length, CustomerProvider.maxPinnedCustomers);

      final overflow = provider.customers.firstWhere((c) => c.name == 'Overflow');
      await expectLater(
        () => provider.pinCustomer(overflow.id),
        throwsA(isA<PinLimitExceededException>()),
      );
      await provider.loadCustomers();
      expect(
        provider.customers.firstWhere((c) => c.id == overflow.id).pinOrder,
        isNull,
      );
    });

    test('no-ops silently when customerId does not exist', () async {
      await provider.pinCustomer(999999);
      expect(provider.pinnedCustomers, isEmpty);
    });
  });

  group('unpinCustomer', () {
    test('sets pinOrder to null for the target customer', () async {
      await _addCustomer(provider, name: 'Ana');
      final id = provider.customers.first.id;
      await provider.pinCustomer(id);

      await provider.unpinCustomer(id);

      expect(provider.customers.first.pinOrder, isNull);
    });

    test('compacts remaining pinned customers after unpinning the middle one',
        () async {
      await _addCustomer(provider, name: 'Ana');
      await _addCustomer(provider, name: 'Bea');
      await _addCustomer(provider, name: 'Cy');
      final ids = provider.customers.map((c) => c.id).toList();
      for (final id in ids) {
        await provider.pinCustomer(id);
      }

      await provider.unpinCustomer(ids[1]); // unpin the middle (pinOrder 1)

      final remaining = provider.pinnedCustomers;
      expect(remaining.map((c) => c.id).toList(), [ids[0], ids[2]]);
      expect(remaining.map((c) => c.pinOrder).toList(), [0, 1]);
    });

    test('no-ops silently when customerId does not exist or is not pinned',
        () async {
      await _addCustomer(provider, name: 'Ana');
      final id = provider.customers.first.id;

      await provider.unpinCustomer(id); // not pinned
      await provider.unpinCustomer(999999); // doesn't exist

      expect(provider.pinnedCustomers, isEmpty);
    });
  });

  group('reorderPinnedCustomers', () {
    test('moving a customer earlier reorders correctly', () async {
      await _addCustomer(provider, name: 'Ana');
      await _addCustomer(provider, name: 'Bea');
      await _addCustomer(provider, name: 'Cy');
      for (final c in provider.customers) {
        await provider.pinCustomer(c.id);
      }
      // Order after pinning: Ana(0), Bea(1), Cy(2).
      await provider.reorderPinnedCustomers(2, 0);

      expect(
        provider.pinnedCustomers.map((c) => c.name).toList(),
        ['Cy', 'Ana', 'Bea'],
      );
    });

    test('moving a customer later inserts at newIndex (onReorderItem convention)',
        () async {
      await _addCustomer(provider, name: 'Ana');
      await _addCustomer(provider, name: 'Bea');
      await _addCustomer(provider, name: 'Cy');
      for (final c in provider.customers) {
        await provider.pinCustomer(c.id);
      }
      // Move Ana (index 0) to end (index 2); onReorderItem already supplies
      // the post-removal target index, so no extra shift is applied.
      await provider.reorderPinnedCustomers(0, 2);

      expect(
        provider.pinnedCustomers.map((c) => c.name).toList(),
        ['Bea', 'Cy', 'Ana'],
      );
    });

    test('reordering a single pinned customer with itself is a no-op',
        () async {
      await _addCustomer(provider, name: 'Ana');
      await provider.pinCustomer(provider.customers.first.id);

      await provider.reorderPinnedCustomers(0, 0);

      expect(provider.pinnedCustomers.map((c) => c.name).toList(), ['Ana']);
    });

    test('does not modify any non-pinned customer', () async {
      await _addCustomer(provider, name: 'Ana');
      await _addCustomer(provider, name: 'Bea');
      final ids = provider.customers.map((c) => c.id).toList();
      await provider.pinCustomer(ids[0]);

      await provider.reorderPinnedCustomers(0, 0);

      final bea = provider.customers.firstWhere((c) => c.id == ids[1]);
      expect(bea.pinOrder, isNull);
    });
  });

  group('updateCustomerInfo', () {
    test('renaming to a new unique name persists', () async {
      await _addCustomer(provider, name: 'Ana');
      final id = provider.customers.first.id;

      await provider.updateCustomerInfo(id, name: 'Ana Reyes', phoneNumber: '0917-000-0000');

      final updated = provider.customers.firstWhere((c) => c.id == id);
      expect(updated.name, 'Ana Reyes');
      expect(updated.phoneNumber, '0917-000-0000');
    });

    test('renaming to a name taken by a different customer throws and leaves the DB unchanged',
        () async {
      await _addCustomer(provider, name: 'Ana');
      await _addCustomer(provider, name: 'Bea');
      final ids = {for (final c in provider.customers) c.name: c.id};

      await expectLater(
        () => provider.updateCustomerInfo(ids['Ana']!, name: 'bea'),
        throwsA(isA<DuplicateCustomerNameException>()),
      );

      await provider.loadCustomers();
      expect(provider.customers.firstWhere((c) => c.id == ids['Ana']!).name, 'Ana');
    });

    test('renaming a customer to its own current name (different case) succeeds',
        () async {
      await _addCustomer(provider, name: 'Ana Reyes');
      final id = provider.customers.first.id;

      await provider.updateCustomerInfo(id, name: 'ana reyes');

      expect(provider.customers.firstWhere((c) => c.id == id).name, 'ana reyes');
    });

    test('contact-field-only updates still work alongside the required name param',
        () async {
      await _addCustomer(provider, name: 'Ana');
      final id = provider.customers.first.id;

      await provider.updateCustomerInfo(
        id,
        name: 'Ana',
        phoneNumber: '0917-111-2222',
        address: '123 Rizal St',
        facebookId: 'ana.fb',
        email: 'ana@example.com',
        notes: 'Regular customer',
      );

      final updated = provider.customers.firstWhere((c) => c.id == id);
      expect(updated.phoneNumber, '0917-111-2222');
      expect(updated.address, '123 Rizal St');
      expect(updated.facebookId, 'ana.fb');
      expect(updated.email, 'ana@example.com');
      expect(updated.notes, 'Regular customer');
    });
  });

  group('filteredCustomers', () {
    setUp(() async {
      await _addCustomer(
        provider,
        name: 'Ana Reyes',
        amount: 100,
        phoneNumber: '0917-111-2222',
        createdAt: DateTime(2026, 1, 1),
      );
      await _addCustomer(
        provider,
        name: 'Bea Santos',
        amount: 0,
        phoneNumber: '0918-333-4444',
        createdAt: DateTime(2026, 3, 1),
      );
      await _addCustomer(
        provider,
        name: 'Cy Cruz',
        amount: -50,
        createdAt: DateTime(2026, 2, 1),
      );
    });

    test('defaults to all customers sorted by name, case-insensitively', () {
      expect(
        provider.filteredCustomers.map((c) => c.name).toList(),
        ['Ana Reyes', 'Bea Santos', 'Cy Cruz'],
      );
    });

    test('search matches name case-insensitively as a substring', () {
      provider.setSearchQuery('reyes');
      expect(provider.filteredCustomers.map((c) => c.name).toList(), ['Ana Reyes']);
    });

    test('search matches phoneNumber as a substring', () {
      provider.setSearchQuery('333-4444');
      expect(provider.filteredCustomers.map((c) => c.name).toList(), ['Bea Santos']);
    });

    test('whitespace-only query behaves like an empty query', () {
      provider.setSearchQuery('   ');
      expect(provider.filteredCustomers.length, 3);
    });

    test('a customer with a null phoneNumber is still matchable by name', () {
      provider.setSearchQuery('cy cruz');
      expect(provider.filteredCustomers.map((c) => c.name).toList(), ['Cy Cruz']);
    });

    test('UtangFilter.hasUtang includes only totalUtang > 0', () {
      provider.setUtangFilter(UtangFilter.hasUtang);
      expect(provider.filteredCustomers.map((c) => c.name).toList(), ['Ana Reyes']);
    });

    test('UtangFilter.fullyPaid includes zero and negative balances', () {
      provider.setUtangFilter(UtangFilter.fullyPaid);
      expect(
        provider.filteredCustomers.map((c) => c.name).toList(),
        ['Bea Santos', 'Cy Cruz'],
      );
    });

    test('CustomerSort.balanceHighToLow orders descending', () {
      provider.setSortMode(CustomerSort.balanceHighToLow);
      expect(
        provider.filteredCustomers.map((c) => c.name).toList(),
        ['Ana Reyes', 'Bea Santos', 'Cy Cruz'],
      );
    });

    test('CustomerSort.balanceLowToHigh orders ascending', () {
      provider.setSortMode(CustomerSort.balanceLowToHigh);
      expect(
        provider.filteredCustomers.map((c) => c.name).toList(),
        ['Cy Cruz', 'Bea Santos', 'Ana Reyes'],
      );
    });

    test('CustomerSort.recentlyAdded orders by createdAt descending', () {
      provider.setSortMode(CustomerSort.recentlyAdded);
      expect(
        provider.filteredCustomers.map((c) => c.name).toList(),
        ['Bea Santos', 'Cy Cruz', 'Ana Reyes'],
      );
    });

    test('search, filter, and sort compose together', () {
      // 'a' matches Ana and Bea by name, but not Cy Cruz; combined with the
      // fullyPaid filter (Ana has utang), only Bea should remain.
      provider.setSearchQuery('a');
      provider.setUtangFilter(UtangFilter.fullyPaid);
      provider.setSortMode(CustomerSort.balanceLowToHigh);
      expect(
        provider.filteredCustomers.map((c) => c.name).toList(),
        ['Bea Santos'],
      );
    });

    test('returns [] when nothing matches', () {
      provider.setSearchQuery('nonexistent-name-zzz');
      expect(provider.filteredCustomers, isEmpty);
    });
  });

  group('setSearchQuery / setUtangFilter / setSortMode', () {
    test('each updates its field and notifies listeners, even redundantly',
        () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setSearchQuery('x');
      provider.setSearchQuery('x');
      provider.setUtangFilter(UtangFilter.hasUtang);
      provider.setUtangFilter(UtangFilter.hasUtang);
      provider.setSortMode(CustomerSort.recentlyAdded);
      provider.setSortMode(CustomerSort.recentlyAdded);

      expect(provider.searchQuery, 'x');
      expect(provider.utangFilter, UtangFilter.hasUtang);
      expect(provider.sortMode, CustomerSort.recentlyAdded);
      expect(notifyCount, 6);
    });
  });
}
