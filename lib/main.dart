import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CryptoTrackerApp());
}

class CryptoTrackerApp extends StatefulWidget {
  const CryptoTrackerApp({Key? key}) : super(key: key);

  @override
  _CryptoTrackerAppState createState() => _CryptoTrackerAppState();
}

class _CryptoTrackerAppState extends State<CryptoTrackerApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  // Load theme preference from shared preferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Save theme preference to shared preferences
  Future<void> _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveThemePreference(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomePage(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const HomePage(
      {Key? key, required this.onThemeToggle, required this.isDarkMode})
      : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<dynamic>> _cryptoData;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredData = [];
  String _sortBy = 'Name';

  @override
  void initState() {
    super.initState();
    _cryptoData = fetchCryptoPrices();
  }

  Future<List<dynamic>> fetchCryptoPrices() async {
    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1&sparkline=false');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load cryptocurrency prices');
    }
  }

  void _filterSearchResults(String query, List<dynamic> cryptoList) {
    if (query.isEmpty) {
      setState(() {
        _filteredData = cryptoList;
      });
    } else {
      setState(() {
        _filteredData = cryptoList
            .where((crypto) =>
                crypto['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _sortData(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      if (_filteredData.isNotEmpty) {
        if (_sortBy == 'Price') {
          _filteredData
              .sort((a, b) => b['current_price'].compareTo(a['current_price']));
        } else if (_sortBy == 'Name') {
          _filteredData.sort((a, b) => a['name'].compareTo(b['name']));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Price Tracker'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
          ),
          DropdownButton<String>(
            value: _sortBy,
            onChanged: (value) {
              if (value != null) _sortData(value);
            },
            dropdownColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
            iconEnabledColor: Colors.white,
            items: const [
              DropdownMenuItem(value: 'Name', child: Text('Sort by Name')),
              DropdownMenuItem(value: 'Price', child: Text('Sort by Price')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _cryptoData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final cryptoList = snapshot.data!;
          if (_filteredData.isEmpty) {
            _filteredData = cryptoList;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Crypto',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) => _filterSearchResults(query, cryptoList),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _cryptoData = fetchCryptoPrices();
                      _filteredData.clear();
                    });
                    await _cryptoData;
                  },
                  child: ListView.builder(
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final crypto = _filteredData[index];
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: Image.network(crypto['image'], width: 40),
                          title: Text(
                            crypto['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('\$${crypto['current_price']}'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CryptoDetailsPage(
                                  crypto: crypto,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CryptoDetailsPage extends StatelessWidget {
  final Map<String, dynamic> crypto;

  const CryptoDetailsPage({Key? key, required this.crypto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(crypto['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(crypto['image'], height: 100),
            ),
            const SizedBox(height: 16),
            Text(
              'Name: ${crypto['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Symbol: ${crypto['symbol'].toUpperCase()}'),
            Text('Current Price: \$${crypto['current_price']}'),
            Text('Market Cap: \$${crypto['market_cap']}'),
            Text('24h Volume: \$${crypto['total_volume']}'),
            Text(
              'Price Change (24h): ${crypto['price_change_percentage_24h'].toStringAsFixed(2)}%',
              style: TextStyle(
                color: crypto['price_change_percentage_24h'] >= 0
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
