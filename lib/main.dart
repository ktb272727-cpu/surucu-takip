import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const gold = Color(0xFFFFC400);
const dark = Color(0xFF111111);
const bg = Color(0xFFF7F7F7);

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

  Trip({
    required this.id,
    required this.amount,
    required this.payment,
    this.debtor,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'payment': payment,
    'debtor': debtor,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
    id: j['id'],
    amount: (j['amount'] as num).toDouble(),
    payment: j['payment'],
    debtor: j['debtor'],
    note: j['note'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}

class Storage {
  static const tripsKey = 'trips';
  static const driverKey = 'driverName';

  static Future<List<Trip>> loadTrips() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(tripsKey) ?? [];
    return raw.map((x) => Trip.fromJson(jsonDecode(x))).toList();
  }

  static Future<void> saveTrips(List<Trip> trips) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(tripsKey, trips.map((t) => jsonEncode(t.toJson())).toList());
  }

  static Future<String> loadDriver() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(driverKey) ?? 'Sürücü Adı';
  }

  static Future<void> saveDriver(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(driverKey, name);
  }
}

class SurucuTakipApp extends StatelessWidget {
  const SurucuTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sürücü Takip',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.light),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: dark,
          elevation: 0,
          centerTitle: false,
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
            borderSide: const BorderSide(color: gold, width: 2),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/logo.png', width: 230, height: 230),
          const SizedBox(height: 24),
          const Text('Sürücü Takip', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  List<Trip> trips = [];
  String driver = 'Sürücü Adı';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final loaded = await Storage.loadTrips();
    final name = await Storage.loadDriver();
    if (mounted) setState(() { trips = loaded; driver = name; });
  }

  Future<void> _addOrEdit({Trip? trip}) async {
    final result = await Navigator.push<Trip>(
      context,
      MaterialPageRoute(builder: (_) => AddTripScreen(trip: trip)),
    );
    if (result != null) {
      if (trip == null) {
        trips.add(result);
      } else {
        final i = trips.indexWhere((x) => x.id == result.id);
        if (i >= 0) trips[i] = result;
      }
      await Storage.saveTrips(trips);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yolculuk başarıyla kaydedildi'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  Future<void> _openMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _menuTile(Icons.person_outline, 'Sürücü adını değiştir', 'driver'),
          _menuTile(Icons.receipt_long_outlined, 'Yolculukları düzenle / sil', 'trips'),
          _menuTile(Icons.account_balance_wallet_outlined, 'Borçlar', 'debts'),
          _menuTile(Icons.info_outline, 'Hakkında', 'about'),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'driver') {
      final controller = TextEditingController(text: driver == 'Sürücü Adı' ? '' : driver);
      final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(
        title: const Text('Sürücü adı'),
        content: TextField(controller: controller, textCapitalization: TextCapitalization.words, autofocus: true, decoration: const InputDecoration(hintText: 'Adınızı yazın')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Kaydet')),
        ],
      ));
      if (name != null && name.isNotEmpty) {
        await Storage.saveDriver(name);
        setState(() => driver = name);
      }
    } else if (action == 'trips') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => TripsScreen(trips: trips, onChanged: _load)));
      await _load();
    } else if (action == 'debts') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => DebtsScreen(trips: trips, onChanged: _load)));
      await _load();
    } else if (action == 'about') {
      showAboutDialog(context: context, applicationName: 'Sürücü Takip', applicationVersion: '1.0.0', applicationLegalese: 'Taksi yolculuk ve borç takip uygulaması.');
    }
  }

  Widget _menuTile(IconData icon, String title, String value) => ListTile(
    leading: CircleAvatar(backgroundColor: gold.withOpacity(.18), child: Icon(icon, color: dark)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    onTap: () => Navigator.pop(context, value),
  );

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayTrips = trips.where((t) => t.createdAt.year == today.year && t.createdAt.month == today.month && t.createdAt.day == today.day).toList();
    double sum(String p) => todayTrips.where((t) => t.payment == p).fold(0, (a, b) => a + b.amount);
    final total = todayTrips.fold(0.0, (a, b) => a + b.amount);
    final debt = sum('Borç');

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(driver, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          Text(_date(today), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.menu_rounded, size: 30), onPressed: _openMenu)],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                const Icon(Icons.local_taxi_rounded, color: gold, size: 25),
                const SizedBox(width: 10),
                const Text('Toplam Yolculuk:', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${todayTrips.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(height: 14),
            _card('Toplam Kazanç', total, Icons.payments_rounded, large: true),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _card('Nakit', sum('Nakit'), Icons.money_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _card('POS', sum('POS'), Icons.credit_card_rounded)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _card('IBAN', sum('IBAN'), Icons.account_balance_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _card('Borç', debt, Icons.account_balance_wallet_rounded)),
            ]),
            const SizedBox(height: 22),
            const Text('Bugünkü Yolculuklar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (todayTrips.isEmpty)
              _empty()
            else
              ...todayTrips.reversed.take(5).map((t) => _tripPreview(t)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(width: double.infinity, height: 58, child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: dark, foregroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          onPressed: () => _addOrEdit(),
          icon: const Icon(Icons.add_rounded, size: 28),
          label: const Text('Yeni Yolculuk Ekle', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        )),
      ),
    );
  }

  Widget _card(String title, double value, IconData icon, {bool large = false}) => Container(
    padding: EdgeInsets.all(large ? 20 : 15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: gold, size: large ? 28 : 22), const SizedBox(width: 8), Flexible(child: Text(title, style: TextStyle(fontSize: large ? 16 : 13, fontWeight: FontWeight.w700)))]),
      const SizedBox(height: 7),
      Text('${value.toStringAsFixed(2)} TL', style: TextStyle(fontSize: large ? 28 : 19, fontWeight: FontWeight.w900)),
    ]),
  );

  Widget _tripPreview(Trip t) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    elevation: 0,
    child: ListTile(
      leading: CircleAvatar(backgroundColor: gold.withOpacity(.18), child: Icon(_paymentIcon(t.payment), color: dark)),
      title: Text('${t.amount.toStringAsFixed(2)} TL • ${t.payment}', style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('${t.debtor ?? ''}${t.debtor != null ? ' • ' : ''}${_time(t.createdAt)}'),
      trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _addOrEdit(trip: t)),
    ),
  );

  Widget _empty() => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: const Center(child: Text('Henüz yolculuk eklenmedi.')),
  );
}

