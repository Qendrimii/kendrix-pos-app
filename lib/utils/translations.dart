class AppTranslations {
  // App Title
  static const String appTitle = 'Restaurant POS';
  
  // Login Screen
  static const String invalidPin = 'PIN i pavlefshëm';
  static const String loginFailed = 'Hyrja dështoi';
  static const String settings = 'Cilësimet';
  
  // Settings Screen
  static const String serverSettings = 'Cilësimet e Serverit';
  static const String serverConfiguration = 'Konfigurimi i Serverit';
  static const String serverConfigurationDescription = 'Konfiguroni URL-në e serverit API për sistemin tuaj të POS-së së restorantit.';
  static const String serverUrl = 'URL e Serverit';
  static const String serverUrlHint = 'http://localhost:3333';
  static const String autoDiscoverServer = 'Zbulimi Automatik i Serverit';
  static const String discovering = 'Duke zbuluar...';
  static const String testConnection = 'Testo Lidhjen';
  static const String testing = 'Duke testuar...';
  static const String connectionSuccessful = 'Lidhja u krye me sukses! API është i arritshëm.';
  static const String connectionFailed = 'Lidhja dështoi. Kontrolloni konsolën për detaje.';
  static const String troubleshooting = 'Zgjidhja e problemeve:';
  static const String ensureApiRunning = 'Sigurohuni që serveri API të jetë duke punuar';
  static const String checkAccessible = 'Kontrolloni nëse URL është e arritshme';
  static const String verifyCors = 'Verifikoni që CORS të jetë i aktivizuar në server';
  static const String tryDirectAccess = 'Përpiquni të aksesoni URL-në direkt në shfletues';
  static const String networkIssues = 'Probleme të lidhjes së rrjetit';
  static const String corsBlocking = 'CORS duke bllokuar (nëse është aplikacion web)';
  static const String serverNotResponding = 'Serveri nuk po përgjigjet';
  static const String invalidUrlFormat = 'Format i pavlefshëm URL';
  static const String saveSettings = 'Ruaj Cilësimet';
  static const String settingsSaved = 'Cilësimet u ruajtën dhe të dhënat u ngarkuan nga API!';
  static const String errorSavingSettings = 'Gabim në ruajtjen e cilësimeve';
  
  // Port Discovery
  static const String portDiscovery = 'Zbulimi i Portave';
  static const String portDiscoveryDescription = 'Zbuloni portat e disponueshme në një host specifik.';
  static const String hostAddress = 'Adresa e Host-it';
  static const String hostAddressHint = 'localhost ose 192.168.1.100';
  static const String discoverPorts = 'Zbulo Portat';
  static const String scanning = 'Duke skanuar...';
  static const String pleaseEnterHost = 'Ju lutemi vendosni një adresë host së pari';
  static const String foundPorts = 'U gjetën portat e disponueshme';
  static const String noPortsFound = 'Nuk u gjetën portat e disponueshme në';
  static const String portDiscoveryFailed = 'Zbulimi i portave dështoi';
  static const String autoDiscovering = 'Duke zbuluar automatikisht serverin API...';
  static const String autoDiscoveredServer = 'Serveri u zbulua automatikisht';
  static const String noServerFound = 'Nuk u gjet server API gjatë zbulimit automatik';
  static const String autoDiscoveryFailed = 'Zbulimi automatik dështoi';
  static const String discoveredPorts = 'Portat e Zbuluara:';
  static const String port = 'Porti';
  static const String healthEndpointAvailable = 'Pika fundore e shëndetësisë e disponueshme';
  static const String serverResponding = 'Serveri po përgjigjet';
  static const String use = 'Përdor';
  
  // Cache Management
  static const String cacheManagement = 'Menaxhimi i Cache';
  static const String cacheManagementDescription = 'Menaxhoni të dhënat e cache-uara lokalisht.';
  static const String cacheSize = 'Madhësia e Cache:';
  static const String bytes = 'bytes';
  static const String clearCache = 'Pastro Cache';
  static const String cacheCleared = 'Cache-u u pastrua me sukses!';
  static const String errorClearingCache = 'Gabim në pastrimin e cache';
  
  // Example URLs
  static const String exampleUrls = 'URL-të Shembull:';
  static const String localDevelopment = 'Zhvillimi lokal: http://localhost:3333';
  static const String localNetwork = 'Rrjeti lokal: http://192.168.1.100:3333';
  static const String production = 'Prodhimi: https://api.restaurant.com';
  
  // Table Detail Screen
  static const String tableNotFound = 'Tavolina nuk u gjet';
  static const String accessDenied = 'Aksesi u refuzua';
  static const String tableAssignedToAnotherWaiter = 'Kjo tavolinë është caktuar një kamarieri tjetër';
  static const String orderSentToKitchen = 'Porosia u dërgua në kuzhinë!';
  static const String addItem = 'Shto';
  static const String specialInstructions = 'Udhëzime të veçanta (opsionale)';
  static const String addToOrder = 'Shto në Porosi';
  static const String cancel = 'Anulo';
  static const String close = 'Mbyll';
  static const String noItemsFound = 'Nuk u gjetën artikuj';
  static const String quantity = 'Sasia';
  static const String note = 'Shënim';
  
  // Current Order
  static const String currentOrder = 'Porosia Aktuale';
  static const String currentOrderMobile = 'Porosia Aktuale';
  static const String pastOrders = 'Historiku i Porosive';
  static const String pastOrdersMobile = 'Historiku i Porosive';
  static const String items = 'artikuj';
  static const String order = 'Porosi';
  static const String sendToKitchen = 'Dërgo në Kuzhinë';
  
  // Dialog Translations
  static const String editItem = 'Redakto';
  static const String commentOptional = 'Koment (opsional)';
  static const String update = 'Përditëso';
  static const String previousOrdersItems = 'Porositë e Mëparshme - Artikuj';
  static const String differentProducts = 'produkte të ndryshme';
  static const String lastOrder = 'Porosia e fundit';
  
  // Previous Orders
  static const String previousOrders = 'Porositë e Mëparshme';
  static const String total = 'total';
  
  // Payment Dialog
  static const String payment = 'Pagesa';
  static const String table = 'Tavolina';
  static const String orders = 'Porositë';
  static const String paymentMethod = 'Metoda e Pagesës:';
  static const String cashReceived = 'Para të marra';
  static const String fullPayment = 'Pagesa e Plotë';
  static const String change = 'Kusuri';
  static const String completePayment = 'Përfundo Pagesën';
  static const String paymentCompleted = 'Pagesa u përfundua!';
  static const String paymentFailed = 'Pagesa dështoi';
  
  // Mobile Bottom Bar
  static const String paymentButton = 'Pagesa';
  
  // Search
  static const String search = 'Kërko';
  static const String searchHint = 'Kërko produkte...';
  
  // Categories
  static const String allCategories = 'Të Gjitha';
  static const String searchCategory = 'Kërko';
  
  // Error Messages
  static const String error = 'Gabim';
  static const String errorType = 'Lloji i Gabimit';
  static const String thisUsuallyIndicates = 'Kjo zakonisht tregon:';
  
  // Success Messages
  static const String success = 'Sukses';
  static const String operationCompleted = 'Operacioni u përfundua';
  
  // Loading States
  static const String loading = 'Duke ngarkuar...';
  static const String pleaseWait = 'Ju lutemi prisni...';
  
  // Navigation
  static const String back = 'Kthehu';
  static const String next = 'Vazhdo';
  static const String done = 'Përfunduar';
  
  // Status Messages
  static const String connected = 'I lidhur';
  static const String disconnected = 'I shkëputur';
  static const String online = 'Online';
  static const String offline = 'Offline';
  
  // Time and Date
  static const String today = 'Sot';
  static const String yesterday = 'Dje';
  static const String thisWeek = 'Këtë javë';
  static const String thisMonth = 'Këtë muaj';
  
  // Currency
  static const String currency = 'Lek';
  static const String currencySymbol = 'L';
  
  // Common Actions
  static const String edit = 'Redakto';
  static const String delete = 'Fshi';
  static const String save = 'Ruaj';
  static const String create = 'Krijo';
  static const String remove = 'Hiq';
  static const String add = 'Shto';
  static const String view = 'Shiko';
  static const String print = 'Printo';
  static const String export = 'Eksporto';
  static const String import = 'Importo';
  
  // Confirmation
  static const String confirm = 'Konfirmo';
  static const String confirmDelete = 'A jeni të sigurt që doni ta fshini?';
  static const String confirmAction = 'A jeni të sigurt që doni ta vazhdoni?';
  static const String yes = 'Po';
  static const String no = 'Jo';
  static const String ok = 'OK';
  
  // Validation
  static const String required = 'Kërkohet';
  static const String invalidInput = 'Hyrje e pavlefshme';
  static const String pleaseEnterValue = 'Ju lutemi vendosni një vlerë';
  static const String pleaseEnterValidUrl = 'Ju lutemi vendosni një URL të vlefshme (p.sh., http://localhost:3333)';
  
  // Network
  static const String networkError = 'Gabim i rrjetit';
  static const String connectionError = 'Gabim i lidhjes';
  static const String timeoutError = 'Gabim i kohës së pritjes';
  static const String serverError = 'Gabim i serverit';
  
  // Data
  static const String noData = 'Nuk ka të dhëna';
  static const String loadingData = 'Duke ngarkuar të dhënat...';
  static const String dataLoaded = 'Të dhënat u ngarkuan';
  static const String dataSaved = 'Të dhënat u ruajtën';
  static const String dataDeleted = 'Të dhënat u fshinë';
  
  // Table Status
  static const String tableFree = 'E lirë';
  static const String tableOccupied = 'E zënë';
  static const String tableReserved = 'E rezervuar';
  static const String tableCleaning = 'Duke pastruar';
  
  // Order Status
  static const String orderOpen = 'E hapur';
  static const String orderPrinted = 'E printuar';
  static const String orderClosed = 'E mbyllur';
  static const String orderCancelled = 'E anuluar';
  
  // Menu Categories
  static const String appetizers = 'Përpara';
  static const String mainCourse = 'Gjella kryesore';
  static const String desserts = 'Ëmbëlsira';
  static const String beverages = 'Pije';
  static const String alcoholicBeverages = 'Pije alkoolike';
  static const String nonAlcoholicBeverages = 'Pije jo-alkoolike';
  static const String coffee = 'Kafe';
  static const String tea = 'Çaj';
  static const String water = 'Ujë';
  static const String softDrinks = 'Pije të buta';
  static const String juices = 'Lëngje';
  static const String salads = 'Sallata';
  static const String soups = 'Supat';
  static const String pasta = 'Makaronat';
  static const String pizza = 'Pica';
  static const String meat = 'Mishi';
  static const String fish = 'Peshku';
  static const String vegetarian = 'Vegetarian';
  static const String vegan = 'Vegan';
  static const String glutenFree = 'Pa gluten';
  static const String dairyFree = 'Pa qumësht';
  
  // Payment Methods
  static const String cash = 'Para';
  static const String card = 'Kartë';
  static const String creditCard = 'Kartë krediti';
  static const String debitCard = 'Kartë debiti';
  static const String mobilePayment = 'Pagesa me telefon';
  static const String bankTransfer = 'Transferta bankare';
  static const String check = 'Çek';
  static const String voucher = 'Voucher';
  static const String giftCard = 'Kartë dhuratë';
  
  // Receipt
  static const String receipt = 'Fatura';
  static const String receiptCopy = 'Kopja e fatura';
  static const String customerReceipt = 'Fatura e klientit';
  static const String fiscalReceipt = 'Fatura fiskale';
  static const String receiptNumber = 'Numri i fatura';
  static const String receiptDate = 'Data e fatura';
  static const String receiptTime = 'Ora e fatura';
  static const String receiptTotal = 'Totali i fatura';
  static const String receiptTax = 'Taksa e fatura';
  static const String receiptSubtotal = 'Nëntotali i fatura';
  static const String receiptDiscount = 'Zbritja e fatura';
  static const String receiptTip = 'Bakshishi i fatura';
  static const String receiptChange = 'Kusuri i fatura';
  static const String receiptThankYou = 'Faleminderit për vizitën tuaj!';
  static const String receiptWelcomeBack = 'Mirë se u kthet!';
  
  // Staff
  static const String waiter = 'Kamarier';
  static const String waitress = 'Kamariere';
  static const String server = 'Server';
  static const String bartender = 'Bartender';
  static const String chef = 'Kuzhinier';
  static const String manager = 'Menaxher';
  static const String owner = 'Pronar';
  static const String staff = 'Stafi';
  static const String employee = 'Punëtor';
  static const String user = 'Përdorues';
  
  // Restaurant
  static const String restaurant = 'Restorant';
  static const String cafe = 'Kafe';
  static const String bar = 'Bar';
  static const String pizzeria = 'Pizzeria';
  static const String bakery = 'Furrë buke';
  static const String fastFood = 'Ushqim i shpejtë';
  static const String fineDining = 'Restorant i mirë';
  static const String casualDining = 'Restorant i thjeshtë';
  static const String takeaway = 'Për marrje';
  static const String delivery = 'Për dërgim';
  static const String dineIn = 'Për në vend';
  
  // Halls and Tables
  static const String hall = 'Salla';
//  static const String table = 'Tavolina';
  static const String tables = 'Tavolinat';
  static const String tableNumber = 'Numri i tavolinës';
  static const String tableName = 'Emri i tavolinës';
  static const String tableStatus = 'Statusi i tavolinës';
  static const String tableCapacity = 'Kapaciteti i tavolinës';
  static const String tableLocation = 'Vendndodhja e tavolinës';
  static const String tableType = 'Lloji i tavolinës';
  static const String indoor = 'Në brendësi';
  static const String outdoor = 'Në jashtë';
  static const String smoking = 'Për duhanpirës';
  static const String nonSmoking = 'Për jo-duhanpirës';
  static const String window = 'Dritare';
  static const String corner = 'Kënd';
  static const String center = 'Qendër';
  static const String barSeating = 'Ulje në bar';
  static const String booth = 'Kabinë';
  static const String highTop = 'Tavolinë e lartë';
  static const String lowTop = 'Tavolinë e ulët';
  static const String round = 'E rrumbullakët';
  static const String square = 'Katrore';
  static const String rectangle = 'Drejtkëndëshe';
  
  // Menu Items
  static const String menu = 'Menu';
  static const String menuItem = 'Artikull i menysë';
  static const String menuItems = 'Artikujt e menysë';
  static const String product = 'Produkt';
  static const String products = 'Produktet';
  static const String item = 'Artikull';
  //static const String items = 'Artikujt';
  static const String dish = 'Gjellë';
  static const String dishes = 'Gjellët';
  static const String food = 'Ushqim';
  static const String drink = 'Pije';
  static const String drinks = 'Pijet';
  static const String appetizer = 'Përpara';
  //static const String appetizers = 'Përparat';
  static const String mainDish = 'Gjella kryesore';
  static const String mainDishes = 'Gjellët kryesore';
  static const String dessert = 'Ëmbëlsirë';
  //static const String desserts = 'Ëmbëlsirat';
  static const String sideDish = 'Gjellë anësore';
  static const String sideDishes = 'Gjellët anësore';
  static const String soup = 'Supë';
 // static const String soups = 'Supat';
  static const String salad = 'Sallatë';
  //static const String salads = 'Sallatat';
  static const String bread = 'Bukë';
  //static const String pasta = 'Makaronat';
  //static const String pizza = 'Picë';
  //static const String meat = 'Mish';
  //static const String fish = 'Peshk';
  static const String chicken = 'Pulë';
  static const String beef = 'Viç';
  static const String pork = 'Derri';
  static const String lamb = 'Qengji';
  static const String seafood = 'Deti';
  //static const String vegetarian = 'Vegetarian';
  //static const String vegan = 'Vegan';
  //static const String glutenFree = 'Pa gluten';
  //static const String dairyFree = 'Pa qumësht';
  static const String spicy = 'I pikant';
  static const String mild = 'I butë';
  static const String hot = 'I nxehtë';
  static const String cold = 'I ftohtë';
  static const String fresh = 'I freskët';
  static const String frozen = 'I ngrirë';
  static const String organic = 'Organik';
  static const String local = 'Vendës';
  static const String imported = 'I importuar';
  static const String seasonal = 'Sezonal';
  static const String daily = 'Ditore';
  static const String weekly = 'Javore';
  static const String monthly = 'Mujore';
  static const String available = 'I disponueshëm';
  static const String unavailable = 'I padisponueshëm';
  static const String outOfStock = 'Jashtë stokut';
  static const String limited = 'I kufizuar';
  static const String popular = 'I popullarizuar';
  static const String newItem = 'Artikull i ri';
  static const String featured = 'I veçantë';
  static const String recommended = 'I rekomanduar';
  static const String bestSeller = 'Më i shituri';
  static const String chefSpecial = 'Specialiteti i kuzhinierit';
  static const String houseSpecial = 'Specialiteti i shtëpisë';
  static const String signatureDish = 'Gjella e nënshkrimit';
  static const String traditional = 'Tradicional';
  static const String modern = 'Modern';
  static const String fusion = 'Fuzion';
  static const String international = 'Ndërkombëtar';
  static const String mediterranean = 'Mesdhetar';
  static const String italian = 'Italjan';
  static const String french = 'Francez';
  static const String greek = 'Grek';
  static const String turkish = 'Turq';
  static const String chinese = 'Kinez';
  static const String japanese = 'Japonez';
  static const String thai = 'Tajlandez';
  static const String indian = 'Indian';
  static const String mexican = 'Meksikan';
  static const String american = 'Amerikan';
  static const String european = 'Europian';
  static const String asian = 'Aziatik';
  static const String african = 'Afrikan';
  static const String middleEastern = 'Lindor i Mesëm';
  static const String latinAmerican = 'Amerikan Latin';
  
  // Order Management
  //static const String order = 'Porosi';
 // static const String orders = 'Porositë';
  static const String orderNumber = 'Numri i porosisë';
  static const String orderDate = 'Data e porosisë';
  static const String orderTime = 'Ora e porosisë';
  static const String orderStatus = 'Statusi i porosisë';
  static const String orderType = 'Lloji i porosisë';
  static const String orderTotal = 'Totali i porosisë';
  static const String orderSubtotal = 'Nëntotali i porosisë';
  static const String orderTax = 'Taksa e porosisë';
  static const String orderDiscount = 'Zbritja e porosisë';
  static const String orderTip = 'Bakshishi i porosisë';
  static const String orderChange = 'Kusuri i porosisë';
  static const String orderItems = 'Artikujt e porosisë';
  static const String orderItem = 'Artikulli i porosisë';
  static const String orderQuantity = 'Sasia e porosisë';
  static const String orderPrice = 'Çmimi i porosisë';
  static const String orderComment = 'Komentari i porosisë';
  static const String orderNotes = 'Shënimet e porosisë';
  static const String orderInstructions = 'Udhëzimet e porosisë';
  static const String orderSpecialRequests = 'Kërkesat e veçanta të porosisë';
  static const String orderAllergies = 'Alergjitë e porosisë';
  static const String orderDietaryRestrictions = 'Kufizimet dietike të porosisë';
  static const String orderCookingInstructions = 'Udhëzimet e gatimit të porosisë';
  static const String orderServingInstructions = 'Udhëzimet e shërbimit të porosisë';
  static const String orderPackagingInstructions = 'Udhëzimet e paketimit të porosisë';
  static const String orderDeliveryInstructions = 'Udhëzimet e dërgimit të porosisë';
  static const String orderPickupInstructions = 'Udhëzimet e marrjes të porosisë';
  static const String orderDineInInstructions = 'Udhëzimet për në vend të porosisë';
  static const String orderTakeawayInstructions = 'Udhëzimet për marrje të porosisë';
  static const String orderDeliveryAddress = 'Adresa e dërgimit të porosisë';
  static const String orderPickupTime = 'Ora e marrjes të porosisë';
  static const String orderDeliveryTime = 'Ora e dërgimit të porosisë';
  static const String orderEstimatedTime = 'Koha e vlerësuar e porosisë';
  static const String orderActualTime = 'Koha aktuale e porosisë';
  static const String orderPreparationTime = 'Koha e përgatitjes së porosisë';
  static const String orderCookingTime = 'Koha e gatimit të porosisë';
  static const String orderServingTime = 'Koha e shërbimit të porosisë';
  static const String orderCompletionTime = 'Koha e përfundimit të porosisë';
  static const String orderCancellationTime = 'Koha e anulimit të porosisë';
  static const String orderModificationTime = 'Koha e modifikimit të porosisë';
  static const String orderSplitTime = 'Koha e ndarjes së porosisë';
  static const String orderMergeTime = 'Koha e bashkimit të porosisë';
  static const String orderTransferTime = 'Koha e transferimit të porosisë';
  static const String orderRefundTime = 'Koha e rimbursimit të porosisë';
  static const String orderVoidTime = 'Koha e anulimit të porosisë';
  static const String orderReopenTime = 'Koha e rihapjes së porosisë';
  static const String orderCloseTime = 'Koha e mbylljes së porosisë';
  static const String orderPrintTime = 'Koha e printimit të porosisë';
  static const String orderEmailTime = 'Koha e dërgimit me email të porosisë';
  static const String orderSmsTime = 'Koha e dërgimit me SMS të porosisë';
  static const String orderNotificationTime = 'Koha e njoftimit të porosisë';
  static const String orderReminderTime = 'Koha e kujtimit të porosisë';
  static const String orderFollowUpTime = 'Koha e ndjekjes së porosisë';
  static const String orderFeedbackTime = 'Koha e komentit të porosisë';
  static const String orderRatingTime = 'Koha e vlerësimit të porosisë';
  static const String orderReviewTime = 'Koha e rishikimit të porosisë';
  static const String orderComplaintTime = 'Koha e ankesës së porosisë';
  static const String orderComplimentTime = 'Koha e komplimentit të porosisë';
  static const String orderSuggestionTime = 'Koha e sugjerimit të porosisë';
  static const String orderQuestionTime = 'Koha e pyetjes së porosisë';
  static const String orderAnswerTime = 'Koha e përgjigjes së porosisë';
  static const String orderHelpTime = 'Koha e ndihmës së porosisë';
  static const String orderSupportTime = 'Koha e mbështetjes së porosisë';
  static const String orderEscalationTime = 'Koha e eskalimit të porosisë';
  static const String orderResolutionTime = 'Koha e zgjidhjes së porosisë';
  static const String orderSatisfactionTime = 'Koha e kënaqësisë së porosisë';
  static const String orderLoyaltyTime = 'Koha e besnikërisë së porosisë';
  static const String orderRewardTime = 'Koha e shpërblimit të porosisë';
  static const String orderDiscountTime = 'Koha e zbritjes së porosisë';
  static const String orderPromotionTime = 'Koha e promocionit të porosisë';
  static const String orderCouponTime = 'Koha e kuponit të porosisë';
  static const String orderVoucherTime = 'Koha e voucherit të porosisë';
  static const String orderGiftCardTime = 'Koha e kartës dhuratë të porosisë';
  static const String orderLoyaltyCardTime = 'Koha e kartës së besnikërisë të porosisë';
  static const String orderMembershipTime = 'Koha e anëtarësimit të porosisë';
  static const String orderSubscriptionTime = 'Koha e abonimit të porosisë';
  static const String orderRecurringTime = 'Koha e përsëritjes së porosisë';
  static const String orderScheduledTime = 'Koha e planifikuar e porosisë';
  static const String orderPreOrderTime = 'Koha e porosisë paraprake';
  static const String orderAdvanceOrderTime = 'Koha e porosisë së avancuar';
  static const String orderRushOrderTime = 'Koha e porosisë së nxituar';
  static const String orderPriorityOrderTime = 'Koha e porosisë së prioritetit';
  static const String orderVIPOrderTime = 'Koha e porosisë VIP';
  static const String orderRegularOrderTime = 'Koha e porosisë së rregullt';
  static const String orderSpecialOrderTime = 'Koha e porosisë së veçantë';
  static const String orderCustomOrderTime = 'Koha e porosisë së personalizuar';
  static const String orderBulkOrderTime = 'Koha e porosisë së madhe';
  static const String orderWholesaleOrderTime = 'Koha e porosisë së shumicës';
  static const String orderRetailOrderTime = 'Koha e porosisë së pakicës';
  static const String orderOnlineOrderTime = 'Koha e porosisë online';
  static const String orderPhoneOrderTime = 'Koha e porosisë me telefon';
  static const String orderWalkInOrderTime = 'Koha e porosisë në vend';
  static const String orderDriveThruOrderTime = 'Koha e porosisë në drive-thru';
  static const String orderDeliveryOrderTime = 'Koha e porosisë për dërgim';
  static const String orderPickupOrderTime = 'Koha e porosisë për marrje';
  static const String orderCateringOrderTime = 'Koha e porosisë për catering';
  static const String orderEventOrderTime = 'Koha e porosisë për event';
  static const String orderPartyOrderTime = 'Koha e porosisë për festë';
  static const String orderCorporateOrderTime = 'Koha e porosisë për korporatë';
  static const String orderGroupOrderTime = 'Koha e porosisë për grup';
  static const String orderFamilyOrderTime = 'Koha e porosisë për familje';
  static const String orderIndividualOrderTime = 'Koha e porosisë për individ';
  static const String orderCoupleOrderTime = 'Koha e porosisë për çift';
  static const String orderSingleOrderTime = 'Koha e porosisë për një person';
  static const String orderMultipleOrderTime = 'Koha e porosisë për shumë persona';
  static const String orderLargeOrderTime = 'Koha e porosisë së madhe';
  static const String orderSmallOrderTime = 'Koha e porosisë së vogël';
  static const String orderMediumOrderTime = 'Koha e porosisë së mesme';
  static const String orderExtraLargeOrderTime = 'Koha e porosisë ekstra të madhe';
  static const String orderMiniOrderTime = 'Koha e porosisë mini';
  static const String orderMicroOrderTime = 'Koha e porosisë mikro';
  static const String orderNanoOrderTime = 'Koha e porosisë nano';
  static const String orderPicoOrderTime = 'Koha e porosisë piko';
  static const String orderFemtoOrderTime = 'Koha e porosisë femto';
  static const String orderAttoOrderTime = 'Koha e porosisë atto';
  static const String orderZeptoOrderTime = 'Koha e porosisë zepto';
  static const String orderYoctoOrderTime = 'Koha e porosisë yocto';
  static const String orderKiloOrderTime = 'Koha e porosisë kilo';
  static const String orderMegaOrderTime = 'Koha e porosisë mega';
  static const String orderGigaOrderTime = 'Koha e porosisë giga';
  static const String orderTeraOrderTime = 'Koha e porosisë tera';
  static const String orderPetaOrderTime = 'Koha e porosisë peta';
  static const String orderExaOrderTime = 'Koha e porosisë exa';
  static const String orderZettaOrderTime = 'Koha e porosisë zetta';
  static const String orderYottaOrderTime = 'Koha e porosisë yotta';
}
