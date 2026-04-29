import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  void _showHelpDialog() {
    final isConfigured = ApiService().isConfigured;
    final currentUrl = ApiService().baseUrl ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Informacion',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Connection status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConfigured ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isConfigured ? Icons.check_circle : Icons.warning_amber,
                          size: 20,
                          color: isConfigured ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConfigured ? 'Serveri: I lidhur' : 'Serveri: I pa-konfiguruar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isConfigured ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    if (isConfigured) ...[
                      const SizedBox(height: 4),
                      Text(
                        currentUrl,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // PIN info
              const Text(
                'PIN per hyrje:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (isConfigured)
                const Text(
                  'Perdorni PIN-in qe ju ka dhene administratori.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF444444)),
                )
              else ...[
                const Text(
                  'Pa server, mund te perdorni keto PIN:',
                  style: TextStyle(fontSize: 14, color: Color(0xFF444444)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pinChip('1111', 'Alice'),
                    _pinChip('2222', 'Bob'),
                    _pinChip('3333', 'Charlie'),
                    _pinChip('4444', 'Diana'),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Use test server button
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final apiService = ApiService();
                    await apiService.setBaseUrl('https://rest.kendrix.org');
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test server u konfigurua: rest.kendrix.org'),
                          backgroundColor: Color(0xFF2E7D32),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.science, size: 18),
                  label: const Text('Perdor Test Server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (!isConfigured) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.settings, size: 16, color: Color(0xFF666666)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ose shtypni butonin e cilësimeve (⚙) per server tjeter.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pinChip(String pin, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        '$pin ($name)',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
        ),
      ),
    );
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
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/app-icon.png',
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Connection status & help
                GestureDetector(
                  onTap: _showHelpDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ApiService().isConfigured
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ApiService().isConfigured
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ApiService().isConfigured ? Icons.cloud_done : Icons.cloud_off,
                          size: 16,
                          color: ApiService().isConfigured
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            ApiService().isConfigured
                                ? 'Server i lidhur'
                                : 'Pa server',
                            style: TextStyle(
                              fontSize: 12,
                              color: ApiService().isConfigured
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.help_outline,
                          size: 14,
                          color: ApiService().isConfigured
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                        ),
                      ],
                    ),
                  ),
                ),
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


