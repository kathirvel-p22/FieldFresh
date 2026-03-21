# FieldFresh Verification System Test Guide

## Overview
This guide provides step-by-step instructions to test the comprehensive verification system implemented in FieldFresh.

## Prerequisites
1. Database setup completed with `VERIFICATION_SYSTEM_DATABASE.sql`
2. App running with verification services enabled
3. Test devices with camera and location permissions

## Test Scenarios

### 1. New User Registration & Verification Flow

#### Test Case 1.1: Farmer Registration
1. **Register as Farmer**
   - Open app and select "Register as Farmer"
   - Complete basic registration (name, phone, password)
   - Should be redirected to KYC screen
   - Complete KYC form with farm details
   - Should be redirected to VerificationFlowScreen

2. **Phone Verification**
   - Enter phone number in verification flow
   - Tap "Send OTP"
   - Verify OTP is received (check logs if using test mode)
   - Enter correct OTP
   - Should see "Phone verified successfully" message
   - Progress should show 25% complete

3. **Document Verification**
   - Select document type (Aadhar/PAN/Driving License)
   - Take clear photos of document (front and back if required)
   - Submit document
   - Should see "Document submitted for verification" message
   - Progress should show 50% complete

4. **Location Verification**
   - Enter farm address
   - Grant location permissions when prompted
   - Take photo at current location
   - Should see "Location verified successfully" message
   - Progress should show 75% complete

5. **Selfie Verification**
   - Take selfie while holding ID document
   - Should see "Selfie submitted for verification" message
   - Progress should show 100% complete
   - Should see "Complete Verification" button

#### Test Case 1.2: Customer Registration
- Follow similar steps as farmer but with customer-specific messaging
- Location verification is optional for customers
- Should complete with 4 verification steps

### 2. Admin Verification Management

#### Test Case 2.1: Admin Dashboard Access
1. **Login as Admin**
   - Use admin credentials
   - Navigate to Admin Dashboard
   - Should see "Verification Management" option

2. **View Pending Verifications**
   - Open Verification Management screen
   - Should see list of pending verifications
   - Filter by verification type (phone, document, location, selfie)
   - Each verification should show:
     - User info
     - Verification type
     - Submitted images (if applicable)
     - Submission timestamp

#### Test Case 2.2: Approve Verifications
1. **Approve Document Verification**
   - Select a pending document verification
   - Review submitted images by tapping on them
   - Tap "Approve" button
   - Should see success message
   - Verification should disappear from pending list

2. **Reject Verification**
   - Select a pending verification
   - Tap "Reject" button
   - Enter rejection reason
   - Should see rejection confirmation
   - User should receive notification (if implemented)

### 3. Progressive Disclosure Integration

#### Test Case 3.1: Customer Order Flow
1. **Browse Products (Unverified Farmer)**
   - Login as customer
   - Browse products from unverified farmer
   - Should see basic farmer info only
   - Should see "⚠️ Farmer verification pending" message

2. **Place Order**
   - Add product to cart
   - Complete checkout
   - Order status: "pending"
   - Should still see limited farmer info

3. **Order Progression**
   - Admin/Farmer changes order to "packed"
   - Customer should see masked phone number
   - Should see "⚠️ Farmer not fully verified" if farmer unverified

4. **Verified Farmer Comparison**
   - Repeat with verified farmer
   - Should see full contact details when order is dispatched
   - Should see "✅ Full farmer contact details available"

#### Test Case 3.2: Farmer Order Management
1. **Receive Order (Unverified Customer)**
   - Login as farmer
   - View incoming order from unverified customer
   - Should see basic customer info only
   - Should see verification warning

2. **Confirm Order**
   - Confirm the order
   - Should see customer contact details
   - Should see verification status warning if customer unverified

### 4. Verification Status Display

#### Test Case 4.1: Profile Screens
1. **User Profile**
   - Navigate to user profile
   - Should see verification status widget
   - Should show progress percentage
   - Should list missing verifications