String _date(DateTime d) => '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';
String _time(DateTime d) => '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
IconData _paymentIcon(String p) => p == 'Nakit' ? Icons.money_rounded : p == 'POS' ? Icons.credit_card_rounded : p == 'IBAN' ? Icons.account_balance_rounded : Icons.account_balance_wallet_rounded;

class AddTripScreen extends StatefulWidget {
  final Trip? trip;
  const AddTripScreen({super.key, this.trip});
  @override State<AddTripScreen> createState() => _AddTripScreenState();
}
class _AddTripScreenState extends State<AddTripScreen> {
  late final TextEditingController amount;
  late final TextEditingController debtor;
  late final TextEditingController note;
  String payment = 'Nakit';

  @override
  void initState() {
    super.initState();
    amount = TextEditingController(text: widget.trip == null ? '' : widget.trip!.amount.toStringAsFixed(2));
    debtor = TextEditingController(text: widget.trip?.debtor ?? '');
    note = TextEditingController(text: widget.trip?.note ?? '');
    payment = widget.trip?.payment ?? 'Nakit';
  }
  @override void dispose() { amount.dispose(); debtor.dispose(); note.dispose(); super.dispose(); }

  Future<void> _save() async {
    final value = double.tryParse(amount.text.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçerli bir tutar girin.')));
      return;
    }
    if (payment == 'Borç' && debtor.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Borçlu adını girin.')));
      return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Kaydı onaylıyor musunuz?'),
      content: Text('Tutar: ${value.toStringAsFixed(2)} TL\nÖdeme: $payment${payment == 'Borç' ? '\nBorçlu: ${debtor.text.trim()}' : ''}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal Et')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Onayla')),
      ],
    ));
    if (confirmed == true && mounted) {
      Navigator.pop(context, Trip(
        id: widget.trip?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        amount: value,
        payment: payment,
        debtor: payment == 'Borç' ? debtor.text.trim() : null,
        note: note.text.trim().isEmpty ? null : note.text.trim(),
        createdAt: widget.trip?.createdAt ?? DateTime.now(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.trip == null ? 'Yeni Yolculuk' : 'Yolculuğu Düzenle')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      TextField(
        controller: amount,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Tutar', suffixText: 'TL', prefixIcon: Icon(Icons.payments_outlined)),
      ),
      const SizedBox(height: 18),
      const Text('Ödeme yöntemi', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: ['Nakit','POS','IBAN','Borç'].map((p) => ChoiceChip(
        label: Text(p), selected: payment == p, onSelected: (_) => setState(() => payment = p),
        selectedColor: gold, labelStyle: TextStyle(fontWeight: FontWeight.w700, color: payment == p ? dark : null),
      )).toList()),
      if (payment == 'Borç') ...[
        const SizedBox(height: 18),
        TextField(controller: debtor, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Borçlu adı', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Not (isteğe bağlı)', prefixIcon: Icon(Icons.notes_outlined))),
      ],
      if (payment != 'Borç') ...[
        const SizedBox(height: 18),
        TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Not (isteğe bağlı)', prefixIcon: Icon(Icons.notes_outlined))),
      ],
      const SizedBox(height: 28),
      SizedBox(height: 55, child: FilledButton(onPressed: _save, child: const Text('Kaydet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))),
    ]),
  );
}

class TripsScreen extends StatefulWidget {
  final List<Trip> trips;
  final VoidCallback onChanged;
  const TripsScreen({super.key, required this.trips, required this.onChanged});
  @override State<TripsScreen> createState() => _TripsScreenState();
}
class _TripsScreenState extends State<TripsScreen> {
  late List<Trip> list;
  @override void initState() { super.initState(); list = [...widget.trips]; }

  Future<void> _delete(Trip t) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Yolculuk silinsin mi?'),
      content: const Text('Bu kayıt kalıcı olarak silinecek.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil'))],
    ));
    if (ok == true) {
      list.removeWhere((x) => x.id == t.id);
      await Storage.saveTrips(list);
      setState(() {});
      widget.onChanged();
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yolculuklar')),
    body: list.isEmpty ? const Center(child: Text('Kayıt bulunmuyor.')) : ListView.builder(
      padding: const EdgeInsets.all(12), itemCount: list.length, itemBuilder: (_, i) {
        final t = list[list.length - 1 - i];
        return Card(elevation: 0, child: ListTile(
          title: Text('${t.amount.toStringAsFixed(2)} TL • ${t.payment}', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${_date(t.createdAt)} ${_time(t.createdAt)}${t.debtor != null ? '\nBorçlu: ${t.debtor}' : ''}${t.note != null ? '\nNot: ${t.note}' : ''}'),
          isThreeLine: t.debtor != null || t.note != null,
          trailing: Wrap(children: [
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () async {
              final r = await Navigator.push<Trip>(context, MaterialPageRoute(builder: (_) => AddTripScreen(trip: t)));
              if (r != null) { final idx = list.indexWhere((x) => x.id == r.id); if (idx >= 0) list[idx] = r; await Storage.saveTrips(list); setState(() {}); widget.onChanged(); }
            }),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(t)),
          ]),
        ));
      },
    ),
  );
}

