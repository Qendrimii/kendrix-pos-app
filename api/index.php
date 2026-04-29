<?php
/**
 * Kendrix POS - Mock API for App Store Review
 * Single-file PHP API with file-based storage.
 * No database, no Composer, no external dependencies.
 * Requires PHP 7.4+ with Apache mod_rewrite or PHP built-in server.
 *
 * Local testing:  php -S localhost:8080 index.php
 */

// ─── CORS ────────────────────────────────────────────────────────────────────
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────
function jsonResponse($data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

function readBody(): array {
    $raw = file_get_contents('php://input');
    return $raw ? (json_decode($raw, true) ?? []) : [];
}

function dataDir(): string {
    $dir = __DIR__ . '/data';
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
    return $dir;
}

function tableFile(string $tableId): string {
    return dataDir() . '/table_' . preg_replace('/[^a-zA-Z0-9_-]/', '_', $tableId) . '.json';
}

function readTableData(string $tableId): array {
    $file = tableFile($tableId);
    if (file_exists($file)) {
        $data = json_decode(file_get_contents($file), true);
        return is_array($data) ? $data : ['temp' => [], 'orders' => [], 'nextId' => 1];
    }
    return ['temp' => [], 'orders' => [], 'nextId' => 1];
}

function writeTableData(string $tableId, array $data): void {
    file_put_contents(tableFile($tableId), json_encode($data, JSON_PRETTY_PRINT));
}

// ─── MOCK DATA ───────────────────────────────────────────────────────────────
function getProducts(): array {
    return [
        ['id' => 1,  'name' => 'Espresso',          'price' => 1.50, 'categoryId' => 1, 'categoryName' => 'Drinks',     'isAvailable' => true, 'isActive' => true, 'description' => 'Single shot espresso'],
        ['id' => 2,  'name' => 'Cappuccino',         'price' => 2.50, 'categoryId' => 1, 'categoryName' => 'Drinks',     'isAvailable' => true, 'isActive' => true, 'description' => 'Espresso with steamed milk'],
        ['id' => 3,  'name' => 'Latte',              'price' => 2.80, 'categoryId' => 1, 'categoryName' => 'Drinks',     'isAvailable' => true, 'isActive' => true, 'description' => 'Espresso with lots of milk'],
        ['id' => 4,  'name' => 'Coca Cola',          'price' => 2.00, 'categoryId' => 1, 'categoryName' => 'Drinks',     'isAvailable' => true, 'isActive' => true, 'description' => '330ml can'],
        ['id' => 5,  'name' => 'Fresh Orange Juice', 'price' => 3.00, 'categoryId' => 1, 'categoryName' => 'Drinks',     'isAvailable' => true, 'isActive' => true, 'description' => 'Freshly squeezed'],
        ['id' => 6,  'name' => 'Water',              'price' => 1.00, 'categoryId' => 1, 'categoryName' => 'Drinks',     'isAvailable' => true, 'isActive' => true, 'description' => '500ml bottle'],
        ['id' => 7,  'name' => 'Margherita Pizza',   'price' => 7.50, 'categoryId' => 2, 'categoryName' => 'Food',       'isAvailable' => true, 'isActive' => true, 'description' => 'Classic tomato and mozzarella'],
        ['id' => 8,  'name' => 'Cheeseburger',       'price' => 6.00, 'categoryId' => 2, 'categoryName' => 'Food',       'isAvailable' => true, 'isActive' => true, 'description' => 'Beef patty with cheese'],
        ['id' => 9,  'name' => 'Caesar Salad',       'price' => 5.50, 'categoryId' => 2, 'categoryName' => 'Food',       'isAvailable' => true, 'isActive' => true, 'description' => 'Romaine lettuce, croutons, parmesan'],
        ['id' => 10, 'name' => 'Grilled Chicken',    'price' => 8.00, 'categoryId' => 2, 'categoryName' => 'Food',       'isAvailable' => true, 'isActive' => true, 'description' => 'With roasted vegetables'],
        ['id' => 11, 'name' => 'Pasta Carbonara',    'price' => 7.00, 'categoryId' => 2, 'categoryName' => 'Food',       'isAvailable' => true, 'isActive' => true, 'description' => 'Spaghetti with bacon and egg sauce'],
        ['id' => 12, 'name' => 'Fish & Chips',       'price' => 8.50, 'categoryId' => 2, 'categoryName' => 'Food',       'isAvailable' => true, 'isActive' => true, 'description' => 'Battered cod with fries'],
        ['id' => 13, 'name' => 'Tiramisu',           'price' => 4.00, 'categoryId' => 3, 'categoryName' => 'Desserts',   'isAvailable' => true, 'isActive' => true, 'description' => 'Classic Italian dessert'],
        ['id' => 14, 'name' => 'Cheesecake',         'price' => 4.50, 'categoryId' => 3, 'categoryName' => 'Desserts',   'isAvailable' => true, 'isActive' => true, 'description' => 'New York style'],
        ['id' => 15, 'name' => 'Ice Cream',          'price' => 3.00, 'categoryId' => 3, 'categoryName' => 'Desserts',   'isAvailable' => true, 'isActive' => true, 'description' => 'Three scoops'],
        ['id' => 16, 'name' => 'Bruschetta',         'price' => 4.00, 'categoryId' => 4, 'categoryName' => 'Appetizers', 'isAvailable' => true, 'isActive' => true, 'description' => 'Toasted bread with tomatoes'],
        ['id' => 17, 'name' => 'Garlic Bread',       'price' => 3.00, 'categoryId' => 4, 'categoryName' => 'Appetizers', 'isAvailable' => true, 'isActive' => true, 'description' => 'With herb butter'],
        ['id' => 18, 'name' => 'Mozzarella Sticks',  'price' => 4.50, 'categoryId' => 4, 'categoryName' => 'Appetizers', 'isAvailable' => true, 'isActive' => true, 'description' => 'Deep fried with marinara'],
    ];
}

function getCategories(): array {
    return [
        ['id' => 1, 'name' => 'Drinks'],
        ['id' => 2, 'name' => 'Food'],
        ['id' => 3, 'name' => 'Desserts'],
        ['id' => 4, 'name' => 'Appetizers'],
    ];
}

function getHalls(): array {
    return [
        [
            'id' => 1,
            'name' => 'Main Hall',
            'tables' => [
                ['id' => '1', 'name' => 'Table 1', 'status' => 'free', 'waiterId' => null, 'waiterName' => null, 'total' => 0.0],
                ['id' => '2', 'name' => 'Table 2', 'status' => 'free', 'waiterId' => null, 'waiterName' => null, 'total' => 0.0],
                ['id' => '3', 'name' => 'Table 3', 'status' => 'free', 'waiterId' => null, 'waiterName' => null, 'total' => 0.0],
                ['id' => '4', 'name' => 'Table 4', 'status' => 'free', 'waiterId' => null, 'waiterName' => null, 'total' => 0.0],
                ['id' => '5', 'name' => 'Table 5', 'status' => 'free', 'waiterId' => null, 'waiterName' => null, 'total' => 0.0],
            ],
        ],
        [
            'id' => 2,
            'name' => 'Terrace',
            'tables' => [
                ['id' => '6', 'name' => 'Table 6', 'status' => 'free', 'waiterId' => null, 'waiterName' => null, 'total' => 0.0],
                ['id' => '7', 'name' => 'Table 7', 'status' => 'free', 'waiterId' => null, 'waiterName' => null, 'total' => 0.0],
                ['id' => '8', 'name' => 'Table 8', 'status' => 'free', 'waiterId' => null, 'waiterName' => null, 'total' => 0.0],
                ['id' => '9', 'name' => 'Table 9', 'status' => 'free', 'waiterId' => null, 'waiterName' => null, 'total' => 0.0],
            ],
        ],
    ];
}

function getPaymentMethods(): array {
    return [
        ['id' => 1, 'name' => 'Cash',   'code' => 'CASH'],
        ['id' => 2, 'name' => 'Card',   'code' => 'CARD'],
        ['id' => 3, 'name' => 'Online', 'code' => 'ONLINE'],
    ];
}

function findProduct(int $productId): ?array {
    foreach (getProducts() as $p) {
        if ($p['id'] === $productId) return $p;
    }
    return null;
}

// ─── ROUTING ─────────────────────────────────────────────────────────────────
$method = $_SERVER['REQUEST_METHOD'];
$uri    = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Strip leading /index.php if PHP built-in server rewrites to it
$uri = preg_replace('#^/index\.php#', '', $uri);
// Normalise slashes
$uri = '/' . trim($uri, '/');

// Simple pattern matching with {param} support
function matchRoute(string $pattern, string $uri, array &$params): bool {
    // Convert {param} to named regex groups
    $regex = preg_replace_callback('/\{(\w+)\}/', function ($m) {
        return '(?P<' . $m[1] . '>[^/]+)';
    }, $pattern);
    $regex = '#^' . $regex . '$#i';
    if (preg_match($regex, $uri, $matches)) {
        foreach ($matches as $k => $v) {
            if (is_string($k)) $params[$k] = $v;
        }
        return true;
    }
    return false;
}

$params = [];

// ─── ENDPOINTS ───────────────────────────────────────────────────────────────

// Health check
if ($method === 'GET' && ($uri === '/health' || $uri === '/')) {
    jsonResponse(['status' => 'healthy']);
}

// API info
if ($method === 'GET' && $uri === '/api/info') {
    jsonResponse(['version' => '1.0', 'name' => 'Kendrix POS API']);
}

// ── Auth ──────────────────────────────────────────────────────────────────────
if ($method === 'POST' && matchRoute('/api/Login/login', $uri, $params)) {
    $body = readBody();
    $pin  = $body['password'] ?? '';
    // Accept any 4-digit PIN
    if (strlen($pin) === 4 && ctype_digit($pin)) {
        jsonResponse([
            'success' => true,
            'data'    => [
                'id'       => 1,
                'name'     => 'Demo Waiter',
                'username' => 'demo',
                'role'     => 'waiter',
                'color'    => '#000000',
            ],
        ]);
    }
    jsonResponse(['success' => false, 'message' => 'Invalid PIN. Use any 4-digit code.'], 401);
}

if ($method === 'POST' && matchRoute('/api/Login/logout', $uri, $params)) {
    jsonResponse(['success' => true, 'message' => 'Logged out']);
}

// ── Halls & Tables ───────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/api/halls') {
    jsonResponse(['success' => true, 'data' => getHalls()]);
}

