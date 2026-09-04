import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const gold = Color(0xFFFFC400);
const dark = Color(0xFF111111);
const lightBg = Color(0xFFF7F7F7);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SurucuTakipApp());
}

class Trip {
  String id;
  double amount;
  String payment;
  String? debtor;
  String? note;
  DateTime createdAt;
  bool paid;

  Trip({
    required this.id,
    required this.amount,
    required this.payment,
    this.debtor,
    this.note,
    required this.createdAt,
    this.paid = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'payment': payment,
        'debtor': debtor,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'paid': paid,
      };

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: j['id'].toString(),
        amount: (j['amount'] as num).toDouble(),
        payment: j['payment'].toString(),
        debtor: j['debtor']?.toString(),
        note: j['note']?.toString(),
        createdAt: DateTime.parse(j['createdAt'].toString()),
        paid: j['paid'] == true,
      );
}

class Storage {
  static const tripsKey = 'trips';
  static const driverKey = 'driverName';
  static const stationKey = 'stationName';
  static const darkKey = 'darkMode';

  static Future<SharedPreferences> _p() =>
      SharedPreferences.getInstance();

  static Future<List<Trip>> loadTrips() async {
    final p = await _p();
    final raw = p.getStringList(tripsKey) ?? [];
    return raw.map((x) => Trip.fromJson(jsonDecode(x))).toList();
  }