2. **Farmer/Customer Lists (Admin)**
   - View farmers/customers list in admin panel
   - Should see verification badges next to names
   - Should be able to filter by verification status

#### Test Case 4.2: Order Screens
1. **Order Details**
   - View order details as customer/farmer
   - Should see verification status of other party
   - Should see appropriate disclosure messages

### 5. Error Handling & Edge Cases

#### Test Case 5.1: Permission Denials
1. **Camera Permission Denied**
   - Deny camera permission during document/selfie verification
   - Should show appropriate error message
   - Should provide guidance to enable permissions

2. **Location Permission Denied**
   - Deny location permission during location verification
   - Should show error message
   - Should allow manual address entry as fallback

#### Test Case 5.2: Network Issues
1. **Upload Failures**
   - Simulate network issues during image upload
   - Should show retry option
   - Should not lose captured images

2. **Verification Service Errors**
   - Test with invalid user IDs
   - Should handle gracefully without crashes

### 6. Database Verification

#### Test Case 6.1: Data Integrity
1. **Check Database Tables**
   ```sql
   -- Verify verification records
   SELECT * FROM user_verifications WHERE user_id = 'test-user-id';
   
   -- Check user verification status
   SELECT id, name, verification_status, verification_progress 
   FROM users WHERE verification_status != 'unverified';
   
   -- Verify OTP records
   SELECT * FROM otp_verifications WHERE phone_number = '+91XXXXXXXXXX';
   ```

2. **Trigger Functionality**
   - Insert/update verification record
   - Check if user's verification_status and verification_progress update automatically

### 7. Performance Testing

#### Test Case 7.1: Large Image Uploads
1. **High Resolution Images**
   - Take high-resolution photos for document verification
   - Should compress/resize appropriately
   - Upload should complete within reasonable time

2. **Multiple Concurrent Verifications**
   - Test multiple users going through verification simultaneously
   - Should handle concurrent requests without issues

## Expected Results Summary

### Successful Verification Flow
- ✅ User completes all 4 verification steps
- ✅ Admin can review and approve/reject verifications
- ✅ Progressive disclosure works based on verification status
- ✅ Verification badges display correctly
- ✅ Database triggers update user status automatically

### Security & Privacy
- ✅ Unverified users have limited access to contact information
- ✅ Location data is protected until appropriate order status
- ✅ Phone numbers are masked appropriately
- ✅ Verification images are securely stored

### User Experience
- ✅ Clear progress indicators throughout verification
- ✅ Helpful error messages and guidance
- ✅ Smooth navigation between verification steps
- ✅ Appropriate messaging based on verification status

## Troubleshooting

### Common Issues
1. **OTP Not Received**: Check Supabase auth configuration
2. **Image Upload Fails**: Verify Supabase storage setup and RLS policies
3. **Location Not Captured**: Ensure location permissions and GPS enabled
4. **Verification Status Not Updating**: Check database triggers and functions

### Debug Commands
```sql
-- Reset user verification for testing
DELETE FROM user_verifications WHERE user_id = 'test-user-id';
UPDATE users SET verification_status = 'unverified', verification_progress = 0 WHERE id = 'test-user-id';

-- Check verification requirements
SELECT * FROM verification_requirements WHERE user_role = 'farmer';

-- View all verification templates
SELECT * FROM verification_templates WHERE is_active = true;
```

## Test Completion Checklist
- [ ] New user registration and verification flow
- [ ] Admin verification management
- [ ] Progressive disclosure integration
- [ ] Verification status display
- [ ] Error handling and edge cases
- [ ] Database integrity and triggers
- [ ] Performance with large images
- [ ] Security and privacy features
- [ ] User experience and messaging

## Next Steps
After successful testing:
1. Deploy verification system to production
2. Monitor verification completion rates
3. Gather user feedback on verification flow
4. Implement additional verification types if needed
5. Add automated verification for certain document types