if ($method === 'GET' && matchRoute('/api/halls/{id}/tables', $uri, $params)) {
    $hallId = (int) $params['id'];
    foreach (getHalls() as $hall) {
        if ((int) $hall['id'] === $hallId) {
            jsonResponse(['success' => true, 'data' => $hall['tables']]);
        }
    }
    jsonResponse(['success' => false, 'message' => 'Hall not found'], 404);
}

if ($method === 'GET' && matchRoute('/api/tables/{id}', $uri, $params)) {
    $tid = $params['id'];
    foreach (getHalls() as $hall) {
        foreach ($hall['tables'] as $t) {
            if ($t['id'] === $tid) {
                jsonResponse(['success' => true, 'data' => $t]);
            }
        }
    }
    jsonResponse(['success' => false, 'message' => 'Table not found'], 404);
}

if ($method === 'PUT' && matchRoute('/api/Halls/tables/{id}/status', $uri, $params)) {
    jsonResponse(['success' => true, 'data' => [
        'id'         => $params['id'],
        'name'       => 'Table ' . $params['id'],
        'status'     => 'occupied',
        'waiterId'   => '1',
        'waiterName' => 'Demo Waiter',
        'total'      => 0.0,
    ]]);
}

if ($method === 'PUT' && matchRoute('/api/halls/tables/{id}/free', $uri, $params)) {
    // Clear stored data for this table when freed
    $tableId = $params['id'];
    $file = tableFile($tableId);
    if (file_exists($file)) {
        unlink($file);
    }
    // Also clear composite table IDs that contain this table ID
    $compositePattern = dataDir() . '/table_*_' . $tableId . '.json';
    foreach (glob($compositePattern) as $f) {
        unlink($f);
    }
    jsonResponse(['success' => true, 'data' => [
        'id'         => $tableId,
        'name'       => 'Table ' . $tableId,
        'status'     => 'free',
        'waiterId'   => null,
        'waiterName' => null,
        'total'      => 0.0,
    ]]);
}

