# 🌍 How to Use Tamil Localization in Your Screens

## Quick Integration Guide

### **1. Import the Localization**
```dart
import '../../generated/l10n.dart';
```

### **2. Use Translations in Your Widgets**
```dart
// Instead of hardcoded text:
Text('Login')

// Use localized text:
Text(S.of(context).login)
```

### **3. Common Examples**

#### **Buttons**
```dart
// English: "Login" | Tamil: "உள்நுழை"
ElevatedButton(
  onPressed: () {},
  child: Text(S.of(context).login),
)

// English: "Sign Up" | Tamil: "பதிவு செய்"
ElevatedButton(
  onPressed: () {},
  child: Text(S.of(context).signup),
)
```

#### **Role Selection**
```dart
// English: "Select Your Role" | Tamil: "உங்கள் வகையைத் தேர்வு செய்யவும்"
Text(S.of(context).selectRole)

// English: "Farmer" | Tamil: "விவசாயி"
Text(S.of(context).farmer)

// English: "Customer" | Tamil: "வாடிக்கையாளர்"
Text(S.of(context).customer)
```

#### **Product Actions**
```dart
// English: "Buy Now" | Tamil: "இப்போது வாங்கு"
ElevatedButton(
  onPressed: () {},
  child: Text(S.of(context).buyNow),
)

// English: "Add to Cart" | Tamil: "கூடையில் சேர்"
ElevatedButton(
  onPressed: () {},
  child: Text(S.of(context).addToCart),
)
```

#### **Navigation & Menus**
```dart
// English: "Products" | Tamil: "பொருட்கள்"
BottomNavigationBarItem(
  icon: Icon(Icons.inventory),
  label: S.of(context).products,
)

// English: "Orders" | Tamil: "ஆர்டர்கள்"
BottomNavigationBarItem(
  icon: Icon(Icons.shopping_bag),
  label: S.of(context).orders,
)

// English: "Profile" | Tamil: "சுயவிவரம்"
BottomNavigationBarItem(
  icon: Icon(Icons.person),
  label: S.of(context).profile,
)
```

### **4. Check Current Language**
```dart
// Get language service
final languageService = Provider.of<LanguageService>(context);

// Check if Tamil
if (languageService.isTamil) {
  // Show Tamil-specific content
}

// Check if English
if (languageService.isEnglish) {
  // Show English-specific content
}
```

### **5. Language-Specific Logic**
```dart
// Different behavior based on language
String getWelcomeMessage() {
  final languageService = Provider.of<LanguageService>(context, listen: false);
  
  if (languageService.isTamil) {
    return 'வணக்கம்! FieldFresh-க்கு வரவேற்கிறோம்';
  } else {
    return 'Welcome to FieldFresh!';
  }
}
```

### **6. Available Translation Keys**

#### **Common Actions**
- `S.of(context).login` - உள்நுழை
- `S.of(context).logout` - வெளியேறு
- `S.of(context).signup` - பதிவு செய்
- `S.of(context).cancel` - ரத்து செய்
- `S.of(context).save` - சேமி
- `S.of(context).delete` - நீக்கு
- `S.of(context).edit` - திருத்து
- `S.of(context).update` - புதுப்பி

#### **User Roles**
- `S.of(context).farmer` - விவசாயி
- `S.of(context).customer` - வாடிக்கையாளர்
- `S.of(context).admin` - நிர்வாகி

#### **Product Related**
- `S.of(context).products` - பொருட்கள்
- `S.of(context).postProduct` - பொருள் பதிவிடு
- `S.of(context).myProducts` - என் பொருட்கள்
- `S.of(context).buyNow` - இப்போது வாங்கு
- `S.of(context).addToCart` - கூடையில் சேர்
- `S.of(context).cart` - கூடை
- `S.of(context).price` - விலை
- `S.of(context).quantity` - அளவு

#### **Navigation**
- `S.of(context).orders` - ஆர்டர்கள்
- `S.of(context).profile` - சுயவிவரம்
- `S.of(context).settings` - அமைப்புகள்
- `S.of(context).location` - இடம்

#### **Status & States**
- `S.of(context).verified` - சரிபார்க்கப்பட்டது
- `S.of(context).pending` - நிலுவையில்
- `S.of(context).available` - கிடைக்கிறது
- `S.of(context).fresh` - புதிய
- `S.of(context).organic` - இயற்கை

### **7. Complete Screen Example**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n.dart';
import '../../services/language_service.dart';

class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).products), // "பொருட்கள்" in Tamil
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              // Navigate to language settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome message
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return Text(
                languageService.isTamil 
                  ? 'வணக்கம்! புதிய பொருட்களைப் பார்க்கவும்'
                  : 'Welcome! Check out fresh products',
                style: TextStyle(fontSize: 18),
              );
            },
          ),
          
          // Action buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                child: Text(S.of(context).buyNow), // "இப்போது வாங்கு"
              ),
              SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                child: Text(S.of(context).addToCart), // "கூடையில் சேர்"
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: S.of(context).products, // "பொருட்கள்"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: S.of(context).orders, // "ஆர்டர்கள்"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: S.of(context).profile, // "சுயவிவரம்"
          ),
        ],
      ),
    );
  }
}
```

## 🎯 Best Practices

### **1. Always Use Keys**
❌ **Don't**: `Text('Login')`
✅ **Do**: `Text(S.of(context).login)`

### **2. Check Language When Needed**
```dart
// For language-specific formatting
final languageService = Provider.of<LanguageService>(context);
final dateFormat = languageService.isTamil 
  ? 'dd/MM/yyyy' 
  : 'MM/dd/yyyy';
```

### **3. Handle Long Tamil Text**
```dart
// Tamil text might be longer, use flexible widgets
Flexible(
  child: Text(S.of(context).farmerDescription),
)
```

### **4. Test Both Languages**
- Always test your screens in both English and Tamil
- Check for text overflow issues
- Verify button sizes accommodate Tamil text

## 🚀 Quick Migration Steps

1. **Import localization**: Add `import '../../generated/l10n.dart';`
2. **Replace hardcoded text**: Change `'Login'` to `S.of(context).login`
3. **Test in Tamil**: Change language and verify UI
4. **Handle edge cases**: Check for text overflow or layout issues

Your app now supports professional Tamil localization! 🌾