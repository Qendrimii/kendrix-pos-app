# Restaurant POS System

A modern, mobile-first Point of Sale (POS) system built with Flutter for restaurants and food service businesses.

## Features

### Core POS Features
- **Table Management**: Manage restaurant tables and their status
- **Order Processing**: Create and manage orders with real-time updates
- **Menu Management**: Comprehensive menu system with categories and pricing
- **Payment Processing**: Multiple payment methods support
- **Waiter Management**: Assign waiters to tables and track orders
- **Receipt Printing**: Print kitchen orders and customer receipts

### Network & Connectivity
- **HTTP/HTTPS Support**: Communicate with both HTTP and HTTPS servers
- **Auto-Discovery**: Automatically discover API servers on your local network
- **Port Scanning**: Scan for available ports on specific hosts
- **Offline Mode**: Continue working with cached data when server is unavailable

### Data Persistence
- **Local Caching**: All server data is cached locally for offline access
- **Automatic Sync**: Data syncs when connection is restored
- **Cache Management**: View and clear cached data through settings
- **Persistent Settings**: Server configuration is saved between app sessions

## Getting Started

### Prerequisites
- Flutter SDK (3.4.4 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd res_pos
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Configuration

### Server Setup

1. **Manual Configuration**:
   - Open the app and go to Settings
   - Enter your API server URL (e.g., `http://localhost:3333`)
   - Test the connection

2. **Auto-Discovery**:
   - In Settings, tap "Auto-Discover Server"
   - The app will scan your local network for API servers
   - Select the discovered server

3. **Port Discovery**:
   - Enter a host address (e.g., `192.168.1.100`)
   - Tap "Discover Ports" to scan for available ports
   - Select a port from the discovered list

### Network Security

The app is configured to allow HTTP traffic for development and local networks:

#### Android
- Network security config allows HTTP traffic
- Cleartext traffic is permitted for local development

#### iOS
- App Transport Security allows arbitrary loads
- HTTP exceptions for localhost and local networks

## Architecture

### Services
- **ApiService**: Main API communication service
- **DataPersistenceService**: Local data caching and persistence
- **PortDiscoveryService**: Network discovery and port scanning
- **AuthService**: Authentication and user management
- **HallsService**: Table and hall management
- **MenuService**: Menu and product management
- **OrdersService**: Order processing and management
- **PaymentService**: Payment processing

### State Management
- **Riverpod**: State management with providers
- **Cached Data**: Automatic fallback to cached data when offline
- **Real-time Updates**: Live updates when connected to server

### Data Flow
1. App starts and loads cached data
2. Attempts to connect to API server
3. Syncs fresh data if connection successful
4. Continues working with cached data if offline
5. Automatically syncs when connection restored

## Development

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── providers/                # State management
├── screens/                  # UI screens
├── services/                 # Business logic
├── utils/                    # Utilities
└── widgets/                  # Reusable components
```

### Key Files
- `lib/services/data_persistence_service.dart`: Local data caching
- `lib/services/port_discovery_service.dart`: Network discovery
- `lib/screens/settings_screen.dart`: Server configuration UI
- `lib/providers/`: State management with caching

### Adding New Features

1. **Data Models**: Add to `lib/models/`
2. **API Integration**: Add to appropriate service in `lib/services/`
3. **State Management**: Add provider in `lib/providers/`
4. **UI Components**: Add to `lib/screens/` or `lib/widgets/`

## Troubleshooting

### Connection Issues
1. Check if API server is running
2. Verify server URL in settings
3. Use auto-discovery to find server
4. Check network connectivity
5. Verify CORS settings on server

### Data Issues
1. Clear cache in settings if data is stale
2. Check last sync timestamp
3. Force refresh by reconnecting to server
4. Verify API endpoints are working

### Port Discovery Issues
1. Ensure server is running on common ports
2. Check firewall settings
3. Verify network connectivity
4. Try manual port configuration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the configuration guide