if ($method === 'POST' && $uri === '/api/Tables') {
    $body = readBody();
    jsonResponse(['success' => true, 'id' => 99, 'name' => $body['name'] ?? 'New Table', 'status' => 'free'], 201);
}

// ── Menu / Products ──────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/api/Sales/products') {
    jsonResponse(['success' => true, 'data' => getProducts()]);
}

if ($method === 'GET' && $uri === '/api/Sales/categories') {
    jsonResponse(['success' => true, 'data' => getCategories()]);
}

if ($method === 'GET' && $uri === '/api/Orders/products/search') {
    $name = $_GET['name'] ?? '';
    if ($name === '') {
        jsonResponse(['success' => true, 'data' => []]);
    }
    $results = array_values(array_filter(getProducts(), function ($p) use ($name) {
        return stripos($p['name'], $name) !== false;
    }));
    jsonResponse(['success' => true, 'data' => $results]);
}

// ── TempTav (current order items) ────────────────────────────────────────────
if ($method === 'GET' && matchRoute('/api/TempTav/table/{id}', $uri, $params)) {
    $tableId = $params['id'];
    $td = readTableData($tableId);
    jsonResponse(['success' => true, 'data' => $td['temp']]);
}

if ($method === 'POST' && matchRoute('/api/TempTav/table/{id}/add', $uri, $params)) {
    $tableId = $params['id'];
    $body    = readBody();
    $productId = (int) ($body['productId'] ?? 0);
    $quantity  = (double) ($body['quantity'] ?? 1);
    $options   = $body['options'] ?? '';

    $product = findProduct($productId);
    if (!$product) {
        jsonResponse(['success' => false, 'message' => 'Product not found'], 404);
    }

    $td  = readTableData($tableId);
    $newId = $td['nextId'] ?? 1;
    $td['nextId'] = $newId + 1;

    $item = [
        'id'          => $newId,
        'tableId'     => $tableId,
        'productId'   => $productId,
        'productName' => $product['name'],
        'cmimi'       => $product['price'],
        'sasia'       => $quantity,
        'opsionet'    => $options,
    ];
    $td['temp'][] = $item;
    writeTableData($tableId, $td);

    jsonResponse(['success' => true, 'data' => $item]);
}

