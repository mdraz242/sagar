import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Lang { en, hi }

final langProvider = StateNotifierProvider<LangNotifier, Lang>(
  (ref) => LangNotifier(),
);

class LangNotifier extends StateNotifier<Lang> {
  LangNotifier() : super(Lang.en);

  void toggle() => state = state == Lang.en ? Lang.hi : Lang.en;
  void set(Lang lang) => state = lang;
}

String tr(String key, Lang lang) {
  final value = _t[key];
  if (value == null) return key;
  return lang == Lang.hi ? value.hi : value.en;
}

class _Copy {
  const _Copy(this.en, this.hi);
  final String en;
  final String hi;
}

const _t = <String, _Copy>{
  'appName': _Copy('VyparHub', 'व्यापारHub'),
  'tagline': _Copy('Makers seh Market tak', 'मैन्युफैक्चरर से रिटेलर तक'),
  'home': _Copy('Home', 'होम'),
  'category': _Copy('Category', 'कैटेगरी'),
  'categories': _Copy('Categories', 'कैटेगरी'),
  'ai': _Copy('AI Help', 'AI मदद'),
  'offers': _Copy('Offers', 'ऑफर्स'),
  'cart': _Copy('Cart', 'कार्ट'),
  'wallet': _Copy('Wallet', 'वॉलेट'),
  'deliveryIn': _Copy('Delivery in just 2 hours', 'डिलीवरी सिर्फ 2 घंटे में'),
  'deliveryShort': _Copy('2 hours', '2 घंटे'),
  'searchPlaceholder': _Copy('Search for "Coca Cola"', '"Coca Cola" खोजें'),
  'voiceSearch': _Copy('Voice search', 'बोलकर खोजें'),
  'expressDelivery': _Copy('Express Delivery', 'एक्सप्रेस डिलीवरी'),
  'doorstep': _Copy(
      'Door-step to your shop - citywide', 'आपकी दुकान तक - पूरे शहर में'),
  'topTrendingCategories':
      _Copy('Top Trending Categories', 'टॉप ट्रेंडिंग कैटेगरी'),
  'viewAll': _Copy('View all', 'सब देखें'),
  'inDemand': _Copy('In Demand', 'इन डिमांड'),
  'bestSellers': _Copy('Best Sellers', 'बेस्ट सेलर'),
  'highMargin': _Copy('High Margin', 'हाई मार्जिन'),
  'bestMargins': _Copy('Best Margins', 'बेस्ट मार्जिन'),
  'topBrands': _Copy('Top Brands', 'टॉप ब्रांड्स'),
  'topFmcg': _Copy('Top FMCG', 'टॉप FMCG'),
  'topPicks': _Copy('Top Picks', 'टॉप पिक्स'),
  'moreBrands': _Copy('More Brands', 'और ब्रांड्स'),
  'freshDeals': _Copy('Fresh deals', 'फ्रेश डील्स'),
  'trendingArea': _Copy('Trending in your area', 'आपके इलाके में ट्रेंडिंग'),
  'bestDeals': _Copy('Best Deals', 'बेस्ट डील्स'),
  'addToCart': _Copy('Add to Cart', 'कार्ट में डालें'),
  'inCart': _Copy('In Cart', 'कार्ट में'),
  'buyNow': _Copy('ORDER NOW', 'ऑर्डर करें'),
  'chooseSize':
      _Copy('Choose size - margin shown', 'साइज चुनें - मार्जिन देखें'),
  'bulk': _Copy('Bulk', 'बल्क'),
  'margin': _Copy('Margin', 'मार्जिन'),
  'totalMargin': _Copy('Total Margin', 'कुल मार्जिन'),
  'perPiece': _Copy('/pc', '/पीस'),
  'options': _Copy('Options', 'ऑप्शन'),
  'image': _Copy('IMAGE', 'फोटो'),
  'video': _Copy('VIDEO', 'वीडियो'),
  'buy': _Copy('Buy', 'खरीदें'),
  'tapOffer': _Copy('Watch photo / video - buy directly',
      'फोटो / वीडियो देखें - सीधे खरीदें'),
  'bulkMargin': _Copy('Bulk margin', 'बल्क मार्जिन'),
  'emptyCart': _Copy('Cart is empty', 'कार्ट खाली है'),
  'shopNow': _Copy('Shop now', 'शॉप करें'),
  'freeDeliveryUnlocked':
      _Copy('Free delivery unlocked!', 'फ्री डिलीवरी अनलॉक!'),
  'freeDeliveryMore': _Copy('Add {amount} more for free delivery',
      'फ्री डिलीवरी के लिए {amount} और जोड़ें'),
  'minOrder': _Copy('min Rs 1000', 'न्यूनतम Rs 1000'),
  'mrp': _Copy('MRP', 'MRP'),
  'buyPrice': _Copy('Buy Price', 'खरीद दाम'),
  'delivery': _Copy('Delivery', 'डिलीवरी'),
  'total': _Copy('Total', 'कुल'),
  'proceedOrder': _Copy('Proceed to Order', 'ऑर्डर आगे बढ़ाएं'),
  'deliveryAddress': _Copy('Delivery Address', 'डिलीवरी पता'),
  'choosePayment': _Copy('Choose Payment', 'पेमेंट चुनें'),
  'payUpi': _Copy('Pay via UPI', 'UPI से पेमेंट'),
  'orderPlaced': _Copy('Order Placed', 'ऑर्डर हो गया'),
  'fullName': _Copy('Full name', 'पूरा नाम'),
  'phone': _Copy('Phone', 'फोन'),
  'address': _Copy('Address', 'पता'),
  'area': _Copy('Area', 'एरिया'),
  'continuePayment': _Copy('Continue to Payment', 'पेमेंट पर जाएं'),
  'placeOrder': _Copy('Place Order', 'ऑर्डर करें'),
  'shopMore': _Copy('Shop more', 'और खरीदें'),
  'arrives2h':
      _Copy('Your order arrives in 2 hours', 'आपका ऑर्डर 2 घंटे में पहुंचेगा'),
  'step1Title': _Copy('Let us get started', 'शुरू करते हैं'),
  'step1Sub': _Copy('Enter your owner details', 'मालिक की जानकारी डालें'),
  'yourName': _Copy('Your name', 'आपका नाम'),
  'sendOtp': _Copy('Send OTP', 'OTP भेजें'),
  'back': _Copy('Back', 'वापस'),
  'step2Title': _Copy('Verify OTP', 'OTP वेरिफाई करें'),
  'otpSent': _Copy('OTP sent to', 'OTP भेजा गया'),
  'verify': _Copy('Verify', 'वेरिफाई'),
  'step3Title': _Copy('Shop Details', 'दुकान की जानकारी'),
  'step3Sub': _Copy('One last step - your shop name and address',
      'आखिरी कदम - दुकान का नाम और पता'),
  'shopName': _Copy('Shop name', 'दुकान का नाम'),
  'city': _Copy('City', 'शहर'),
  'pincode': _Copy('Pincode', 'पिनकोड'),
  'finish': _Copy('Get Started', 'शुरू करें'),
  'secureOtp': _Copy(
      '100% Secure - Demo OTP: 123456', '100% सुरक्षित - डेमो OTP: 123456'),
  'kiranaWelcome': _Copy('FOR YOUR KIRANA DUKAAN', 'आपकी किराना दुकान के लिए'),
  'heroStock': _Copy(
      'FMCG stock straight to your shop', 'FMCG स्टॉक सीधे आपकी दुकान तक'),
  'heroProfit':
      _Copy('Vyapar Badhao,\nMunafa Kamao', 'व्यापार बढ़ाओ,\nमुनाफा कमाओ'),
  'walletTitle': _Copy('My Wallet', 'मेरा वॉलेट'),
  'rewardsTitle': _Copy('OfferHub Rewards', 'OfferHub रिवॉर्ड्स'),
  'ordersTitle': _Copy('My Orders', 'मेरे ऑर्डर्स'),
  'supportTitle': _Copy('Support', 'सपोर्ट'),
  'referTitle': _Copy('Refer & Earn', 'रेफर और अर्न'),
  'kycTitle': _Copy('KYC + Pay Later', 'KYC + पे लेटर'),
  'returnTitle': _Copy('Return & Replace Policy', 'रिटर्न और रिप्लेस पॉलिसी'),
  'privacyTitle': _Copy('Privacy Policy', 'प्राइवेसी पॉलिसी'),
  'termsTitle': _Copy('Terms of Use', 'उपयोग की शर्तें'),
  'aboutTitle': _Copy('About Us', 'हमारे बारे में'),
  'logout': _Copy('Logout', 'लॉगआउट'),
  'availableBalance': _Copy('Available balance', 'उपलब्ध बैलेंस'),
  'addMoney': _Copy('Add Money', 'पैसा जोड़ें'),
  'noTransactions': _Copy('No transactions yet', 'अभी कोई ट्रांजैक्शन नहीं'),
  'earnPoints': _Copy('Earn points on every order', 'हर ऑर्डर पर पॉइंट कमाएं'),
  'supportCopy': _Copy('Call, WhatsApp or email us for order help.',
      'ऑर्डर मदद के लिए कॉल, WhatsApp या ईमेल करें।'),
  'referCopy': _Copy(
      'Refer a friend, both get Rs 100', 'दोस्त को रेफर करें, दोनों को Rs 100'),
  'yourCode': _Copy('Your code', 'आपका कोड'),
  'copyCode': _Copy('Copy Code', 'कोड कॉपी करें'),
  'kycSteps': _Copy('Submit owner ID, shop proof and bank details.',
      'मालिक ID, दुकान प्रूफ और बैंक डिटेल्स जमा करें।'),
  'submitKyc': _Copy('Submit KYC (Demo)', 'KYC सबमिट करें (डेमो)'),
  'kycApproved': _Copy('KYC Approved', 'KYC अप्रूव्ड'),
  'enablePayLater': _Copy('Enable Pay Later', 'पे लेटर चालू करें'),
  'limit25000': _Copy('Limit Rs 25,000', 'लिमिट Rs 25,000'),
  'returnCopy': _Copy(
      'Free replacement for damaged or wrong products within 48 hours. Original packaging is required.',
      'डैमेज या गलत प्रोडक्ट का 48 घंटे में फ्री रिप्लेसमेंट। ओरिजिनल पैकिंग जरूरी है।'),
  'privacyCopy': _Copy(
      'Phone, address and order history are used only for delivery and support.',
      'फोन, पता और ऑर्डर हिस्ट्री सिर्फ डिलीवरी और सपोर्ट के लिए इस्तेमाल होती है।'),
  'termsCopy': _Copy(
      'Bulk orders are for registered retailers. Prices may change with stock and market conditions.',
      'बल्क ऑर्डर रजिस्टर्ड रिटेलर्स के लिए हैं। स्टॉक और बाजार के अनुसार दाम बदल सकते हैं।'),
  'aboutCopy': _Copy(
      'VyparHub connects manufacturers to retailers with better margins and fast shop delivery.',
      'VyparHub मैन्युफैक्चरर को रिटेलर से जोड़ता है, बेहतर मार्जिन और तेज डिलीवरी के साथ।'),
  'noOrders': _Copy('No orders placed yet', 'अभी कोई ऑर्डर नहीं'),
  'noOrdersSub': _Copy(
      'Start shopping and your recent orders will appear here.',
      'शॉपिंग शुरू करें, आपके ऑर्डर यहां दिखेंगे।'),
  'recentOrders': _Copy('Recent Orders', 'हाल के ऑर्डर'),
  'items': _Copy('items', 'आइटम'),
  'login': _Copy('Login', 'लॉगिन'),
  'signup': _Copy('Signup', 'साइन अप'),
  'accountLogin': _Copy('Account login', 'अकाउंट लॉगिन'),
  'createAccount': _Copy('Create account', 'अकाउंट बनाएं'),
  'emailOrPhone': _Copy('Email or phone number', 'ईमेल या फोन नंबर'),
  'password': _Copy('Password', 'पासवर्ड'),
  'forgotPassword': _Copy('Forgot password?', 'पासवर्ड भूल गए?'),
  'forgotPasswordTitle': _Copy('Forgot password', 'पासवर्ड रीसेट'),
  'forgotPasswordCopy': _Copy(
      'Enter your email or phone number and we will send a reset link or OTP.',
      'ईमेल या फोन नंबर डालें, हम रीसेट लिंक या OTP भेजेंगे।'),
  'sendResetLink': _Copy('Send reset link', 'रीसेट लिंक भेजें'),
  'resetSent': _Copy('Reset instructions sent. Please check your email or SMS.',
      'रीसेट निर्देश भेज दिए गए। ईमेल या SMS चेक करें।'),
  'signInOtp': _Copy('Sign in with OTP', 'OTP से लॉगिन'),
  'biometricReady': _Copy('Fingerprint login is ready for device setup.',
      'फिंगरप्रिंट लॉगिन डिवाइस सेटअप के लिए तैयार है।'),
  'googlePending': _Copy('Google sign-in will be connected soon.',
      'Google लॉगिन जल्द कनेक्ट होगा।'),
};
