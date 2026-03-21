import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FieldFresh'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Farm to Customer Direct'**
  String get appTagline;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get selectRole;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Choose your role to get started'**
  String get chooseRole;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get chooseLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Mobile Number'**
  String get enterMobileNumber;

  /// No description provided for @sendOtpSignUp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP & Sign Up'**
  String get sendOtpSignUp;

  /// No description provided for @signInInstantly.
  ///
  /// In en, this message translates to:
  /// **'Sign In Instantly'**
  String get signInInstantly;

  /// No description provided for @newToFieldFresh.
  ///
  /// In en, this message translates to:
  /// **'New to FieldFresh? Create your account'**
  String get newToFieldFresh;

  /// No description provided for @wellSendOtp.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send an OTP to verify your number'**
  String get wellSendOtp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in instantly'**
  String get alreadyHaveAccount;

  /// No description provided for @noOtpNeeded.
  ///
  /// In en, this message translates to:
  /// **'No OTP needed - just enter your number'**
  String get noOtpNeeded;

  /// No description provided for @byContinguing.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Privacy Policy'**
  String get byContinguing;

  /// No description provided for @enterValid10Digit.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit number'**
  String get enterValid10Digit;

  /// No description provided for @testingConnection.
  ///
  /// In en, this message translates to:
  /// **'Testing connection...'**
  String get testingConnection;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// No description provided for @cannotConnectServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server. Please check your internet connection and try again.'**
  String get cannotConnectServer;

  /// No description provided for @numberAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This number is already registered. Please use Sign In instead.'**
  String get numberAlreadyRegistered;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please complete your profile setup'**
  String get welcomeBack;

  /// No description provided for @welcomeBackSimple.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBackSimple;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @sendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Sending OTP...'**
  String get sendingOtp;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP sent! Please verify to create your account.'**
  String get otpSent;

  /// No description provided for @otpError.
  ///
  /// In en, this message translates to:
  /// **'OTP Error'**
  String get otpError;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get demoMode;

  /// No description provided for @demoModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Demo mode allows you to test the app without OTP verification. This is useful for testing when OTP service is not available. Continue with demo mode?'**
  String get demoModeDescription;

  /// No description provided for @continuDemo.
  ///
  /// In en, this message translates to:
  /// **'Continue Demo'**
  String get continuDemo;

  /// No description provided for @demoAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Demo account created! Complete your profile setup.'**
  String get demoAccountCreated;

  /// No description provided for @demoModeFailed.
  ///
  /// In en, this message translates to:
  /// **'Demo mode failed'**
  String get demoModeFailed;

  /// No description provided for @postTodaysHarvest.
  ///
  /// In en, this message translates to:
  /// **'Post Today\'s Harvest'**
  String get postTodaysHarvest;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @addProductPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add product photos'**
  String get addProductPhotos;

  /// No description provided for @cameraOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Camera or Gallery'**
  String get cameraOrGallery;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get searchCategories;

  /// No description provided for @vegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get vegetables;

  /// No description provided for @fruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get fruits;

  /// No description provided for @grains.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get grains;

  /// No description provided for @rootVegs.
  ///
  /// In en, this message translates to:
  /// **'Root Vegs'**
  String get rootVegs;

  /// No description provided for @machinery.
  ///
  /// In en, this message translates to:
  /// **'Machinery'**
  String get machinery;

  /// No description provided for @leafyGreens.
  ///
  /// In en, this message translates to:
  /// **'Leafy Greens'**
  String get leafyGreens;

  /// No description provided for @dairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get dairy;

  /// No description provided for @herbs.
  ///
  /// In en, this message translates to:
  /// **'Herbs'**
  String get herbs;

  /// No description provided for @flowers.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get flowers;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @priceRupees.
  ///
  /// In en, this message translates to:
  /// **'Price (₹)'**
  String get priceRupees;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @availableQuantity.
  ///
  /// In en, this message translates to:
  /// **'Available Quantity'**
  String get availableQuantity;

  /// No description provided for @validFor12Hours.
  ///
  /// In en, this message translates to:
  /// **'Valid for 12 hours'**
  String get validFor12Hours;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @farmerDescription.
  ///
  /// In en, this message translates to:
  /// **'Sell your harvest directly to customers'**
  String get farmerDescription;

  /// No description provided for @customerDescription.
  ///
  /// In en, this message translates to:
  /// **'Buy fresh produce from local farms'**
  String get customerDescription;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @farmers.
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get farmers;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to exit FieldFresh?'**
  String get exitAppMessage;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @farmerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Farmer Dashboard'**
  String get farmerDashboard;

  /// No description provided for @marketIsLive.
  ///
  /// In en, this message translates to:
  /// **'Market is live!'**
  String get marketIsLive;

  /// No description provided for @goLive.
  ///
  /// In en, this message translates to:
  /// **'Go Live'**
  String get goLive;

  /// No description provided for @activeListings.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListings;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @postHarvest.
  ///
  /// In en, this message translates to:
  /// **'Post Harvest'**
  String get postHarvest;

  /// No description provided for @liveOrders.
  ///
  /// In en, this message translates to:
  /// **'Live Orders'**
  String get liveOrders;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @groupBuy.
  ///
  /// In en, this message translates to:
  /// **'Group Buy'**
  String get groupBuy;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage system and monitor users'**
  String get adminDescription;

  /// No description provided for @addProductPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Product Photo'**
  String get addProductPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @captureFreshProductImage.
  ///
  /// In en, this message translates to:
  /// **'Capture fresh product image'**
  String get captureFreshProductImage;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @selectExistingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Select existing photos'**
  String get selectExistingPhotos;

  /// No description provided for @productNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Product name required'**
  String get productNameRequired;

  /// No description provided for @egFreshTomatoes.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fresh Tomatoes'**
  String get egFreshTomatoes;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter valid price'**
  String get enterValidPrice;

  /// No description provided for @mustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0'**
  String get mustBeGreaterThanZero;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter valid number'**
  String get enterValidNumber;

  /// No description provided for @validForHours.
  ///
  /// In en, this message translates to:
  /// **'Valid for {hours} hours'**
  String validForHours(int hours);

  /// No description provided for @aiSuggestionForCategory.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion for \'{category}\': {hours} hrs'**
  String aiSuggestionForCategory(String category, int hours);

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @tellCustomersAboutProduce.
  ///
  /// In en, this message translates to:
  /// **'Tell customers about your produce...'**
  String get tellCustomersAboutProduce;

  /// No description provided for @farmLocationDetected.
  ///
  /// In en, this message translates to:
  /// **'Farm location detected'**
  String get farmLocationDetected;

  /// No description provided for @detectingFarmLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting farm location...'**
  String get detectingFarmLocation;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @verifyCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify & Create Account'**
  String get verifyCreateAccount;

  /// No description provided for @weSentVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit verification code to'**
  String get weSentVerificationCode;

  /// No description provided for @verifyingYourCode.
  ///
  /// In en, this message translates to:
  /// **'Verifying your code...'**
  String get verifyingYourCode;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get didntReceiveCode;

  /// No description provided for @resendInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInSeconds(int seconds);

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhoneNumber;

  /// No description provided for @afterVerificationComplete.
  ///
  /// In en, this message translates to:
  /// **'After verification, you\'ll complete your profile setup to start using FieldFresh.'**
  String get afterVerificationComplete;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone verified! Creating your account...'**
  String get phoneVerified;

  /// No description provided for @verificationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Verification successful!'**
  String get verificationSuccessful;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please try again.'**
  String get invalidOtp;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @otpResentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'OTP resent successfully!'**
  String get otpResentSuccessfully;

  /// No description provided for @failedToResendOtp.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP'**
  String get failedToResendOtp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @validPrice.
  ///
  /// In en, this message translates to:
  /// **'Valid Price (must be greater than 0)'**
  String get validPrice;

  /// No description provided for @productPhoto.
  ///
  /// In en, this message translates to:
  /// **'Product Photo'**
  String get productPhoto;

  /// No description provided for @userLogin.
  ///
  /// In en, this message translates to:
  /// **'User Login (please login again)'**
  String get userLogin;

  /// No description provided for @farmLocation.
  ///
  /// In en, this message translates to:
  /// **'Farm Location (enable GPS)'**
  String get farmLocation;

  /// No description provided for @validQuantity.
  ///
  /// In en, this message translates to:
  /// **'Valid Quantity (must be greater than 0)'**
  String get validQuantity;

  /// No description provided for @missingRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Missing required fields:'**
  String get missingRequiredFields;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get gettingLocation;

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location required. Please enable GPS and try again.'**
  String get locationRequired;

  /// No description provided for @harvestPosted.
  ///
  /// In en, this message translates to:
  /// **'🌾 Harvest posted! Nearby customers notified!'**
  String get harvestPosted;

  /// No description provided for @errorPostingProduct.
  ///
  /// In en, this message translates to:
  /// **'Error posting product'**
  String get errorPostingProduct;

  /// No description provided for @validForHoursText.
  ///
  /// In en, this message translates to:
  /// **'Valid for {hours} hours'**
  String validForHoursText(int hours);

  /// No description provided for @expiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires: {time}'**
  String expiresAt(String time);

  /// No description provided for @aiSuggestionText.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion for \'{category}\': {hours} hrs'**
  String aiSuggestionText(String category, int hours);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'DISMISS'**
  String get dismiss;

  /// No description provided for @updateProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Update Profile Photo'**
  String get updateProfilePhoto;

  /// No description provided for @takeNewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take New Photo'**
  String get takeNewPhoto;

  /// No description provided for @chooseFromGalleryProfile.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGalleryProfile;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @customerOrders.
  ///
  /// In en, this message translates to:
  /// **'Customer Orders'**
  String get customerOrders;

  /// No description provided for @viewManageOrders.
  ///
  /// In en, this message translates to:
  /// **'View & manage orders'**
  String get viewManageOrders;

  /// No description provided for @allCustomers.
  ///
  /// In en, this message translates to:
  /// **'All Customers'**
  String get allCustomers;

  /// No description provided for @viewCustomerProfiles.
  ///
  /// In en, this message translates to:
  /// **'View customer profiles'**
  String get viewCustomerProfiles;

  /// No description provided for @salesAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Sales Analytics'**
  String get salesAnalytics;

  /// No description provided for @viewPerformanceCharts.
  ///
  /// In en, this message translates to:
  /// **'View your performance charts'**
  String get viewPerformanceCharts;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @manageAllProducts.
  ///
  /// In en, this message translates to:
  /// **'Manage all your products'**
  String get manageAllProducts;

  /// No description provided for @customerReviews.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customerReviews;

  /// No description provided for @seeWhatCustomersSay.
  ///
  /// In en, this message translates to:
  /// **'See what customers say'**
  String get seeWhatCustomersSay;

  /// No description provided for @bankUpiSettings.
  ///
  /// In en, this message translates to:
  /// **'Bank / UPI Settings'**
  String get bankUpiSettings;

  /// No description provided for @managePayoutMethods.
  ///
  /// In en, this message translates to:
  /// **'Manage payout methods'**
  String get managePayoutMethods;

  /// No description provided for @kycDocuments.
  ///
  /// In en, this message translates to:
  /// **'KYC Documents'**
  String get kycDocuments;

  /// No description provided for @verificationDocuments.
  ///
  /// In en, this message translates to:
  /// **'Verification documents'**
  String get verificationDocuments;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @trackYourOrders.
  ///
  /// In en, this message translates to:
  /// **'Track your orders'**
  String get trackYourOrders;

  /// No description provided for @savedFarmers.
  ///
  /// In en, this message translates to:
  /// **'Saved Farmers'**
  String get savedFarmers;

  /// No description provided for @yourFavouriteFarms.
  ///
  /// In en, this message translates to:
  /// **'Your favourite farms'**
  String get yourFavouriteFarms;

  /// No description provided for @deliveryAddresses.
  ///
  /// In en, this message translates to:
  /// **'Delivery Addresses'**
  String get deliveryAddresses;

  /// No description provided for @manageSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Manage saved addresses'**
  String get manageSavedAddresses;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @tamilHindiEnglish.
  ///
  /// In en, this message translates to:
  /// **'Tamil / Hindi / English'**
  String get tamilHindiEnglish;

  /// No description provided for @languageSettingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Language settings coming soon'**
  String get languageSettingsComingSoon;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @alertsHarvestBlasts.
  ///
  /// In en, this message translates to:
  /// **'Alerts & harvest blasts'**
  String get alertsHarvestBlasts;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @locationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get locationNotSet;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get imageUploadFailed;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @searchVegetablesFruits.
  ///
  /// In en, this message translates to:
  /// **'Search vegetables, fruits...'**
  String get searchVegetablesFruits;

  /// No description provided for @freshFrom.
  ///
  /// In en, this message translates to:
  /// **'Fresh from'**
  String get freshFrom;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @loadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @freshProducts.
  ///
  /// In en, this message translates to:
  /// **'Fresh Products'**
  String get freshProducts;

  /// No description provided for @nearbyFarms.
  ///
  /// In en, this message translates to:
  /// **'Nearby Farms'**
  String get nearbyFarms;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @packed.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get packed;

  /// No description provided for @dispatched.
  ///
  /// In en, this message translates to:
  /// **'Dispatched'**
  String get dispatched;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @markAsPacked.
  ///
  /// In en, this message translates to:
  /// **'Mark as Packed'**
  String get markAsPacked;

  /// No description provided for @markAsDispatched.
  ///
  /// In en, this message translates to:
  /// **'Mark as Dispatched'**
  String get markAsDispatched;

  /// No description provided for @noStatusOrders.
  ///
  /// In en, this message translates to:
  /// **'No {status} orders'**
  String noStatusOrders(String status);

  /// No description provided for @ordersWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Orders will appear here when customers buy your products'**
  String get ordersWillAppear;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orderStatus;

  /// No description provided for @orderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Order updated'**
  String get orderUpdated;

  /// No description provided for @errorUpdatingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error updating order'**
  String get errorUpdatingOrder;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @contactCustomer.
  ///
  /// In en, this message translates to:
  /// **'Contact Customer'**
  String get contactCustomer;

  /// No description provided for @viewLocation.
  ///
  /// In en, this message translates to:
  /// **'View Location'**
  String get viewLocation;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @freshMarket.
  ///
  /// In en, this message translates to:
  /// **'Fresh Market'**
  String get freshMarket;

  /// No description provided for @orderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// No description provided for @noFreshProduceNearby.
  ///
  /// In en, this message translates to:
  /// **'No fresh produce nearby right now'**
  String get noFreshProduceNearby;

  /// No description provided for @checkBackSoon.
  ///
  /// In en, this message translates to:
  /// **'Check back soon!'**
  String get checkBackSoon;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @loadingCustomerInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading customer info...'**
  String get loadingCustomerInfo;

  /// No description provided for @markAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get markAsDelivered;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @chatWithOurTeam.
  ///
  /// In en, this message translates to:
  /// **'Chat with our team'**
  String get chatWithOurTeam;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ta':
      return STa();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