if ($method === 'DELETE' && matchRoute('/api/TempTav/{id}', $uri, $params)) {
    $itemId = (int) $params['id'];
    // Search all table files to find and remove the item
    $found = false;
    foreach (glob(dataDir() . '/table_*.json') as $file) {
        $tableId = preg_replace('/^table_|\.json$/', '', basename($file));
        $td = readTableData($tableId);
        $before = count($td['temp']);
        $td['temp'] = array_values(array_filter($td['temp'], function ($item) use ($itemId) {
            return (int) $item['id'] !== $itemId;
        }));
        if (count($td['temp']) < $before) {
            writeTableData($tableId, $td);
            $found = true;
            break;
        }
    }
    jsonResponse(['success' => true, 'message' => $found ? 'Item removed' : 'Item not found (already removed)']);
}

if ($method === 'DELETE' && matchRoute('/api/TempTav/table/{id}/clear', $uri, $params)) {
    $tableId = $params['id'];
    $td = readTableData($tableId);
    $td['temp'] = [];
    writeTableData($tableId, $td);
    jsonResponse(['success' => true, 'message' => 'Temp orders cleared']);
}

// ── Temp Orders (update / total) ─────────────────────────────────────────────
if ($method === 'PUT' && matchRoute('/api/temp-orders/{id}', $uri, $params)) {
    $itemId = (int) $params['id'];
    $body   = readBody();
    // Search all table files
    foreach (glob(dataDir() . '/table_*.json') as $file) {
        $tableId = preg_replace('/^table_|\.json$/', '', basename($file));
        $td = readTableData($tableId);
        foreach ($td['temp'] as &$item) {
            if ((int) $item['id'] === $itemId) {
                if (isset($body['quantity'])) $item['sasia'] = (double) $body['quantity'];
                if (isset($body['notes']))    $item['opsionet'] = $body['notes'];
                writeTableData($tableId, $td);
                jsonResponse(['success' => true, 'data' => $item]);
            }
        }
        unset($item);
    }
    jsonResponse(['success' => false, 'message' => 'Item not found'], 404);
}

