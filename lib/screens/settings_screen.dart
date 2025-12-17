import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/port_discovery_service.dart';
import '../services/data_persistence_service.dart';
import '../providers/providers.dart';
import '../utils/translations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  late FocusNode _serverFocusNode;
  bool _isTestingConnection = false;
  bool _isDiscoveringPorts = false;
  String? _connectionStatus;
  List<PortInfo> _discoveredPorts = [];
  String? _selectedHost;
  Map<String, int> _cacheInfo = {};

  @override
  void initState() {
    super.initState();
    _serverFocusNode = FocusNode();
    _loadCurrentSettings();
    _loadCacheInfo();
    
    // Automatically focus the server URL field on mobile to show keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MediaQuery.of(context).size.width < 800) { // Mobile check
        _serverFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _serverFocusNode.dispose();
    super.dispose();
  }

  void _loadCurrentSettings() {
    final apiService = ApiService();
    _serverController.text = apiService.baseUrl ?? '';
  }

  Future<void> _loadCacheInfo() async {
    final dataPersistence = DataPersistenceService();
    final info = await dataPersistence.getCacheInfo();
    setState(() {
      _cacheInfo = info;
    });
  }

  Future<void> _discoverPorts() async {
    if (_selectedHost == null || _selectedHost!.isEmpty) {
      setState(() {
        _connectionStatus = '❌ ${AppTranslations.pleaseEnterHost}';
      });
      return;
    }

    setState(() {
      _isDiscoveringPorts = true;
      _discoveredPorts = [];
      _connectionStatus = null;
    });

    try {
      final portDiscovery = PortDiscoveryService();
      final ports = await portDiscovery.discoverPorts(_selectedHost!);
      
      setState(() {
        _discoveredPorts = ports;
        if (ports.isNotEmpty) {
          _connectionStatus = '✅ ${AppTranslations.foundPorts} ${ports.length}';
        } else {
          _connectionStatus = '❌ ${AppTranslations.noPortsFound} $_selectedHost';
        }
      });
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ ${AppTranslations.portDiscoveryFailed}: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isDiscoveringPorts = false;
      });
    }
  }

  Future<void> _autoDiscoverServer() async {
    setState(() {
      _isDiscoveringPorts = true;
      _discoveredPorts = [];
      _connectionStatus = '🔍 ${AppTranslations.autoDiscovering}';
    });

    try {
      final portDiscovery = PortDiscoveryService();
      final discoveredServer = await portDiscovery.autoDiscoverAPIServer();
      
      if (discoveredServer != null) {
        setState(() {
          _serverController.text = discoveredServer.url;
          _connectionStatus = '✅ ${AppTranslations.autoDiscoveredServer}: ${discoveredServer.url}';
        });
      } else {
        setState(() {
          _connectionStatus = '❌ ${AppTranslations.noServerFound}';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ ${AppTranslations.autoDiscoveryFailed}: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isDiscoveringPorts = false;
      });
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final apiService = ApiService();
      await apiService.setBaseUrl(_serverController.text.trim());
      
      print('🔍 Starting connection test from settings screen...');
      final isConnected = await apiService.testConnection();
      
      setState(() {
        if (isConnected) {
          _connectionStatus = '✅ ${AppTranslations.connectionSuccessful}';
        } else {
          _connectionStatus = '❌ ${AppTranslations.connectionFailed}\n\n${AppTranslations.troubleshooting}\n• ${AppTranslations.ensureApiRunning}\n• ${AppTranslations.checkAccessible}\n• ${AppTranslations.verifyCors}\n• ${AppTranslations.tryDirectAccess}';
        }
      });
    } catch (e) {
      print('🚨 Settings screen connection test error: $e');
      setState(() {
        _connectionStatus = '❌ ${AppTranslations.error}: ${e.toString()}\n\n${AppTranslations.errorType}: ${e.runtimeType}\n\n${AppTranslations.thisUsuallyIndicates}\n• ${AppTranslations.networkIssues}\n• ${AppTranslations.corsBlocking}\n• ${AppTranslations.serverNotResponding}\n• ${AppTranslations.invalidUrlFormat}';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final apiService = ApiService();
      await apiService.setBaseUrl(_serverController.text.trim());
      
      // Reload data from the new API
      await _loadDataFromApi();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.settingsSaved),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
              content: Text('${AppTranslations.errorSavingSettings}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
        );
      }
    }
  }

  Future<void> _loadDataFromApi() async {
    try {
      // Load halls, menu, and waiters from the new API with cache fallback
      final hallsNotifier = ref.read(hallsProvider.notifier);
      final menuNotifier = ref.read(menuProvider.notifier);
      final waitersNotifier = ref.read(waitersProvider.notifier);
      
      await Future.wait([
        hallsNotifier.loadHalls(),
        menuNotifier.loadMenu(),
        waitersNotifier.loadWaiters(),
      ]);
      
      print('Data successfully loaded from API');
    } catch (e) {
      print('Failed to load data from API: $e');
      // Data loading errors are non-critical since we have fallback data
    }
  }

  Future<void> _clearCache() async {
    try {
      final dataPersistence = DataPersistenceService();
      await dataPersistence.clearCache();
      
      // Clear providers
      ref.read(hallsProvider.notifier).clearCache();
      ref.read(menuProvider.notifier).clearCache();
      ref.read(waitersProvider.notifier).clearCache();
      
      await _loadCacheInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.cacheCleared),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
              content: Text('${AppTranslations.errorClearingCache}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text(
          AppTranslations.serverSettings,
          style: const TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF000000)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                             Text(
                         AppTranslations.serverConfiguration,
                         style: const TextStyle(
                           fontSize: 20,
                           fontWeight: FontWeight.bold,
                           color: Color(0xFF000000),
                         ),
                       ),
                       const SizedBox(height: 8),
                       Text(
                         AppTranslations.serverConfigurationDescription,
                         style: const TextStyle(
                           fontSize: 14,
                           color: Color(0xFF666666),
                         ),
                       ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _serverController,
                        focusNode: _serverFocusNode,
                        decoration: InputDecoration(
                          labelText: AppTranslations.serverUrl,
                          hintText: AppTranslations.serverUrlHint,
                          prefixIcon: const Icon(Icons.language),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppTranslations.pleaseEnterValue;
                          }
                          
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null || !uri.hasScheme) {
                            return AppTranslations.pleaseEnterValidUrl;
                          }
                          
                          return null;
                        },
                        keyboardType: TextInputType.url,
                        // Enable text selection and cursor
                        enableInteractiveSelection: true,
                        // Show keyboard on tap
                        onTap: () {
                          _serverFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Auto Discovery Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isDiscoveringPorts ? null : _autoDiscoverServer,
                          icon: _isDiscoveringPorts
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
                                  ),
                                )
                              : const Icon(Icons.radar),
                                                     label: Text(_isDiscoveringPorts ? AppTranslations.discovering : AppTranslations.autoDiscoverServer),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: const Color(0xFFFFFFFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Test Connection Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isTestingConnection ? null : _testConnection,
                          icon: _isTestingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
                                  ),
                                )
                              : const Icon(Icons.wifi_tethering),
                                                     label: Text(_isTestingConnection ? AppTranslations.testing : AppTranslations.testConnection),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000000),
                            foregroundColor: const Color(0xFFFFFFFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      
                      // Connection Status
                      if (_connectionStatus != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _connectionStatus!.contains('successful') || _connectionStatus!.contains('✅')
                                ? const Color(0xFFE6F7E6)
                                : const Color(0xFFFFE6E6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _connectionStatus!.contains('successful') || _connectionStatus!.contains('✅')
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFE53E3E),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _connectionStatus!.contains('successful') || _connectionStatus!.contains('✅')
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _connectionStatus!.contains('successful') || _connectionStatus!.contains('✅')
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFE53E3E),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _connectionStatus!,
                                  style: TextStyle(
                                    color: _connectionStatus!.contains('successful') || _connectionStatus!.contains('✅')
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFB71C1C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Port Discovery Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.portDiscovery,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppTranslations.portDiscoverySubDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: AppTranslations.hostAddress,
                          hintText: AppTranslations.hostAddressHint,
                          prefixIcon: const Icon(Icons.computer),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedHost = value.trim();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isDiscoveringPorts ? null : _discoverPorts,
                          icon: _isDiscoveringPorts
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: Text(_isDiscoveringPorts ? AppTranslations.scanning : AppTranslations.discoverPorts),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: const Color(0xFFFFFFFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      
                      // Discovered Ports List
                      if (_discoveredPorts.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          AppTranslations.discoveredPorts,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_discoveredPorts.map((port) => Card(
                          child: ListTile(
                            leading: Icon(
                              port.hasHealthEndpoint ? Icons.check_circle : Icons.info,
                              color: port.hasHealthEndpoint ? Colors.green : Colors.orange,
                            ),
                            title: Text('${AppTranslations.port} ${port.port}'),
                            subtitle: Text(port.hasHealthEndpoint ? AppTranslations.healthEndpointAvailable : AppTranslations.serverResponding),
                            trailing: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _serverController.text = port.url;
                                });
                              },
                              child: Text(AppTranslations.use),
                            ),
                          ),
                        )).toList()),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Cache Management Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.cacheManagement,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppTranslations.cacheManagementSubDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cache Info
                      if (_cacheInfo.isNotEmpty) ...[
                        Text(
                          AppTranslations.cacheSize,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_cacheInfo.entries.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${entry.key}:',
                                style: const TextStyle(color: Color(0xFF666666)),
                              ),
                              Text(
                                '${entry.value} ${AppTranslations.bytes}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                        )).toList()),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _clearCache,
                          icon: const Icon(Icons.clear_all),
                          label: Text(AppTranslations.clearCache),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            foregroundColor: const Color(0xFFFFFFFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000000),
                      foregroundColor: const Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                                         child: Text(
                       AppTranslations.saveSettings,
                       style: const TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Example URLs
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Example URLs:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Local development: http://localhost:3333',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Text(
                        '• Local network: http://192.168.1.100:3333',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Text(
                        '• Production: https://api.restaurant.com',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
