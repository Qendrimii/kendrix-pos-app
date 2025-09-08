import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import '../utils/translations.dart';
import 'settings_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _pin = '';
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeApi();
  }

  Future<void> _initializeApi() async {
    await ApiService().initialize();
  }

  void _onNumberPress(String number) {
    if (_pin.length < 4 && !_isLoading) {
      setState(() {
        _pin += number;
        _errorMessage = null;
      });
      
      if (_pin.length == 4) {
        _validatePin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_isLoading) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onSettingsPress() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  Future<void> _validatePin() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      
      // Try API first if configured, otherwise use local data
      if (apiService.isConfigured) {
        // Try API authentication with PIN
        try {
          final loginResult = await apiService.authenticateWithPin(_pin);
          
          if (loginResult['success'] == true) {
            final userData = loginResult['data'];
            
            // Create a Waiter object from API response - following TechTrek workflow
            final waiter = Waiter(
              id: userData['userPrivId']?.toString() ?? userData['userId']?.toString() ?? '1',
              name: userData['userFirstName'] ?? userData['firstName'] ?? userData['username'] ?? 'User',
              color: Color(int.parse((userData['strUserColor'] ?? userData['color'] ?? '#000000').replaceAll('#', '0xFF'))),
              pin: _pin,
            );
            
            // Update local state
            ref.read(currentUserProvider.notifier).login(waiter);
            
            // Load data from API
            await _loadDataFromApi();
            
            // Navigate to halls screen
            if (mounted) {
              context.go('/halls-tables');
            }
          } else {
            setState(() {
              _errorMessage = AppTranslations.invalidPin;
              _pin = '';
            });
          }
        } catch (apiError) {
          // Fallback to local validation if API fails
          print('API login failed, falling back to local: $apiError');
          _validateLocalLogin();
        }
      } else {
        // Use local validation when API is not configured
        _validateLocalLogin();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${AppTranslations.loginFailed}: ${e.toString()}';
        _pin = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _validateLocalLogin() {
    final waiters = ref.read(waitersProvider);
    final waiter = waiters.where((w) => w.pin == _pin).firstOrNull;
    
    if (waiter != null) {
      ref.read(currentUserProvider.notifier).login(waiter);
      
      // Navigate to halls screen
      if (mounted) {
        context.go('/halls-tables');
      }
    } else {
      setState(() {
        _errorMessage = AppTranslations.invalidPin;
        _pin = '';
      });
    }
  }

  Future<void> _loadDataFromApi() async {
    try {
      // Load halls, menu, waiters from the API with cache fallback
      await Future.wait([
        ref.read(hallsProvider.notifier).loadHalls(),
        ref.read(menuProvider.notifier).loadMenu(),
        ref.read(waitersProvider.notifier).loadWaiters(),
      ]);
      
      print('Data successfully loaded from API during login');
    } catch (e) {
      print('Failed to load data from API during login: $e');
      // Data loading errors are non-critical since we have fallback data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6), // Uber light grey
      body: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 400 : double.infinity,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF), // White background
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SvgPicture.asset(
                      'assets/icons/logo.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(height: 24),
                PinDisplay(pin: _pin),
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF000000)),
                    strokeWidth: 3, // Increased from default 2 to 3
                  ),
                ],
                if (_errorMessage != null && !_isLoading) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFE53E3E), // Uber red for errors
                      fontSize: 18, // Increased from 16 to 18
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                // Number pad
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1, // Decreased from 1.2 to 1.1 for bigger buttons
                    crossAxisSpacing: 20, // Increased from 16 to 20
                    mainAxisSpacing: 20, // Increased from 16 to 20
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      return SettingsButton(onPressed: _onSettingsPress);
                    } else if (index == 10) {
                      return NumberButton(
                        text: '0',
                        onPressed: () => _onNumberPress('0'),
                        enabled: !_isLoading,
                      );
                    } else if (index == 11) {
                      return BackspaceButton(
                        onPressed: _onBackspace,
                        enabled: !_isLoading,
                      );
                    } else {
                      final number = (index + 1).toString();
                      return NumberButton(
                        text: number,
                        onPressed: () => _onNumberPress(number),
                        enabled: !_isLoading,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