if ($method === 'GET' && matchRoute('/api/temp-orders/{id}/total', $uri, $params)) {
    $tableId = $params['id'];
    $td = readTableData($tableId);
    $total = 0.0;
    foreach ($td['temp'] as $item) {
        $total += ($item['cmimi'] ?? 0) * ($item['sasia'] ?? 1);
    }
    jsonResponse(['success' => true, 'data' => ['total' => round($total, 2)]]);
}

// ── Orders (past / batch) ────────────────────────────────────────────────────
if ($method === 'GET' && matchRoute('/api/Orders/table/{id}', $uri, $params)) {
    $tableId = $params['id'];
    $td = readTableData($tableId);
    jsonResponse(['success' => true, 'data' => $td['orders']]);
}

if ($method === 'POST' && $uri === '/api/Orders/batch') {
    $body    = readBody();
    $tableId = $body['tableId'] ?? '';
    if ($tableId === '') {
        jsonResponse(['success' => false, 'message' => 'Missing tableId'], 400);
    }

    $td = readTableData($tableId);

    // Move current temp items to past orders
    $batchOrders = [];
    $now = date('c');
    foreach ($td['temp'] as $item) {
        $orderId = rand(10000, 99999);
        $batchOrders[] = [
            'id'          => $orderId,
            'tableId'     => $tableId,
            'productName' => $item['productName'],
            'price'       => $item['cmimi'],
            'quantity'    => $item['sasia'],
            'notes'       => $item['opsionet'] ?? '',
            'total'       => round(($item['cmimi'] ?? 0) * ($item['sasia'] ?? 1), 2),
            'status'      => 'open',
            'orderTime'   => $now,
        ];
    }

    // Append to past orders, clear temp
    $td['orders'] = array_merge($td['orders'], $batchOrders);
    $td['temp']   = [];
    writeTableData($tableId, $td);

    jsonResponse(['success' => true, 'message' => 'Batch order created', 'data' => $batchOrders]);
}

// ── Payments ─────────────────────────────────────────────────────────────────
if ($method === 'GET' && $uri === '/api/Payments/methods') {
    jsonResponse(['success' => true, 'data' => getPaymentMethods()]);
}

if ($method === 'POST' && matchRoute('/api/tables/{id}/finalize', $uri, $params)) {
    $tableId = $params['id'];
    // Clear all stored data for this table
    $td = readTableData($tableId);
    $td['temp']   = [];
    $td['orders'] = [];
    writeTableData($tableId, $td);
    jsonResponse(['success' => true, 'data' => ['transactionId' => 'TXN-' . rand(100000, 999999)]]);
}

if ($method === 'POST' && $uri === '/api/transactions/staff-sale') {
    $body = readBody();
    $tableId = $body['tableId'] ?? '';
    if ($tableId !== '') {
        $td = readTableData($tableId);
        $td['temp']   = [];
        $td['orders'] = [];
        writeTableData($tableId, $td);
    }
    jsonResponse(['success' => true, 'data' => ['transactionId' => 'TXN-' . rand(100000, 999999)]]);
}

if ($method === 'POST' && $uri === '/api/Payments/process') {
    $body    = readBody();
    $tableId = $body['tableId'] ?? '';
    if ($tableId !== '') {
        $td = readTableData($tableId);
        $td['temp']   = [];
        $td['orders'] = [];
        writeTableData($tableId, $td);
    }
    jsonResponse(['success' => true, 'data' => ['transactionId' => 'TXN-' . rand(100000, 999999)], 'message' => 'Payment processed']);
}

// ── Print receipts (no-op success) ───────────────────────────────────────────
if ($method === 'POST' && matchRoute('/api/orders/{id}/print-receipt', $uri, $params)) {
    jsonResponse(['success' => true, 'data' => ['message' => 'Receipt printed'], 'message' => 'Receipt sent to printer']);
}

if ($method === 'POST' && matchRoute('/api/transactions/{id}/print-fiscal', $uri, $params)) {
    jsonResponse(['success' => true, 'data' => ['message' => 'Fiscal receipt printed'], 'message' => 'Fiscal receipt sent to printer']);
}

// ─── FALLBACK ────────────────────────────────────────────────────────────────
jsonResponse(['success' => false, 'message' => "Route not found: $method $uri"], 404);
