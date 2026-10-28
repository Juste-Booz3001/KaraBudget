import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../core/l10n_ext.dart';
import '../providers.dart';
import 'common.dart';

/// Hachage du code PIN : SHA-256 itéré avec un sel aléatoire (le PIN n'est jamais stocké en clair).
String hashPin(String pin, String salt) {
  var digest = sha256.convert(utf8.encode('$salt:$pin')).bytes;
  final saltBytes = utf8.encode(salt);
  for (var i = 0; i < 20000; i++) {
    digest = sha256.convert([...digest, ...saltBytes]).bytes;
  }
  return base64Encode(digest);
}

class LockState {
  const LockState({required this.enabled, required this.locked, required this.biometric, this.failures = 0, this.blockedUntil});
  final bool enabled, locked, biometric;
  final int failures;
  final DateTime? blockedUntil;

  LockState copyWith({bool? enabled, bool? locked, bool? biometric, int? failures, DateTime? blockedUntil, bool clearBlock = false}) => LockState(
        enabled: enabled ?? this.enabled,
        locked: locked ?? this.locked,
        biometric: biometric ?? this.biometric,
        failures: failures ?? this.failures,
        blockedUntil: clearBlock ? null : (blockedUntil ?? this.blockedUntil),
      );
}

class LockController extends Notifier<LockState> {
  static const graceSeconds = 30; // temps passé en arrière-plan avant de reverrouiller
  bool busy = false; // demande biométrique en cours : ne pas reverrouiller pendant ce temps

  @override
  LockState build() {
    final p = ref.read(prefsProvider);
    final enabled = p.getString('lock_hash') != null;
    return LockState(enabled: enabled, locked: enabled, biometric: p.getBool('lock_bio') ?? false);
  }

  bool verify(String pin) {
    final p = ref.read(prefsProvider);
    final until = state.blockedUntil;
    if (until != null && until.isAfter(DateTime.now())) return false;
    final ok = hashPin(pin, p.getString('lock_salt') ?? '') == p.getString('lock_hash');
    if (ok) {
      state = state.copyWith(locked: false, failures: 0, clearBlock: true);
    } else {
      final f = state.failures + 1;
      state = state.copyWith(failures: f, blockedUntil: f >= 5 ? DateTime.now().add(const Duration(seconds: 30)) : null, clearBlock: f < 5);
      if (f >= 5) state = state.copyWith(failures: 0);
    }
    return ok;
  }

  bool check(String pin) {
    final p = ref.read(prefsProvider);
    return hashPin(pin, p.getString('lock_salt') ?? '') == p.getString('lock_hash');
  }

  Future<void> setPin(String pin) async {
    final p = ref.read(prefsProvider);
    final salt = base64Encode(List.generate(16, (_) => Random.secure().nextInt(256)));
    await p.setString('lock_salt', salt);
    await p.setString('lock_hash', hashPin(pin, salt));
    state = state.copyWith(enabled: true, locked: false, failures: 0, clearBlock: true);
  }

  Future<void> disable() async {
    final p = ref.read(prefsProvider);
    await p.remove('lock_hash');
    await p.remove('lock_salt');
    await p.remove('lock_bio');
    state = const LockState(enabled: false, locked: false, biometric: false);
  }

  Future<void> setBiometric(bool v) async {
    await ref.read(prefsProvider).setBool('lock_bio', v);
    state = state.copyWith(biometric: v);
  }

  void lockNow() {
    if (state.enabled && !busy) state = state.copyWith(locked: true);
  }

  static bool get biometricsPossible => Platform.isAndroid || Platform.isIOS;

  Future<bool> biometricAvailable() async {
    if (!biometricsPossible) return false;
    try {
      final auth = LocalAuthentication();
      return await auth.isDeviceSupported() && await auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> tryBiometric(String reason) async {
    if (!state.enabled || !state.biometric || !await biometricAvailable()) return false;
    busy = true;
    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (ok) state = state.copyWith(locked: false, failures: 0, clearBlock: true);
      return ok;
    } catch (_) {
      return false;
    } finally {
      busy = false;
    }
  }
}

final lockProvider = NotifierProvider<LockController, LockState>(LockController.new);

/// Pose l'écran de verrouillage par-dessus toute l'application (placé dans MaterialApp.builder).
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AppLockGate> createState() => _GateState();
}

