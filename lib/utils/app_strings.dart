class AppStrings {
  static String locale = 'vi'; // 'vi' hoặc 'en'
  
  static final Map<String, Map<String, String>> _strings = {
    // Common
    'appTitle': {'vi': 'SOS App UTH', 'en': 'SOS App UTH'},
    'cancel': {'vi': 'Hủy', 'en': 'Cancel'},
    'confirm': {'vi': 'Xác nhận', 'en': 'Confirm'},
    'save': {'vi': 'Lưu', 'en': 'Save'},
    'close': {'vi': 'Đóng', 'en': 'Close'},
    'loading': {'vi': 'Đang tải...', 'en': 'Loading...'},
    'error': {'vi': 'Lỗi', 'en': 'Error'},
    'success': {'vi': 'Thành công', 'en': 'Success'},
    'or': {'vi': 'Hoặc', 'en': 'Or'},
    
    // Auth
    'login': {'vi': 'Đăng Nhập', 'en': 'Login'},
    'signup': {'vi': 'Đăng Ký', 'en': 'Sign Up'},
    'welcome': {'vi': 'Chào mừng bạn!', 'en': 'Welcome!'},
    'email': {'vi': 'Email', 'en': 'Email'},
    'emailOrPhone': {'vi': 'Email hoặc số điện thoại', 'en': 'Email or phone number'},
    'password': {'vi': 'Mật khẩu', 'en': 'Password'},
    'rememberMe': {'vi': 'Ghi nhớ', 'en': 'Remember me'},
    'forgotPassword': {'vi': 'Quên mật khẩu?', 'en': 'Forgot password?'},
    'loginWithGoogle': {'vi': 'Đăng nhập với Google', 'en': 'Sign in with Google'},
    'loginSuccess': {'vi': 'Đăng nhập thành công ✅', 'en': 'Login successful ✅'},
    'loginError': {'vi': 'Sai thông tin đăng nhập ❌', 'en': 'Invalid credentials ❌'},
    'noAccount': {'vi': 'Chưa có tài khoản? ', 'en': "Don't have an account? "},
    'signupNow': {'vi': 'Đăng ký ngay', 'en': 'Sign up now'},
    'pleaseEnterInfo': {'vi': 'Vui lòng nhập thông tin', 'en': 'Please enter information'},
    
    // Settings
    'settings': {'vi': 'Cài đặt', 'en': 'Settings'},
    'darkMode': {'vi': 'Chế độ tối', 'en': 'Dark Mode'},
    'darkModeOn': {'vi': 'Đang bật', 'en': 'Enabled'},
    'darkModeOff': {'vi': 'Đang tắt', 'en': 'Disabled'},
    'language': {'vi': 'Ngôn ngữ', 'en': 'Language'},
    'vietnamese': {'vi': 'Tiếng Việt', 'en': 'Vietnamese'},
    'english': {'vi': 'Tiếng Anh', 'en': 'English'},
    'selectLanguage': {'vi': 'Chọn ngôn ngữ', 'en': 'Select Language'},
    
    // Navigation
    'home': {'vi': 'Trang chủ', 'en': 'Home'},
    'activity': {'vi': 'Hoạt động', 'en': 'Activity'},
    'sos': {'vi': 'SOS', 'en': 'SOS'},
    'profile': {'vi': 'Hồ sơ', 'en': 'Profile'},
    
    // Account Page
    'noBioYet': {'vi': 'Chưa có giới thiệu bản thân', 'en': 'No bio yet'},
    'noYearOfBirth': {'vi': 'Chưa cập nhật năm sinh', 'en': 'Year not updated'},
    'editBio': {'vi': 'Chỉnh sửa giới thiệu', 'en': 'Edit bio'},
    'enterBio': {'vi': 'Nhập giới thiệu về bạn...', 'en': 'Enter your bio...'},
    'bioUpdated': {'vi': 'Đã cập nhật giới thiệu', 'en': 'Bio updated'},
    'uploading': {'vi': 'Đang tải lên...', 'en': 'Uploading...'},
    'changeAvatar': {'vi': 'Đổi ảnh đại diện', 'en': 'Change avatar'},
    'avatarUpdated': {'vi': 'Đã cập nhật ảnh đại diện', 'en': 'Avatar updated'},
    'myProfile': {'vi': 'Hồ sơ', 'en': 'Profile'},
    'viewEditInfo': {'vi': 'Xem và chỉnh sửa thông tin', 'en': 'View and edit info'},
    'volunteerStatus': {'vi': 'Trạng thái hoạt động', 'en': 'Activity status'},
    'readyForRequests': {'vi': 'Đang sẵn sàng nhận yêu cầu', 'en': 'Ready for requests'},
    'notReceivingSOS': {'vi': 'Tắt nhận yêu cầu SOS', 'en': 'Not receiving SOS'},
    'viewVolunteerProfile': {'vi': 'Xem hồ sơ tình nguyện viên', 'en': 'View volunteer profile'},
    'manageVolunteerProfile': {'vi': 'Quản lý hồ sơ TNV của bạn', 'en': 'Manage your volunteer profile'},
    'pendingApproval': {'vi': 'Hồ sơ đang chờ duyệt', 'en': 'Profile pending approval'},
    'waitForAdmin': {'vi': 'Vui lòng chờ quản trị viên xác nhận', 'en': 'Please wait for admin confirmation'},
    'underReview': {'vi': 'Đang xét duyệt', 'en': 'Under review'},
    'registrationRejected': {'vi': 'Đăng ký bị từ chối', 'en': 'Registration rejected'},
    'tapToReregister': {'vi': 'Nhấn để đăng ký lại', 'en': 'Tap to re-register'},
    'becomeVolunteer': {'vi': 'Đăng ký làm tình nguyện viên', 'en': 'Become a volunteer'},
    'joinRescueCommunity': {'vi': 'Tham gia cứu hộ cộng đồng', 'en': 'Join rescue community'},
    'customizeApp': {'vi': 'Tùy chỉnh ứng dụng', 'en': 'Customize app'},
    'createPost': {'vi': 'Đăng bài viết', 'en': 'Create post'},  
    'createPostSubtitle': {'vi': 'Tạo bài viết mới cho cộng đồng', 'en': 'Create new post for community'},
    'aboutApp': {'vi': 'Về ứng dụng', 'en': 'About app'},
    'versionInfo': {'vi': 'Thông tin phiên bản', 'en': 'Version info'},
    'sosRequestOn': {'vi': 'Đã bật nhận yêu cầu SOS', 'en': 'SOS requests enabled'},
    'sosRequestOff': {'vi': 'Đã tắt nhận yêu cầu SOS', 'en': 'SOS requests disabled'},
    
    // SOS
    'sosEmergency': {'vi': 'Khẩn Cấp SOS', 'en': 'SOS Emergency'},
    'sosNotYet': {'vi': 'Chưa', 'en': 'Not yet'},
    'sosComplete': {'vi': 'Hoàn thành', 'en': 'Complete'},
    'sosCompleteSuccess': {'vi': 'Đã hoàn thành ứng cứu thành công!', 'en': 'Rescue completed successfully!'},
    'backToHome': {'vi': 'Về trang chủ', 'en': 'Back to home'},
    'victimInfo': {'vi': 'Thông tin người cần cứu', 'en': 'Victim information'},
    'cannotOpenMaps': {'vi': 'Không thể mở Google Maps', 'en': 'Cannot open Google Maps'},
  };
  
  // Lấy string theo key
  static String get(String key) {
    return _strings[key]?[locale] ?? key;
  }
  
  // Đổi ngôn ngữ
  static void setLocale(String newLocale) {
    locale = newLocale;
  }
}