class DebtsScreen extends StatefulWidget {
  final List<Trip> trips;
  final VoidCallback onChanged;
  const DebtsScreen({super.key, required this.trips, required this.onChanged});
  @override State<DebtsScreen> createState() => _DebtsScreenState();
}
class _DebtsScreenState extends State<DebtsScreen> {
  late List<Trip> debts;
  @override void initState() { super.initState(); debts = widget.trips.where((t) => t.payment == 'Borç').toList(); }

  Future<void> _paid(Trip t) async {
    debts.removeWhere((x) => x.id == t.id);
    widget.trips.removeWhere((x) => x.id == t.id);
    await Storage.saveTrips(widget.trips);
    setState(() {});
    widget.onChanged();
  }

  @override Widget build(BuildContext context) {
    final total = debts.fold(0.0, (a,b) => a+b.amount);
    final people = debts.map((e) => e.debtor?.trim()).whereType<String>().where((e)=>e.isNotEmpty).toSet().length;
    return Scaffold(
      appBar: AppBar(title: const Text('Borçlar')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Row(children: [
          Expanded(child: _stat('Aktif Borç', '${debts.length}')),
          const SizedBox(width: 10),
          Expanded(child: _stat('Borçlu', '$people')),
          const SizedBox(width: 10),
          Expanded(child: _stat('Toplam', '${total.toStringAsFixed(2)} TL')),
        ]),
        const SizedBox(height: 14),
        if (debts.isEmpty)
          const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Ödenmemiş borç bulunmuyor.')))
        else
          ...debts.reversed.map((t) => Card(
            elevation: 0, margin: const EdgeInsets.only(bottom: 9),
            child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.debtor ?? 'İsimsiz borç', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${t.amount.toStringAsFixed(2)} TL', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${_date(t.createdAt)} • ${_time(t.createdAt)}'),
                if (t.note != null) Text('Not: ${t.note}'),
              ])),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: dark, foregroundColor: gold),
                onPressed: () => _paid(t),
                child: const Text('Ödendi', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ])),
          )),
      ]),
    );
  }

  Widget _stat(String title, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Column(children: [Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))]),
  );
}
