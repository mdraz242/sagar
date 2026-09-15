import { createContext, useContext, useEffect, useState, type ReactNode } from "react";

export type Lang = "EN" | "HI";

type Dict = Record<string, { EN: string; HI: string }>;

export const T: Dict = {
  // header
  login: { EN: "Login", HI: "लॉगिन" },
  contactUs: { EN: "Contact Us", HI: "संपर्क करें" },
  loginManufacturer: { EN: "Login as Manufacturer", HI: "मैन्युफैक्चरर लॉगिन" },
  downloadApp: { EN: "Download App", HI: "ऐप डाउनलोड" },
  hindi: { EN: "हिंदी", HI: "English" },
  // manufacturer choice modal
  chooseCategory: { EN: "Choose your category", HI: "अपनी श्रेणी चुनें" },
  chooseCategorySub: { EN: "Select what you manufacture to continue.", HI: "जारी रखने के लिए आप क्या निर्माण करते हैं चुनें।" },
  fashionBeauty: { EN: "Fashion / Beauty", HI: "फैशन / सौंदर्य" },
  fashionBeautyDesc: { EN: "Clothing, footwear, accessories, beauty brands", HI: "कपड़े, जूते, एक्सेसरीज़, ब्यूटी ब्रांड" },
  fmcgKirana: { EN: "FMCG / Kirana", HI: "एफएमसीजी / किराना" },
  fmcgKiranaDesc: { EN: "Daily essentials, grocery, packaged goods", HI: "रोज़मर्रा का सामान, किराना, पैकेज्ड गुड्स" },
  // retailer login
  retailerLogin: { EN: "Retailer Login", HI: "रिटेलर लॉगिन" },
  retailerLoginSub: { EN: "Enter your shop's mobile number, we'll send an OTP.", HI: "अपने दुकान का मोबाइल नंबर डालें, हम OTP भेजेंगे।" },
  sendOtp: { EN: "Send OTP", HI: "OTP भेजें" },
  // FMCG application
  fmcgFormTitle: { EN: "FMCG / Kirana Manufacturer Application", HI: "एफएमसीजी / किराना निर्माता आवेदन" },
  fmcgFormSub: { EN: "Fill in your details. Our team will contact you.", HI: "अपनी जानकारी भरें। हमारी टीम आपसे संपर्क करेगी।" },
  fullName: { EN: "Full Name", HI: "पूरा नाम" },
  mobileNumber: { EN: "Mobile Number", HI: "मोबाइल नंबर" },
  enterOtp: { EN: "Enter 6-digit OTP", HI: "6-अंकीय OTP डालें" },
  shopOrCompany: { EN: "Shop / Company Name", HI: "दुकान / कंपनी का नाम" },
  address: { EN: "Address", HI: "पता" },
  sendOtpBtn: { EN: "Send OTP", HI: "OTP भेजें" },
  verifyContinue: { EN: "Verify & Continue", HI: "सत्यापित करें" },
  submit: { EN: "Submit Application", HI: "आवेदन जमा करें" },
  submitting: { EN: "Submitting…", HI: "जमा हो रहा है…" },
  back: { EN: "Back", HI: "वापस" },
  otpSent: { EN: "OTP sent (demo: use any 6 digits)", HI: "OTP भेजा गया (डेमो: कोई भी 6 अंक डालें)" },
  invalidOtp: { EN: "Enter a valid 6-digit OTP", HI: "मान्य 6-अंकीय OTP डालें" },
  thanksTitle: { EN: "Thank you for applying!", HI: "आवेदन के लिए धन्यवाद!" },
  thanksMsg: { EN: "After verification, our team will connect with you shortly.", HI: "सत्यापन के बाद, हमारी टीम जल्द ही आपसे संपर्क करेगी।" },
  goHome: { EN: "Go Home", HI: "होम पर जाएं" },
  // hero
  heroBadge: { EN: "India's #1 B2B Commerce Platform for Bharat", HI: "भारत का #1 B2B कॉमर्स प्लेटफ़ॉर्म" },
  heroTitle1: { EN: "Sell Smarter. Stock Smarter.", HI: "स्मार्ट बेचो। स्मार्ट स्टॉक करो।" },
  heroTitle2: { EN: "Grow Faster.", HI: "तेज़ी से बढ़ो।" },
  heroSubtitle: { EN: "Know What's Trending. Stock What's Selling.", HI: "जानो क्या ट्रेंड में है। स्टॉक करो जो बिक रहा है।" },
  heroDesc: {
    EN: "A retail intelligence platform built for Bharat — empowering shop owners across Tier 2, Tier 3 and Tier 4 cities and villages to discover trending products, source directly from verified manufacturers, and grow with real-time, AI-powered market insights.",
    HI: "भारत के लिए बना रिटेल इंटेलिजेंस प्लेटफ़ॉर्म — टियर 2, टियर 3 और टियर 4 शहरों व गाँवों के दुकानदारों को ट्रेंडिंग प्रोडक्ट खोजने, सत्यापित निर्माताओं से सीधे खरीदने और रियल-टाइम AI मार्केट इनसाइट के साथ बढ़ने की शक्ति देता है।",
  },
  payLaterCredit: { EN: "credit option", HI: "क्रेडिट विकल्प" },
  twoHourFmcg: { EN: "FMCG delivery", HI: "एफएमसीजी डिलीवरी" },
  twoHourLabel: { EN: "2 Hour", HI: "2 घंटे" },
  // hero / common
  payLater: { EN: "Pay Later", HI: "बाद में भुगतान" },
  twoHrDelivery: { EN: "2-Hour Delivery", HI: "2 घंटे डिलीवरी" },
  skus: { EN: "SKUs", HI: "एसकेयू" },
  retailers: { EN: "Retailers", HI: "रिटेलर" },
  manufacturers: { EN: "Manufacturers", HI: "निर्माता" },
  // retailer apply
  loginRetailer: { EN: "Login as Retailer", HI: "रिटेलर लॉगिन" },
  chooseRetailerCategory: { EN: "Choose your shop type", HI: "अपनी दुकान का प्रकार चुनें" },
  chooseRetailerCategorySub: { EN: "Select what you sell to continue.", HI: "जारी रखने के लिए आप क्या बेचते हैं चुनें।" },
  retailerFashionTitle: { EN: "Fashion / Beauty Retailer Sign-up", HI: "फैशन / सौंदर्य रिटेलर पंजीकरण" },
  retailerFmcgTitle: { EN: "FMCG / Kirana Retailer Sign-up", HI: "एफएमसीजी / किराना रिटेलर पंजीकरण" },
  retailerFormSub: { EN: "Fill your details to get the VyparHub app.", HI: "VyparHub ऐप पाने के लिए जानकारी भरें।" },
  optional: { EN: "optional", HI: "वैकल्पिक" },
  retailerDoneTitle: { EN: "All set! Welcome to VyparHub.", HI: "हो गया! VyparHub में आपका स्वागत है।" },
  retailerDoneMsg: { EN: "Download the app to start ordering at wholesale prices.", HI: "थोक मूल्य पर ऑर्डर शुरू करने के लिए ऐप डाउनलोड करें।" },
  // mission / vision
  whyExist: { EN: "Why we exist", HI: "हम क्यों हैं" },
  bharatRev1: { EN: "Bharat's", HI: "भारत की" },
  bharatRev2: { EN: "B2B revolution.", HI: "B2B क्रांति।" },
  ourVision: { EN: "Our Vision", HI: "हमारा विज़न" },
  visionBody: {
    EN: "To ensure that every retailer in Bharat, from Tier 2, Tier 3, Tier 4 cities to villages, has access to the same market intelligence, trending products, and growth opportunities as large urban businesses.",
    HI: "यह सुनिश्चित करना कि भारत के टियर 2, 3, 4 शहरों से लेकर गाँवों तक का हर रिटेलर वही मार्केट इंटेलिजेंस, ट्रेंडिंग प्रोडक्ट और ग्रोथ अवसर पा सके जो बड़े शहरी व्यवसायों को मिलते हैं।",
  },
  ourMission: { EN: "Our Mission", HI: "हमारा मिशन" },
  missionBody: {
    EN: "To help retailers discover what's selling, connect directly with manufacturers, and make smarter inventory decisions through AI-powered trend analysis and commerce infrastructure.",
    HI: "रिटेलर्स को यह खोजने में मदद करना कि क्या बिक रहा है, सीधे निर्माताओं से जुड़ना, और AI ट्रेंड एनालिसिस व कॉमर्स इन्फ्रास्ट्रक्चर के ज़रिए स्मार्ट इन्वेंट्री निर्णय लेना।",
  },
  pillTrend: { EN: "AI-Powered Trend Analysis", HI: "AI ट्रेंड एनालिसिस" },
  pillDirect: { EN: "Direct Manufacturer Access", HI: "सीधे निर्माता तक पहुँच" },
  pillPayLater: { EN: "Pay Later Commerce", HI: "पे लेटर कॉमर्स" },
  pill2Hr: { EN: "2-Hour FMCG Delivery", HI: "2 घंटे FMCG डिलीवरी" },
  // AllInOne
  aiTrendingPill: { EN: "AI Trending Products in Your Shop", HI: "आपकी दुकान में AI ट्रेंडिंग प्रोडक्ट" },
  everythingIn: { EN: "Everything in", HI: "सब कुछ" },
  onePlatform: { EN: "One Platform", HI: "एक प्लेटफ़ॉर्म पर" },
  rowFmcgTitle: { EN: "Trending stock for your kirana", HI: "आपकी किराना के लिए ट्रेंडिंग स्टॉक" },
  rowFmcgBody: {
    EN: "We push AI-powered trending products from manufacturers directly to retailers across Tier 2, Tier 3, Tier 4 cities and villages — so kirana owners never run out of what's actually selling.",
    HI: "हम निर्माताओं से AI-संचालित ट्रेंडिंग प्रोडक्ट सीधे टियर 2, 3, 4 शहरों और गाँवों के रिटेलर्स तक पहुँचाते हैं — ताकि किराना मालिकों के पास हमेशा वही स्टॉक रहे जो असल में बिक रहा है।",
  },
  browseFmcg: { EN: "Browse FMCG", HI: "FMCG देखें" },
  rowMfgTag: { EN: "FMCG Manufacturers", HI: "FMCG निर्माताओं के लिए" },
  rowMfgTitle: { EN: "FMCG Manufacturer se Retailer tak — zero middlemen", HI: "FMCG निर्माता से रिटेलर तक — कोई बिचौलिया नहीं" },
  rowMfgBody: {
    EN: "FMCG factories list their catalogue once and reach thousands of village retailers directly. Live demand signals from every pin code, so you produce exactly what's about to trend.",
    HI: "FMCG फ़ैक्ट्रियाँ अपना कैटलॉग एक बार लिस्ट करती हैं और सीधे हज़ारों गाँव रिटेलर्स तक पहुँचती हैं। हर पिन कोड से लाइव डिमांड सिग्नल, ताकि आप वही बनाएँ जो ट्रेंड होने वाला है।",
  },
  becomePartner: { EN: "Become a Partner", HI: "पार्टनर बनें" },
  // footer
  footerTagline: {
    EN: "Building Bharat's retail intelligence network by connecting manufacturers and retailers through trending products, AI-powered insights, and smarter commerce.",
    HI: "भारत के रिटेल इंटेलिजेंस नेटवर्क का निर्माण — निर्माताओं और रिटेलर्स को ट्रेंडिंग प्रोडक्ट, AI इनसाइट और स्मार्ट कॉमर्स के ज़रिए जोड़ते हुए।",
  },
  solutions: { EN: "Solutions", HI: "समाधान" },
  fmcgMarketplace: { EN: "FMCG Marketplace", HI: "FMCG मार्केटप्लेस" },
  fashionMarketplace: { EN: "Fashion Marketplace", HI: "फ़ैशन मार्केटप्लेस" },
  aiTrendAnalysis: { EN: "AI Trend Analysis", HI: "AI ट्रेंड एनालिसिस" },
  legal: { EN: "Legal", HI: "क़ानूनी" },
  privacy: { EN: "Privacy Policy", HI: "प्राइवेसी पॉलिसी" },
  terms: { EN: "Terms of Service", HI: "सेवा की शर्तें" },
  refund: { EN: "Refund & Returns", HI: "रिफ़ंड और रिटर्न" },
  sellerAgreement: { EN: "Seller / Manufacturer Agreement", HI: "सेलर / निर्माता समझौता" },
  accountDeletion: { EN: "Account Deletion", HI: "अकाउंट डिलीशन" },
  support: { EN: "Support", HI: "सहायता" },
  allRights: { EN: "All rights reserved.", HI: "सर्वाधिकार सुरक्षित।" },
  madeInBharat: { EN: "Made in Bharat 🇮🇳 — for every kirana, every village.", HI: "भारत में बना 🇮🇳 — हर किराना, हर गाँव के लिए।" },
  discoverTrends: { EN: "Discover Trends.", HI: "ट्रेंड्स खोजो।" },
  sourceSmarter: { EN: "Source Smarter.", HI: "स्मार्ट खरीदो।" },
  growFaster: { EN: "Grow Faster.", HI: "तेज़ी से बढ़ो।" },
  realFeedback: { EN: "Real retailer feedback", HI: "असली रिटेलर फ़ीडबैक" },
  doBusinessVerticals: { EN: "Do business verticals", HI: "दो बिज़नेस वर्टिकल" },
};

type Ctx = { lang: Lang; setLang: (l: Lang) => void; t: (key: keyof typeof T) => string };
const LanguageContext = createContext<Ctx | null>(null);

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>("EN");
  useEffect(() => {
    const saved = (typeof window !== "undefined" && localStorage.getItem("vh_lang")) as Lang | null;
    if (saved === "EN" || saved === "HI") setLangState(saved);
  }, []);
  const setLang = (l: Lang) => {
    setLangState(l);
    try { localStorage.setItem("vh_lang", l); } catch {}
  };
  const t = (key: keyof typeof T) => T[key]?.[lang] ?? String(key);
  return <LanguageContext.Provider value={{ lang, setLang, t }}>{children}</LanguageContext.Provider>;
}

export function useLang() {
  const ctx = useContext(LanguageContext);
  if (!ctx) return { lang: "EN" as Lang, setLang: () => {}, t: (k: keyof typeof T) => T[k]?.EN ?? String(k) };
  return ctx;
}