class _GateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) _pausedAt = DateTime.now();
    if (s == AppLifecycleState.resumed && _pausedAt != null) {
      final away = DateTime.now().difference(_pausedAt!).inSeconds;
      _pausedAt = null;
      if (away >= LockController.graceSeconds) ref.read(lockProvider.notifier).lockNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(lockProvider.select((s) => s.locked));
    return Stack(children: [
      widget.child,
      if (locked) const Positioned.fill(child: LockScreen()),
    ]);
  }
}

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _biometric() async {
    if (!mounted) return;
    await ref.read(lockProvider.notifier).tryBiometric(context.t.unlockReason);
  }

  void _submit() {
    final ctrl = ref.read(lockProvider.notifier);
    final blocked = ref.read(lockProvider).blockedUntil;
    if (blocked != null && blocked.isAfter(DateTime.now())) {
      setState(() => _error = context.t.tooManyAttempts);
      return;
    }
    if (!ctrl.verify(_pin.text)) {
      setState(() {
        _error = ref.read(lockProvider).blockedUntil != null ? context.t.tooManyAttempts : context.t.wrongPin;
        _pin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final bio = ref.watch(lockProvider.select((s) => s.biometric));
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 16),
              Text(t.appLocked, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              TextField(
                controller: _pin,
                autofocus: true,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: InputDecoration(hintText: t.enterPin, errorText: _error),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _submit, child: Text(t.unlock)),
              if (bio) TextButton.icon(onPressed: _biometric, icon: const Icon(Icons.fingerprint), label: Text(t.useBiometrics)),
            ]),
          ),
        ),
      ),
    );
  }
}

Future<String?> askPin(BuildContext context, String title) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
        decoration: InputDecoration(hintText: ctx.t.pinHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(ctx.t.ok)),
      ],
    ),
  );
}

/// Active, change ou désactive le verrouillage (écran de réglages).
class LockSettingsTiles extends ConsumerWidget {
  const LockSettingsTiles({super.key});

  Future<void> _setNewPin(BuildContext context, WidgetRef ref) async {
    final first = await askPin(context, context.t.choosePin);
    if (first == null || !context.mounted) return;
    if (first.length < 4) return snack(context, context.t.pinTooShort);
    final second = await askPin(context, context.t.confirmPin);
    if (second == null || !context.mounted) return;
    if (second != first) return snack(context, context.t.pinMismatch);
    await ref.read(lockProvider.notifier).setPin(first);
    if (context.mounted) snack(context, context.t.lockEnabled);
  }

  Future<bool> _verifyCurrent(BuildContext context, WidgetRef ref) async {
    final pin = await askPin(context, context.t.enterCurrentPin);
    if (pin == null) return false;
    final ok = ref.read(lockProvider.notifier).check(pin);
    if (!ok && context.mounted) snack(context, context.t.wrongPin);
    return ok;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final lock = ref.watch(lockProvider);
    if (!lock.enabled) {
      return ListTile(
        leading: const Icon(Icons.lock_outline),
        title: Text(t.enableAppLock),
        subtitle: Text(t.appLockHelp),
        onTap: () => _setNewPin(context, ref),
      );
    }
    return Column(children: [
      ListTile(
        leading: const Icon(Icons.pin),
        title: Text(t.changePin),
        onTap: () async {
          if (await _verifyCurrent(context, ref) && context.mounted) await _setNewPin(context, ref);
        },
      ),
      FutureBuilder<bool>(
        future: ref.read(lockProvider.notifier).biometricAvailable(),
        builder: (ctx, snap) => snap.data == true
            ? SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: Text(t.useBiometrics),
                value: lock.biometric,
                onChanged: (v) => ref.read(lockProvider.notifier).setBiometric(v),
              )
            : const SizedBox.shrink(),
      ),
      ListTile(
        leading: const Icon(Icons.lock_open),
        title: Text(t.disableAppLock),
        onTap: () async {
          if (await _verifyCurrent(context, ref)) await ref.read(lockProvider.notifier).disable();
        },
      ),
    ]);
  }
}
