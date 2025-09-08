import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class PortDiscoveryService {
  static final PortDiscoveryService _instance = PortDiscoveryService._internal();
  factory PortDiscoveryService() => _instance;
  PortDiscoveryService._internal();

  // Common ports for API servers
  static const List<int> _commonPorts = [
    3000, 3001, 3002, 3003, 3004, 3005, 3006, 3007, 3008, 3009,
    3333, 3334, 3335, 3336, 3337, 3338, 3339,
    5000, 5001, 5002, 5003, 5004, 5005, 5006, 5007, 5008, 5009,
    8000, 8001, 8002, 8003, 8004, 8005, 8006, 8007, 8008, 8009,
    8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088, 8089,
    9000, 9001, 9002, 9003, 9004, 9005, 9006, 9007, 9008, 9009,
  ];

  // Discover available ports for a given host
  Future<List<PortInfo>> discoverPorts(String host, {int timeoutSeconds = 3}) async {
    final List<PortInfo> availablePorts = [];
    final timeout = Duration(seconds: timeoutSeconds);
    
    print('🔍 Starting port discovery for host: $host');
    
    // Test common ports
    final futures = _commonPorts.map((port) => _testPort(host, port, timeout));
    
    // Wait for all tests to complete
    final results = await Future.wait(futures);
    
    for (final result in results) {
      if (result != null) {
        availablePorts.add(result);
      }
    }
    
    // Sort by port number
    availablePorts.sort((a, b) => a.port.compareTo(b.port));
    
    print('✅ Port discovery completed. Found ${availablePorts.length} available ports');
    return availablePorts;
  }

  // Test a specific port
  Future<PortInfo?> _testPort(String host, int port, Duration timeout) async {
    try {
      final url = 'http://$host:$port/health';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        print('✅ Port $port is available (health endpoint)');
        return PortInfo(
          host: host,
          port: port,
          url: 'http://$host:$port',
          hasHealthEndpoint: true,
          responseTime: 0, // Could be measured if needed
        );
      } else if (response.statusCode < 500) {
        // Server responded but health endpoint might not exist
        print('⚠️ Port $port responded with status ${response.statusCode}');
        return PortInfo(
          host: host,
          port: port,
          url: 'http://$host:$port',
          hasHealthEndpoint: false,
          responseTime: 0,
        );
      }
    } catch (e) {
      // Try alternative endpoints if health fails
      try {
        final alternativeUrls = [
          'http://$host:$port/api/info',
          'http://$host:$port/api',
          'http://$host:$port/',
        ];
        
        for (final altUrl in alternativeUrls) {
          try {
            final response = await http.get(
              Uri.parse(altUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ).timeout(timeout);
            
            if (response.statusCode < 500) {
              print('✅ Port $port is available (alternative endpoint: ${altUrl.split('/').last})');
              return PortInfo(
                host: host,
                port: port,
                url: 'http://$host:$port',
                hasHealthEndpoint: false,
                responseTime: 0,
              );
            }
          } catch (e) {
            // Continue to next alternative URL
            continue;
          }
        }
      } catch (e) {
        // All alternative endpoints failed
      }
    }
    
    return null;
  }

  // Get local network IP addresses
  Future<List<String>> getLocalNetworkIPs() async {
    final List<String> ips = [];
    
    try {
      // Add common localhost variants
      ips.addAll(['localhost', '127.0.0.1', '0.0.0.0']);
      
      // Get network interfaces
      final interfaces = await NetworkInterface.list();
      
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;
            // Filter out loopback and link-local addresses
            if (!ip.startsWith('127.') && 
                !ip.startsWith('169.254.') && 
                !ip.startsWith('::1')) {
              ips.add(ip);
            }
          }
        }
      }
    } catch (e) {
      print('Error getting network interfaces: $e');
    }
    
    // Remove duplicates and sort
    final uniqueIPs = ips.toSet().toList();
    uniqueIPs.sort();
    
    return uniqueIPs;
  }

  // Auto-discover API server
  Future<PortInfo?> autoDiscoverAPIServer() async {
    print('🚀 Starting auto-discovery of API server...');
    
    final localIPs = await getLocalNetworkIPs();
    print('📡 Found local IPs: $localIPs');
    
    for (final ip in localIPs) {
      print('🔍 Scanning IP: $ip');
      final ports = await discoverPorts(ip, timeoutSeconds: 2);
      
      if (ports.isNotEmpty) {
        // Return the first available port with health endpoint, or any available port
        final preferredPort = ports.firstWhere(
          (port) => port.hasHealthEndpoint,
          orElse: () => ports.first,
        );
        
        print('🎯 Auto-discovered API server: ${preferredPort.url}');
        return preferredPort;
      }
    }
    
    print('❌ No API server found during auto-discovery');
    return null;
  }

  // Test if a specific URL is reachable
  Future<bool> testURL(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode < 500;
    } catch (e) {
      return false;
    }
  }
}

class PortInfo {
  final String host;
  final int port;
  final String url;
  final bool hasHealthEndpoint;
  final int responseTime;

  PortInfo({
    required this.host,
    required this.port,
    required this.url,
    required this.hasHealthEndpoint,
    required this.responseTime,
  });

  @override
  String toString() {
    return 'PortInfo(host: $host, port: $port, url: $url, hasHealth: $hasHealthEndpoint)';
  }
}