  static Future<void> saveTrips(List<Trip> trips) async {
    final p = await _p();
    await p.setStringList(
      tripsKey,
      trips.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  static Future<String> loadDriver() async {
    final p = await _p();
    return p.getString(driverKey) ?? 'Sürücü Adı';
  }

  static Future<void> saveDriver(String name) async {
    final p = await _p();
    await p.setString(driverKey, name);
  }

  static Future<String> loadStation() async {
    final p = await _p();
    return p.getString(stationKey) ?? 'Durak Adı';
  }

  static Future<void> saveStation(String name) async {
    final p = await _p();
    await p.setString(stationKey, name);
  }

  static Future<bool> loadDarkMode() async {
    final p = await _p();
    return p.getBool(darkKey) ?? false;
  }

  static Future<void> saveDarkMode(bool value) async {
    final p = await _p();
    await p.setBool(darkKey, value);
  }
}

class SurucuTakipApp extends StatefulWidget {
  const SurucuTakipApp({super.key});

  @override
  State<SurucuTakipApp> createState() => _SurucuTakipAppState();
}

class _SurucuTakipAppState extends State<SurucuTakipApp> {
  bool darkMode = false;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    darkMode = await Storage.loadDarkMode();
    if (mounted) {
      setState(() => loaded = true);
    }
  }

  Future<void> _toggleTheme() async {
    final next = !darkMode;
    await Storage.saveDarkMode(next);
    if (mounted) {
      setState(() => darkMode = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: gold),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sürücü Takip',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: lightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: dark,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: gold,
              width: 2,
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF202020),
          labelStyle: TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: gold,
              width: 2,
            ),
          ),
        ),
      ),
      home: SplashScreen(
        onFinished: () => HomeScreen(
          darkMode: darkMode,
          onThemeChanged: _toggleTheme,
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final Widget Function()? onFinished;

  const SplashScreen({
    super.key,
    this.onFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String driver = 'Sürücü Adı';
  String station = 'Durak Adı';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    driver = await Storage.loadDriver();
    station = await Storage.loadStation();

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              widget.onFinished?.call() ??
              HomeScreen(
                darkMode: false,
                onThemeChanged: () {},
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 230,
                  height: 230,
                ),
                Positioned(
                  top: 72,
                  child: Text(
                    driver,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 61,
                  child: Text(
                    station,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Kerem Bayar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool darkMode;
  final VoidCallback onThemeChanged;

  const HomeScreen({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Trip> trips = [];
  String driver = 'Sürücü Adı';
  String station = 'Durak Adı';

  bool get isDark =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await Storage.loadTrips();
    final d = await Storage.loadDriver();
    final s = await Storage.loadStation();

    if (mounted) {
      setState(() {
        trips = loaded;
        driver = d;
        station = s;
      });
    }
  }

  bool _today(DateTime d) {
    final n = DateTime.now();

    return d.year == n.year &&
        d.month == n.month &&
        d.day == n.day;
  }

  Future<void> _addOrEdit({Trip? trip}) async {
    final result = await Navigator.push<Trip>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTripScreen(
          trip: trip,
        ),
      ),
    );

    if (result == null) return;

    final index = trips.indexWhere(
      (x) => x.id == result.id,
    );

    if (index >= 0) {
      trips[index] = result;
    } else {
      trips.add(result);
    }

    await Storage.saveTrips(trips);
    await _load();

    if (mounted && trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Yolculuk başarıyla kaydedildi. ✅',
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _changeDriver() async {
    final controller = TextEditingController(
      text: driver == 'Sürücü Adı' ? '' : driver,
    );

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            isDark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: gold,
            width: 1.5,
          ),
        ),
        title: Text(
          'Sürücü adını değiştir',
          style: TextStyle(
            color:
                isDark ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization:
              TextCapitalization.words,
          style: TextStyle(
            color:
                isDark ? Colors.white : Colors.black,
          ),
          decoration: const InputDecoration(
            labelText: 'Sürücü adı',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext),
            child: Text(
              'İptal Et',
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null || name.isEmpty) return;

    await Storage.saveDriver(name);
    await _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sürücü Adı başarıyla değiştirilmiştir. ✅',
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _changeStation() async {
    final controller = TextEditingController(
      text: station == 'Durak Adı' ? '' : station,
    );

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            isDark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: gold,
            width: 1.5,
          ),
        ),
        title: Text(
          'Durak adını değiştir',
          style: TextStyle(
            color:
                isDark ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization:
              TextCapitalization.words,
          style: TextStyle(
            color:
                isDark ? Colors.white : Colors.black,
          ),
          decoration: const InputDecoration(
            labelText: 'Durak adı',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext),
            child: Text(
              'İptal Et',
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null || name.isEmpty) return;

    await Storage.saveStation(name);
    await _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Durak Adı başarıyla değiştirilmiştir. ✅',
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
    Future<void> _openMenu() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final darkTheme =
            Theme.of(sheetContext).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: darkTheme ? Colors.black : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
            border: const Border(
              top: BorderSide(color: gold, width: 2),
              left: BorderSide(color: gold),
              right: BorderSide(color: gold),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                _menuButton(
                  sheetContext,
                  'Sürücü adını değiştir',
                  Icons.person_outline,
                  'driver',
                ),
                _menuButton(
                  sheetContext,
                  'Durak adını değiştir',
                  Icons.location_on_outlined,
                  'station',
                ),
                _menuButton(
                  sheetContext,
                  'Yolculukları düzenle / sil',
                  Icons.edit_note_outlined,
                  'trips',
                ),
                _menuButton(
                  sheetContext,
                  'Borçlar',
                  Icons.account_balance_wallet_outlined,
                  'debts',
                ),
                _menuButton(
                  sheetContext,
                  'Geçmiş Kayıtlar',
                  Icons.history,
                  'history',
                ),
                _menuButton(
                  sheetContext,
                  'Hakkında',
                  Icons.info_outline,
                  'about',
                ),
                _menuButton(
                  sheetContext,
                  darkTheme
                      ? 'Tema : Aydınlık'
                      : 'Tema : Karanlık',
                  darkTheme
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  'theme',
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    switch (result) {
      case 'driver':
        await _changeDriver();
        break;

      case 'station':
        await _changeStation();
        break;

      case 'trips':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripsScreen(
              trips: trips,
              onChanged: _load,
            ),
          ),
        );
        await _load();
        break;

      case 'debts':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DebtsScreen(
              trips: trips,
              onChanged: _load,
            ),
          ),
        );
        await _load();
        break;

      case 'history':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryScreen(
              trips: trips,
              onChanged: _load,
            ),
          ),
        );
        await _load();
        break;

      case 'about':
        await _about();
        break;

      case 'theme':
        widget.onThemeChanged();
        break;
    }
  }

  Widget _menuButton(
    BuildContext context,
    String title,
    IconData icon,
    String value,
  ) {
    final darkTheme =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: darkTheme
            ? const Color(0xFF101010)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: gold,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: gold,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: darkTheme
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: darkTheme
              ? Colors.white
              : Colors.black,
        ),
        onTap: () => Navigator.pop(
          context,
          value,
        ),
      ),
    );
  }

  Future<void> _about() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final darkTheme =
            Theme.of(dialogContext).brightness ==
                Brightness.dark;

        return AlertDialog(
          backgroundColor:
              darkTheme ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(
              color: gold,
              width: 1.5,
            ),
          ),
          title: const Text(
            'Sürücü Takip',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Sürüm 1.1.0\n\n'
            'Bu uygulama Kerem BAYAR tarafından üretilmiştir.\n'
            'Bizi tercih ettiğiniz için teşekkür ederiz.',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    String value, {
    Color? valueColor,
  }) {
    final darkTheme =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkTheme
            ? const Color(0xFFD9D9D9)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gold,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentSummary(
    String title,
    double value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness ==
                Brightness.dark
            ? const Color(0xFFD9D9D9)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gold,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.15),
            child: Icon(
              _paymentIcon(title),
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} TL',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  IconData _paymentIcon(String payment) {
    switch (payment) {
      case 'Nakit':
        return Icons.payments_outlined;
      case 'POS':
        return Icons.credit_card_outlined;
      case 'IBAN':
        return Icons.account_balance_outlined;
      case 'Borç':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  String _date(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }

  String _time(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final todayTrips =
        trips.where((t) => _today(t.createdAt)).toList();

    final totalTrips = todayTrips.length;

    final totalEarnings = todayTrips.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    final cash = todayTrips
        .where((t) => t.payment == 'Nakit')
        .fold(0.0, (sum, t) => sum + t.amount);

    final pos = todayTrips
        .where((t) => t.payment == 'POS')
        .fold(0.0, (sum, t) => sum + t.amount);

    final iban = todayTrips
        .where((t) => t.payment == 'IBAN')
        .fold(0.0, (sum, t) => sum + t.amount);

    final debt = trips
        .where((t) => t.payment == 'Borç' && !t.paid)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        foregroundColor: dark,
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Yeni Yolculuk',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              14,
              10,
              14,
              100,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        station,
                        style: const TextStyle(
                          color: gold,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B1B1B)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: gold,
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.menu,
                        color: gold,
                      ),
                      onPressed: _openMenu,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  driver,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              _summaryCard(
                'Toplam Yolculuk',
                '$totalTrips',
              ),

              const SizedBox(height: 9),

              _summaryCard(
                'Toplam Kazanç',
                '${totalEarnings.toStringAsFixed(2)} TL',
              ),

              const SizedBox(height: 9),

              _paymentSummary(
                'Nakit',
                cash,
                Colors.green,
              ),

              const SizedBox(height: 9),

              _paymentSummary(
                'POS',
                pos,
                gold,
              ),

              const SizedBox(height: 9),

              _paymentSummary(
                'IBAN',
                iban,
                Colors.blue,
              ),

              const SizedBox(height: 9),

              _summaryCard(
                'Borç',
                '${debt.toStringAsFixed(2)} TL',
                valueColor: Colors.red,
              ),

              const SizedBox(height: 20),

              const Text(
                'Bugünkü Yolculuklar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              if (todayTrips.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF151515)
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: gold,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Bugün henüz yolculuk kaydı yok.',
                    ),
                  ),
                )
              else
                ...todayTrips.reversed
                    .take(5)
                    .map(
                      (t) => _tripCard(
                        t,
                        onEdit: () =>
                            _addOrEdit(trip: t),
                        onDelete: () async {
                          trips.removeWhere(
                            (x) => x.id == t.id,
                          );
                          await Storage.saveTrips(
                            trips,
                          );
                          await _load();
                        },
                        showDate: false,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTripScreen extends StatefulWidget {
  final Trip? trip;

  const AddTripScreen({
    super.key,
    this.trip,
  });

  @override
  State<AddTripScreen> createState() =>
      _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  late TextEditingController amount;
  late TextEditingController debtor;
  late TextEditingController note;

  String payment = 'Nakit';

  @override
  void initState() {
    super.initState();

    amount = TextEditingController(
      text: widget.trip == null
          ? ''
          : widget.trip!.amount
              .toStringAsFixed(2),
    );

    debtor = TextEditingController(
      text: widget.trip?.debtor ?? '',
    );

    note = TextEditingController(
      text: widget.trip?.note ?? '',
    );

    payment =
        widget.trip?.payment ?? 'Nakit';
  }

  @override
  void dispose() {
    amount.dispose();
    debtor.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = amount.text
        .trim()
        .replaceAll(',', '.');

    final value = double.tryParse(raw);

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen geçerli bir tutar girin.',
          ),
        ),
      );
      return;
    }

    if (payment == 'Borç' &&
        debtor.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen borçlu adını girin.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final darkTheme =
            Theme.of(dialogContext).brightness ==
                Brightness.dark;

        return AlertDialog(
          backgroundColor:
              darkTheme ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(
              color: gold,
              width: 1.5,
            ),
          ),
          title: const Text(
            'Kaydı onaylıyor musunuz?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Tutar: ${value.toStringAsFixed(2)} TL',
              ),
              Text(
                'Ödeme: $payment',
              ),
              if (payment == 'Borç')
                Text(
                  'Borçlu: ${debtor.text.trim()}',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: Text(
                'İptal Et',
                style: TextStyle(
                  color: darkTheme
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Onayla'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final now = DateTime.now();

    Navigator.pop(
      context,
      Trip(
        id: widget.trip?.id ??
            DateTime.now()
                .microsecondsSinceEpoch
                .toString(),
        amount: value,
        payment: payment,
        debtor: payment == 'Borç'
            ? debtor.text.trim()
            : null,
        note: note.text.trim().isEmpty
            ? null
            : note.text.trim(),
        createdAt:
            widget.trip?.createdAt ?? now,
        paid: widget.trip?.paid ?? false,
      ),
    );
  }

  void _quickAmount(double value) {
    amount.text =
        value.toStringAsFixed(0);

    amount.selection =
        TextSelection.collapsed(
      offset: amount.text.length,
    );
  }
    @override
  Widget build(BuildContext context) {
    final quick = [
      200,
      300,
      400,
      500,
      600,
      700,
      800,
      900,
      1000,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.trip == null
              ? 'Yeni Yolculuk'
              : 'Yolculuğu Düzenle',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: amount,
            autofocus: false,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onTap: () {
              FocusScope.of(context).requestFocus();
            },
            decoration: const InputDecoration(
              labelText: 'Tutar',
              suffixText: 'TL',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quick.map((v) {
              return SizedBox(
                height: 38,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                    ),
                    side: const BorderSide(
                      color: gold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () =>
                      _quickAmount(v.toDouble()),
                  child: Text(
                    '$v TL',
                    style: const TextStyle(
                      color: dark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ödeme yöntemi',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Nakit',
              'POS',
              'IBAN',
              'Borç',
            ].map((p) {
              final selected = payment == p;

              final Color selectedColor =
                  p == 'Nakit'
                      ? Colors.green
                      : p == 'POS'
                          ? gold
                          : p == 'IBAN'
                              ? Colors.blue
                              : Colors.red;

              return ChoiceChip(
                label: Text(p),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    payment = p;
                  });
                },
                selectedColor: selectedColor,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? (p == 'POS'
                          ? dark
                          : Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          if (payment == 'Borç') ...[
            const SizedBox(height: 18),
            TextField(
              controller: debtor,
              textCapitalization:
                  TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Borçlu adı',
                prefixIcon: Icon(
                  Icons.person_outline,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Not (isteğe bağlı)',
              prefixIcon: Icon(
                Icons.notes_outlined,
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 55,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: _save,
              child: const Text(
                'Kaydet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TripsScreen extends StatefulWidget {
  final List<Trip> trips;
  final VoidCallback onChanged;

  const TripsScreen({
    super.key,
    required this.trips,
    required this.onChanged,
  });

  @override
  State<TripsScreen> createState() =>
      _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late List<Trip> list;

  bool _today(DateTime d) {
    final n = DateTime.now();

    return d.year == n.year &&
        d.month == n.month &&
        d.day == n.day;
  }

  @override
  void initState() {
    super.initState();

    list = widget.trips
        .where((t) => _today(t.createdAt))
        .toList();
  }

  Future<void> _delete(Trip t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Yolculuk silinsin mi?',
          ),
          content: const Text(
            'Bu kayıt kalıcı olarak silinecek.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    widget.trips.removeWhere(
      (x) => x.id == t.id,
    );

    await Storage.saveTrips(
      widget.trips,
    );

    setState(() {
      list = widget.trips
          .where(
            (x) => _today(x.createdAt),
          )
          .toList();
    });

    widget.onChanged();
  }

  Future<void> _edit(Trip t) async {
    final r = await Navigator.push<Trip>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTripScreen(
          trip: t,
        ),
      ),
    );

    if (r == null) return;

    final idx = widget.trips.indexWhere(
      (x) => x.id == r.id,
    );

    if (idx >= 0) {
      widget.trips[idx] = r;
    }

    await Storage.saveTrips(
      widget.trips,
    );

    setState(() {
      list = widget.trips
          .where(
            (x) => _today(x.createdAt),
          )
          .toList();
    });

    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yolculukları düzenle / sil',
        ),
      ),
      body: list.isEmpty
          ? const Center(
              child: Text(
                'Bugün kayıt bulunmuyor.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final t =
                    list[list.length - 1 - i];

                return _tripCard(
                  t,
                  onEdit: () => _edit(t),
                  onDelete: () => _delete(t),
                  showDate: false,
                );
              },
            ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  final List<Trip> trips;
  final VoidCallback onChanged;

  const HistoryScreen({
    super.key,
    required this.trips,
    required this.onChanged,
  });

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState
    extends State<HistoryScreen> {
  DateTime selected = DateTime.now();

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (d != null) {
      setState(() {
        selected = d;
      });
    }
  }

  Future<void> _edit(Trip t) async {
    final r = await Navigator.push<Trip>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTripScreen(
          trip: t,
        ),
      ),
    );

    if (r == null) return;

    final idx = widget.trips.indexWhere(
      (x) => x.id == r.id,
    );

    if (idx >= 0) {
      widget.trips[idx] = r;
    }

    await Storage.saveTrips(
      widget.trips,
    );

    setState(() {});

    widget.onChanged();
  }

  Future<void> _delete(Trip t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(
          'Yolculuk silinsin mi?',
        ),
        content: const Text(
          'Bu kayıt kalıcı olarak silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(c, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(c, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    widget.trips.removeWhere(
      (x) => x.id == t.id,
    );

    await Storage.saveTrips(
      widget.trips,
    );

    setState(() {});

    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final dayTrips = widget.trips
        .where(
          (t) => _sameDay(
            t.createdAt,
            selected,
          ),
        )
        .toList();

    final total = dayTrips.fold(
      0.0,
      (a, b) => a + b.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Geçmiş Kayıtlar',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
            ),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                          .brightness ==
                      Brightness.dark
                  ? const Color(0xFFD9D9D9)
                  : Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: gold,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _sameDay(
                    selected,
                    DateTime.now(),
                  )
                      ? 'Bugün'
                      : _date(selected),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${dayTrips.length} yolculuk • '
                  '${total.toStringAsFixed(2)} TL',
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (dayTrips.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'Bu tarihte kayıt bulunmuyor.',
                ),
              ),
            )
          else
            ...dayTrips.reversed.map(
              (t) => _tripCard(
                t,
                onEdit: () => _edit(t),
                onDelete: () => _delete(t),
                showDate: true,
              ),
            ),
        ],
      ),
    );
  }
  Widget _tripCard(
  Trip t, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required bool showDate,
}) {
  final isDark =
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFFD9D9D9) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: gold),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: gold.withOpacity(.18),
        child: Icon(_paymentIcon(t.payment), color: dark),
      ),
      title: Text(
        '${t.amount.toStringAsFixed(2)} TL • ${t.payment}',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        '${showDate ? '${_date(t.createdAt)} • ' : ''}'
        '${t.debtor != null ? 'Borçlu: ${t.debtor} • ' : ''}'
        '${t.note != null ? 'Not: ${t.note} • ' : ''}'
        '${_time(t.createdAt)}',
        style: const TextStyle(color: Colors.black87),
      ),
      trailing: Wrap(
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    ),
  );
}
}
class DebtsScreen extends StatefulWidget {
  final List<Trip> trips;
  final VoidCallback onChanged;

  const DebtsScreen({
    super.key,
    required this.trips,
    required this.onChanged,
  });

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  late List<Trip> debts;

  bool get isDark =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();

    debts = widget.trips
        .where(
          (t) => t.payment == 'Borç' && !t.paid,
        )
        .toList();
  }

  Future<void> _paid(Trip t) async {
    final idx = widget.trips.indexWhere(
      (x) => x.id == t.id,
    );

    if (idx >= 0) {
      widget.trips[idx].paid = true;
    }

    await Storage.saveTrips(widget.trips);

    setState(() {
      debts = widget.trips
          .where(
            (x) => x.payment == 'Borç' && !x.paid,
          )
          .toList();
    });

    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final total = debts.fold(
      0.0,
      (a, b) => a + b.amount,
    );

    final people = debts
        .map((e) => e.debtor?.trim())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borçlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(
                child: _stat(
                  'Aktif Borç',
                  '${debts.length}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Borçlu',
                  '$people',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Toplam',
                  '${total.toStringAsFixed(2)} TL',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (debts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'Ödenmemiş borç bulunmuyor.',
                ),
              ),
            )
          else
            ...debts.reversed.map(
              (t) => Container(
                margin: const EdgeInsets.only(
                  bottom: 9,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFD9D9D9)
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: gold,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.debtor ??
                                'İsimsiz borç',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${t.amount.toStringAsFixed(2)} TL',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_date(t.createdAt)} • '
                            '${_time(t.createdAt)}',
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                          if (t.note != null)
                            Text(
                              'Not: ${t.note}',
                              style:
                                  const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: dark,
                        foregroundColor: gold,
                      ),
                      onPressed: () => _paid(t),
                      child: const Text(
                        'Ödendi',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFD9D9D9)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: gold,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 1),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
