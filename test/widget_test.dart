import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_tracker/main.dart';

void main() {
  // Test to check if the app renders the main screen correctly.
  testWidgets('App renders Crypto Price Tracker title',
      (WidgetTester tester) async {
    // Build the app.
    await tester.pumpWidget(const CryptoTrackerApp());

    // Check if the AppBar title is present.
    expect(find.text('Crypto Price Tracker'), findsOneWidget);

    // Check if the welcome message appears when there is no data.
    expect(find.text('Welcome to Crypto Tracker!'), findsNothing);

    // Check for the loading spinner while fetching data.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // Test to check if the list of cryptocurrencies is rendered.
  testWidgets('Crypto list loads and displays data',
      (WidgetTester tester) async {
    // Mock data to simulate the fetched cryptocurrency data.
    final mockCryptoData = [
      {
        'name': 'Bitcoin',
        'current_price': 45000.0,
        'image': 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png'
      },
      {
        'name': 'Ethereum',
        'current_price': 3000.0,
        'image':
            'https://assets.coingecko.com/coins/images/279/large/ethereum.png'
      }
    ];

    // Override the fetchCryptoPrices function to return mock data.
    Future<List<dynamic>> mockFetchCryptoPrices() async {
      return mockCryptoData;
    }

    // Render the HomePage and inject the mocked fetch function.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Crypto Price Tracker'),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: mockFetchCryptoPrices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error fetching data'));
            } else {
              final cryptoList = snapshot.data!;
              return ListView.builder(
                itemCount: cryptoList.length,
                itemBuilder: (context, index) {
                  final crypto = cryptoList[index];
                  return ListTile(
                    leading: Image.network(crypto['image'], width: 40),
                    title: Text(crypto['name']),
                    subtitle: Text('\$${crypto['current_price']}'),
                  );
                },
              );
            }
          },
        ),
      ),
    ));

    // Wait for the FutureBuilder to complete.
    await tester.pump();

    // Verify the mock data is displayed in the list.
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('\$45000.0'), findsOneWidget);
    expect(find.text('Ethereum'), findsOneWidget);
    expect(find.text('\$3000.0'), findsOneWidget);
  });
}
