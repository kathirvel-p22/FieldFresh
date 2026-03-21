import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import '../../services/verification_service.dart';

class VerificationFlowScreen extends StatefulWidget {
  final String userId;
  final String userRole;
  
  const VerificationFlowScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<VerificationFlowScreen> createState() => _VerificationFlowScreenState();
}

class _VerificationFlowScreenState extends State<VerificationFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _loading = false;
  
  // Verification data
  Map<VerificationType, VerificationStatus> _verificationStatus = {};
  String? _phoneNumber;
  String? _selectedDocumentType;
  final List<XFile> _documentImages = [];
  String? _address;
  
  final List<String> _documentTypes = [
    'aadhar',
    'pan', 
    'driving_license',
    'passport',
  ];
  
  final Map<String, String> _documentNames = {
    'aadhar': 'Aadhar Card',
    'pan': 'PAN Card',
    'driving_license': 'Driving License',
    'passport': 'Passport',
  };

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() => _loading = true);
    try {
      final status = await VerificationService().getUserVerificationStatus(widget.userId);
      setState(() {
        _verificationStatus = status;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showDemoVerificationOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧪 Demo Mode'),
        content: const Text(
          'Skip phone verification for testing purposes. '
          'This will mark your phone as verified without sending an actual OTP.\n\n'
          'Continue with demo verification?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Mark phone as verified in demo mode
              setState(() => _loading = true);
              
              try {
                // Simulate verification success
                await Future.delayed(const Duration(seconds: 1));
                
                // Update verification status
                _verificationStatus[VerificationType.phone] = VerificationStatus.approved;
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📱 Phone verified in demo mode'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  
                  setState(() {});
                  _nextStep();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Demo verification failed: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } finally {
                setState(() => _loading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Continue Demo'),
          ),
        ],
      ),
    );
  }

  void _showSkipVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Skip Verification'),
        content: const Text(
          'This will skip the verification process for testing purposes. '
          'In production, users should complete verification.\n\n'
          'Continue to dashboard without verification?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Navigate directly to appropriate dashboard
              final route = widget.userRole == 'farmer' 
                  ? AppRoutes.farmerHome 
                  : AppRoutes.customerHome;
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Verification skipped for testing'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                context.go(route);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Skip & Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Skip verification for testing
          TextButton(
            onPressed: _showSkipVerificationDialog,
            child: const Text(
              'Skip for Testing',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Complete your verification to start using FieldFresh',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step ${_currentStep + 1} of 4',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Verification steps
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildPhoneVerificationStep(),
                _buildDocumentVerificationStep(),
                _buildLocationVerificationStep(),
                _buildSelfieVerificationStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneVerificationStep() {
    final isVerified = _verificationStatus[VerificationType.phone] == VerificationStatus.approved;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone_android, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'Phone Verification',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'We need to verify your phone number to ensure account security and enable order notifications.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          
          if (isVerified) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Phone number verified successfully!',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _nextStep(),
                child: const Text('Continue to Document Verification'),
              ),
            ),
          ] else ...[
            TextField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixText: '+91 ',
                border: OutlineInputBorder(),
                hintText: '10-digit mobile number',
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: (value) {
                setState(() {
                  // Only set phone number if it's a valid 10-digit number
                  if (value.length == 10 && RegExp(r'^\d{10}$').hasMatch(value)) {
                    _phoneNumber = '+91$value';
                  } else {
                    _phoneNumber = null;
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _phoneNumber != null && !_loading ? _sendOTP : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _phoneNumber != null ? AppColors.primary : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send OTP',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            // Add demo mode option for testing
            TextButton(
              onPressed: () => _showDemoVerificationOption(),
              child: const Text(
                'Skip Verification (Demo Mode)',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentVerificationStep() {
    final isVerified = _verificationStatus[VerificationType.document] == VerificationStatus.approved;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'Document Verification',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload a clear photo of your government-issued ID for identity verification.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          
          if (isVerified) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Document verified successfully!',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _nextStep(),
                child: const Text('Continue to Location Verification'),
              ),
            ),
          ] else ...[
            // Document type selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Document Type',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedDocumentType,
              items: _documentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_documentNames[type] ?? type),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDocumentType = value),
            ),
            const SizedBox(height: 16),
            
            // Document images
            if (_documentImages.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _documentImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _documentImages[index].path,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _documentImages.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Add document button
            OutlinedButton.icon(
              onPressed: _pickDocumentImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(_documentImages.isEmpty ? 'Take Photo of Document' : 'Add Another Photo'),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDocumentType != null && _documentImages.isNotEmpty
                    ? _submitDocumentVerification
                    : null,
                child: const Text('Submit Document'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationVerificationStep() {
    final isVerified = _verificationStatus[VerificationType.location] == VerificationStatus.approved;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'Location Verification',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            widget.userRole == 'farmer' 
              ? 'Verify your farm location by taking a photo at your current location.'
              : 'Verify your address by taking a photo at your current location.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          
          if (isVerified) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Location verified successfully!',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _nextStep(),
                child: const Text('Continue to Selfie Verification'),
              ),
            ),
          ] else ...[
            TextField(
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                hintText: 'Enter your complete address',
              ),
              maxLines: 3,
              onChanged: (value) => _address = value,
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info),
                  SizedBox(height: 8),
                  Text(
                    'We will capture your current GPS location and take a photo for verification. Make sure you are at the address you entered above.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _address != null && _address!.isNotEmpty
                    ? _submitLocationVerification
                    : null,
                child: const Text('Verify Location'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelfieVerificationStep() {
    final isVerified = _verificationStatus[VerificationType.selfie] == VerificationStatus.approved;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.face, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'Selfie Verification',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Take a selfie while holding your ID document to complete the verification process.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          
          if (isVerified) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verification completed successfully!',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeVerification,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                child: const Text('Complete Verification'),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Column(
                children: [
                  Icon(Icons.camera_front, color: AppColors.warning, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Hold your ID document clearly visible next to your face and take a selfie.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitSelfieVerification,
                child: const Text('Take Selfie'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendOTP() async {
    if (_phoneNumber == null) return;
    
    setState(() => _loading = true);
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Sending OTP...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final success = await VerificationService().sendPhoneOTP(_phoneNumber!);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ OTP sent successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to OTP screen
        final verified = await context.push('/otp-verify', extra: {
          'phone': _phoneNumber,
          'purpose': 'verification',
        });
        
        if (verified == true) {
          await _loadVerificationStatus();
          _nextStep();
        }
      } else if (mounted) {
        throw Exception('Failed to send OTP. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to send OTP';
        
        if (e.toString().contains('Invalid phone number')) {
          errorMessage = 'Invalid phone number format. Please check and try again.';
        } else if (e.toString().contains('Rate limit')) {
          errorMessage = 'Too many OTP requests. Please wait a few minutes.';
        } else {
          errorMessage = 'OTP service error: ${e.toString()}';
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🚫 OTP Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                const SizedBox(height: 16),
                const Text(
                  'Troubleshooting:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Check your internet connection\n'
                  '• Verify phone number is correct\n'
                  '• Try again in a few minutes\n'
                  '• Use demo mode for testing',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDemoVerificationOption();
                },
                child: const Text('Try Demo Mode'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDocumentImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() => _documentImages.add(image));
    }
  }

  Future<void> _submitDocumentVerification() async {
    if (_selectedDocumentType == null || _documentImages.isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final verificationId = await VerificationService().submitDocumentVerification(
        userId: widget.userId,
        documentType: _selectedDocumentType!,
        images: _documentImages,
      );
      
      if (verificationId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document submitted for verification')),
        );
        await _loadVerificationStatus();
        _nextStep();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit document: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitLocationVerification() async {
    if (_address == null || _address!.isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final verificationId = await VerificationService().submitLocationVerification(
        userId: widget.userId,
        address: _address!,
      );
      
      if (verificationId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location verified successfully')),
        );
        await _loadVerificationStatus();
        _nextStep();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify location: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitSelfieVerification() async {
    setState(() => _loading = true);
    try {
      final verificationId = await VerificationService().submitSelfieVerification(
        userId: widget.userId,
        documentType: _selectedDocumentType ?? 'aadhar',
      );
      
      if (verificationId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selfie submitted for verification')),
        );
        await _loadVerificationStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit selfie: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeVerification() {
    // Navigate to appropriate dashboard based on role
    if (widget.userRole == 'farmer') {
      context.go(AppRoutes.farmerHome);
    } else if (widget.userRole == 'customer') {
      context.go(AppRoutes.customerHome);
    } else {
      context.go(AppRoutes.adminDashboard);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}