import 'language_controller.dart';

class L {
  static const _t = {
    'login': ['Login', 'تسجيل الدخول'],
    'signup': ['Sign Up', 'إنشاء حساب'],
    'login_arrow': ['Login →', 'دخول →'],
    'create_account': ['Create Account →', 'إنشاء حساب →'],
    'full_name': ['Full Name', 'الاسم الكامل'],
    'phone': ['Phone Number', 'رقم الهاتف'],
    'email': ['Email', 'البريد الإلكتروني'],
    'password': ['Password', 'كلمة المرور'],
    'no_account': [
      "Don't have an account? Sign Up",
      'ليس لديك حساب؟ أنشئ حساب',
    ],
    'email_required': ['Email is required', 'البريد الإلكتروني مطلوب'],

    'password_required': ['Password is required', 'كلمة المرور مطلوبة'],

    'password_min': [
      'Password must be at least 6 characters',
      'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
    ],
    'confirm_password': ['Confirm Password', 'تأكيد كلمة المرور'],

    'password_policy_title': [
      'Password must contain:',
      'يجب أن تحتوي كلمة المرور على:',
    ],

    'password_policy_1': ['8+ characters', '8 أحرف على الأقل'],

    'password_policy_2': ['Uppercase & lowercase letters', 'حروف كبيرة وصغيرة'],

    'password_policy_3': ['At least one number', 'رقم واحد على الأقل'],

    'password_policy_4': ['One special character', 'رمز خاص واحد'],

    'password_mismatch': [
      'Passwords do not match',
      'كلمتا المرور غير متطابقتين',
    ],

    'password_weak': [
      'Password must be 8+ chars, include upper, lower, number & symbol',
      'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل، وحرف كبير وصغير ورقم ورمز',
    ],

    'password_updated': [
      'Password updated successfully',
      'تم تحديث كلمة المرور بنجاح',
    ],

    'error_general': ['Something went wrong', 'حدث خطأ ما'],
    'error': ['Error', 'خطأ'],
    'success': ['Success', 'تم بنجاح'],
    'info': ['Info', 'معلومة'],

    // Auth general
    'err_general': ['Something went wrong', 'حدث خطأ غير متوقع'],
    'err_network': [
      'Network error. Please try again.',
      'خطأ في الشبكة، حاول مرة أخرى',
    ],
    'err_database': ['Database error occurred', 'حدث خطأ في قاعدة البيانات'],

    // Login / Signup
    'err_invalid_credentials': [
      'Invalid email or password',
      'البريد أو كلمة المرور غير صحيحة',
    ],
    'err_email_not_confirmed': [
      'Please confirm your email first',
      'يرجى تأكيد البريد الإلكتروني أولاً',
    ],
    'err_user_exists': ['Account already exists', 'الحساب موجود مسبقًا'],
    'login_success': ['Login successful', 'تم تسجيل الدخول بنجاح'],

    // Account exists custom sheet
    'account_exists_title': ['Account already exists', 'الحساب موجود مسبقًا'],
    'account_exists_msg': [
      'This email is already registered. Please log in instead.',
      'هذا البريد مسجّل مسبقًا. يرجى تسجيل الدخول بدلاً من إنشاء حساب.',
    ],

    // Reset password
    'reset_link_sent': [
      'Password reset link has been sent to your email.',
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.',
    ],
    'err_reset_failed': [
      'Failed to send reset link',
      'فشل إرسال رابط إعادة التعيين',
    ],

    // Validation
    'email_invalid': [
      'Invalid email format',
      'صيغة البريد الإلكتروني غير صحيحة',
    ],

    'name_required': ['Name is required', 'الاسم مطلوب'],
    'phone_invalid': ['Invalid phone number', 'رقم الهاتف غير صحيح'],

    // Buttons
    'forgot_password': ['Forgot Password?', 'نسيت كلمة المرور؟'],

    'have_account': [
      'Already have an account? Login',
      'لديك حساب بالفعل؟ سجل دخول',
    ],

    'phone_required': ['Phone number is required', 'رقم الهاتف مطلوب'],

    'login_signup': ['Login / Sign Up', 'تسجيل الدخول / إنشاء حساب'],

    'reset_password': ['Reset Password', 'إعادة تعيين كلمة المرور'],
    'confirm_location': ['Confirm Location', 'تأكيد الموقع'],
    'new_password': ['New Password', 'كلمة المرور الجديدة'],

    'update_password': ['Update Password', 'تحديث كلمة المرور'],

    'err_auth_failed': [
      'Authentication failed. Please check your credentials.',
      'تعذّر تسجيل الدخول، تأكد من البريد الإلكتروني وكلمة المرور.',
    ],
    'password_policy_full': [
      'Password must contain:',
      'يجب أن تحتوي كلمة المرور على:',
    ],
    'select_location': ['Select Location', 'اختر الموقع'],
    'password_min_chars': ['• 8+ characters', '• 8 أحرف على الأقل'],

    'password_upper_lower': [
      '• Uppercase & lowercase letters',
      '• حروف كبيرة وصغيرة',
    ],
    'or_continue_with': ['Or continue with', 'أو المتابعة باستخدام'],

    'password_number': ['• At least one number', '• رقم واحد على الأقل'],

    'password_special': ['• One special character', '• رمز خاص واحد'],
    'password_not_match': [
      'Passwords do not match',
      'كلمتا المرور غير متطابقتين',
    ],

    'enter_email_first': [
      'Please enter your email first',
      'يرجى إدخال البريد الإلكتروني أولًا',
    ],

    'err_auth': [
      'Invalid email or password.',
      'البريد الإلكتروني أو كلمة المرور غير صحيحة',
    ],
    'login_required_to_order': [
      'Please login to place an order.',
      'يجب تسجيل الدخول لإتمام الطلب',
    ],

    'brand_ar': ['Century Fries', 'سنشري فرايز'],

    'phone_with_code': [
      'Phone number with country code',
      'رقم الهاتف مع رمز الدولة',
    ],
    'preview_mode': ['Preview Mode', 'وضع المعاينة'],
    'preview_customer_home': [
      'Preview Customer Home',
      'معاينة الصفحة الرئيسية للعميل',
    ],
    'edit_size': ['Edit Size', 'تعديل القياس'],
    'delete_size': ['Delete Size', 'حذف القياس'],
    'delete_confirmation': [
      'Are you sure you want to delete this item?',
      'هل أنت متأكد من حذف هذا العنصر؟',
    ],
    'size_name_en': ['Size Name (EN)', 'اسم القياس بالإنجليزية'],
    'size_name_ar': ['Size Name (AR)', 'اسم القياس بالعربية'],
    'sort_order': ['Sort Order', 'الترتيب'],
    'is_active': ['Active', 'نشط'],
    'added_successfully': ['Added successfully', 'تمت الإضافة بنجاح'],
    'deleted_successfully': ['Deleted successfully', 'تم الحذف بنجاح'],
    'please_fill_all_fields': [
      'Please fill all required fields',
      'يرجى تعبئة جميع الحقول المطلوبة',
    ],

    'phone_invalid_format': [
      'Invalid phone format (e.g. +971XXXXXXXXX)',
      'صيغة رقم الهاتف غير صحيحة (مثال: +971XXXXXXXXX)',
    ],
    'enter_otp': ['Enter OTP code', 'أدخل رمز التحقق'],
    'otp_too_short': ['OTP code is too short', 'رمز التحقق قصير جدًا'],
    'otp_sent_to': ['OTP sent to', 'تم إرسال رمز التحقق إلى'],
    'resend_in': ['Resend in', 'إعادة الإرسال بعد'],
    'resend_otp': ['Resend OTP', 'إعادة إرسال الرمز'],
    'change': ['Change', 'تغيير'],
    'otp_will_be_sent': [
      'An OTP will be sent to your number',
      'سيتم إرسال رمز تحقق إلى رقمك',
    ],

    'type_to_detect': [
      'Type to detect input type',
      'اكتب ليتم التعرف تلقائيًا',
    ],
    'email_or_phone': ['Email or phone', 'البريد الإلكتروني أو رقم الهاتف'],
    'field_required': ['This field is required', 'هذا الحقل مطلوب'],

    'send_otp': ['Send OTP', 'إرسال الرمز'],
    'verify_otp': ['Verify OTP', 'تأكيد الرمز'],

    'google': ['Google', 'Google'],

    'otp_sent_title': ['OTP Sent', 'تم إرسال الرمز'],
    'otp_sent_message': [
      'Check your messages for the verification code.',
      'تحقق من الرسائل للحصول على رمز التحقق.',
    ],

    'err_phone_provider_disabled': [
      'SMS verification is currently unavailable.',
      'خدمة التحقق عبر الرسائل غير متاحة حاليًا.',
    ],

    'err_otp_invalid': [
      'Invalid or expired OTP code',
      'رمز التحقق غير صحيح أو منتهي',
    ],
    'err_too_many_requests': [
      'Too many requests. Please try again later.',
      'طلبات كثيرة جدًا. حاول لاحقًا.',
    ],

    // Cart
    'cart_title': ['Your Cart', 'سلة المشتريات'],
    'clear': ['Clear', 'مسح'],
    'cart_empty': ['Your cart is empty', 'سلة المشتريات فارغة'],
    'discount': ['Discount', 'الخصم'],
    'total': ['Total', 'الإجمالي'],
    'checkout_btn': ['Proceed to Checkout', 'المتابعة للدفع'],

    // Checkout
    'checkout': ['Checkout', 'الدفع'],
    'how_order': ['How would you like to order?', 'كيف ترغب الطلب؟'],
    'delivery': ['Delivery', 'توصيل'],
    'delivery_desc': ['Delivered to your door', 'التوصيل إلى باب المنزل'],
    'pickup': ['Pickup', 'استلام'],
    'pickup_desc': ['Pick up at restaurant', 'الاستلام من المطعم'],
    'dinein': ['Dine-In', 'داخل المطعم'],
    'dinein_desc': ['Eat at restaurant', 'تناول الطعام داخل المطعم'],
    'delivery_address': ['Delivery Address', 'عنوان التوصيل'],
    'payment_method': ['Payment Method', 'طريقة الدفع'],
    'cash': ['Cash', 'نقدًا'],
    'online_payment': ['online payment', 'الدفع عبر البطاقة'],
    'online_payment_desc': [
      'Pay securely using your card',
      'ادفع بأمان باستخدام بطاقتك',
    ],
    'cash_desc': ['Pay on delivery', 'الدفع عند الاستلام'],
    'coupon': ['Coupon', 'كوبون'],
    'enter_coupon': ['Enter coupon code', 'أدخل رمز الكوبون'],
    'apply': ['Apply', 'تطبيق'],
    'coupon_applied': ['Coupon applied', 'تم تطبيق الكوبون'],
    'remove': ['Remove', 'إزالة'],
    'order_summary': ['Order Summary', 'ملخص الطلب'],
    'subtotal': ['Subtotal', 'المجموع الفرعي'],
    'delivery_fee': ['Delivery Fee', 'رسوم التوصيل'],
    'place_order': ['Place Order', 'تأكيد الطلب'],
    'placing_order': ['Placing order...', 'جاري تنفيذ الطلب...'],
    'err_login_again': ['Please login again.', 'يرجى تسجيل الدخول مرة أخرى'],
    'bldg': ['Bldg', 'بناء'],
    'floor': ['Floor', 'طابق'],
    'no_address': ['No address', 'لا يوجد عنوان'],
    'select_address': [
      'Please select delivery address',
      'يرجى اختيار عنوان التوصيل',
    ],

    'order': ['Order', 'الطلب'],
    'items': ['Items', 'الطلبات'],

    'close': ['Close', 'إغلاق'],

    //Edit_Profile
    'edit_profile': ['Edit Profile', 'تعديل الملف الشخصي'],
    'save_changes': ['Save Changes', 'حفظ التغييرات'],
    'err_load_profile': [
      'Failed to load profile data',
      'فشل تحميل بيانات الملف الشخصي',
    ],
    'err_save_profile': ['Failed to save changes', 'فشل حفظ التغييرات'],
    'required': ['Required', 'مطلوب'],

    'my_orders': ['My Orders', 'طلباتي'],
    'no_orders': ['No orders yet', 'لا توجد طلبات بعد'],

    //Profile
    'profile': ['Profile', 'الملف الشخصي'],
    'dark_mode': ['Dark Mode', 'الوضع الداكن'],
    'settings': ['Settings', ' الإعدادات'],
    'Res_settings': ['Settings', ' الإعدادات و اللغة'],
    'saved_addresses': ['Saved Addresses', 'العناوين المحفوظة'],
    'my_reviews': ['My Reviews', 'تقييماتي'],
    'terms_privacy': ['Terms & Privacy', 'الشروط والخصوصية'],
    'sign_out': ['Sign Out', 'تسجيل الخروج'],
    'confirm_logout': [
      'Are you sure you want to logout?',
      'هل أنت متأكد أنك تريد تسجيل الخروج؟',
    ],
    'guest': ['Guest', 'زائر'],
    'email_verification_sent': [
      'Verification email has been sent to your new email address',
      'تم إرسال رسالة تأكيد إلى بريدك الإلكتروني الجديد',
    ],
    'preferred_contact': ['Preferred Contact Method', 'طريقة التواصل المفضلة'],
    'phone_call': ['Phone Call', 'اتصال هاتفي'],

    'err_update_email': [
      'Error updating email',
      'حدث خطأ أثناء تحديث البريد الإلكتروني',
    ],
    'updated_successfully': ['Updated successfully', 'تم التعديل بنجاح'],
    "open_now": ["Open now", "مفتوح الآن"],
    "closed_now": ["Closed now", "مغلق الآن"],
    //rate_meals
    'rate_meals': ['Rate Your Meals', 'قيّم وجباتك'],
    'optional_comment': ['Optional comment', 'تعليق اختياري'],
    'submit': ['Submit', 'إرسال'],
    'thanks_feedback': ['Thanks for your feedback 🙌', 'شكرًا لملاحظاتك 🙌'],
    'no_meals_rate': ['No meals to rate yet', 'لا توجد وجبات للتقييم بعد'],
    'no_meals_desc': [
      'Once you place an order and it’s delivered, your meals will appear here for rating.',
      'بعد إتمام الطلب وتسليمه، ستظهر وجباتك هنا للتقييم.',
    ],

    //refund_policy
    'refund_policy': ['Refund & Exchange Policy', 'سياسة الاسترجاع والاستبدال'],
    'refund_policy_intro': [
      'Your satisfaction matters to us. Please review the policy below:',
      'نحرص دائمًا على رضاك، يرجى الاطلاع على السياسة التالية:',
    ],
    'refund_item_1': [
      'Orders cannot be returned or exchanged after delivery.',
      'لا يمكن إرجاع أو استبدال الطلبات بعد استلامها.',
    ],
    'refund_item_2': [
      'If an error occurs from the restaurant, the order will be replaced or fully refunded.',
      'في حال وجود خطأ من المطعم، سيتم الاستبدال أو استرجاع المبلغ كاملًا.',
    ],
    'refund_item_3': [
      'Refunds are not accepted due to change of mind or after the item is opened or partially consumed.',
      'لا يتم قبول الاسترجاع بسبب تغيير الرأي أو بعد فتح المنتج أو استهلاك جزء منه.',
    ],
    'refund_item_4': [
      'Online payments are refunded to the same payment method within 7–14 business days, depending on the bank.',
      'يتم رد المدفوعات الإلكترونية إلى نفس وسيلة الدفع خلال 7–14 يوم عمل حسب البنك.',
    ],
    'refund_item_5': [
      'Healthy meal plans and subscriptions are non-refundable after payment or heating.',
      'الوجبات الصحية والاشتراكات غير قابلة للاسترجاع بعد الدفع أو التسخين.',
    ],
    'refund_item_6': [
      'Loyalty and reward programs are subject to restaurant terms and may not apply to all items or branches.',
      'تخضع برامج الولاء والمكافآت لشروط المطعم وقد لا تشمل جميع الأصناف أو الفروع.',
    ],
    //rewards
    'rewards': ['Rewards', 'المكافآت'],
    'available_rewards': ['Available Rewards', 'المكافآت المتاحة'],
    'reward_redeemed': [
      'Reward redeemed successfully 🎉',
      'تم استبدال المكافأة بنجاح 🎉',
    ],

    //Address
    'address': ['Address', 'عنوان'],
    'add_new_address': ['Add new address', 'إضافة عنوان جديد'],
    'address_name': ['Address Name', 'اسم العنوان'],
    'eg_home': ['e.g. Home', 'مثال: المنزل'],
    'location': ['Location', 'الموقع'],
    'city': ['City', 'المدينة'],
    'area': ['Area', 'المنطقة'],
    'street_details': ['Street Details', 'تفاصيل الشارع'],
    'street': ['Street', 'الشارع'],
    'building': ['Building', 'البناء'],
    'notes': ['Notes', 'ملاحظات'],
    'extra_directions': ['Extra directions', 'إرشادات إضافية'],
    'set_default_address': ['Set as default address', 'تعيين كعنوان افتراضي'],
    'save_address': ['Save Address', 'حفظ العنوان'],
    'delete_address': ['Delete Address', 'حذف العنوان'],
    'confirm_delete_address': [
      'Are you sure you want to delete this address?',
      'هل أنت متأكد من حذف هذا العنوان؟',
    ],
    'cancel': ['Cancel', 'إلغاء'],
    'delete': ['Delete', 'حذف'],

    'menu': ['Menu', 'المنيو'],
    'all': ['All', 'الكل'],
    'no_items': ['No items', 'لا توجد عناصر'],

    //Home
    'recommended': ['Recommended for You', 'المقترح لك'],
    'popular': ['Popular Right Now', 'الأكثر طلباً'],

    //Meal Details
    'choose_size': ['Choose Size', 'اختر الحجم'],
    'included': ['Included', 'مشمول'],
    'extras': ['Extras', 'إضافات'],
    'add_to_cart': ['Add to Cart', 'أضف إلى السلة'],
    'added_to_cart': [
      'Added to cart ({count})',
      'تمت الإضافة إلى السلة ({count})',
    ],
    // Order Details
    'order_details': ['Order details', 'تفاصيل الطلب'],
    'order_number': ['Order #{id}', 'طلب رقم #{id}'],
    'order_status': ['Order status', 'حالة الطلب'],
    'track_order': ['Track Order', 'تتبع الطلب'],
    // Loyalty Sheet
    'loyalty_updated': ['🎉 Loyalty updated', '🎉 تم تحديث الولاء'],
    'you_are_now': ['You are now {tier}', 'أنت الآن {tier}'],
    'points_to_next': [
      '{points} / {next} points to {tier}',
      '{points} / {next} نقطة للوصول إلى {tier}',
    ],
    // OrderSuccessScreen
    'order_success_title': [
      'Order Placed Successfully!',
      'تم تنفيذ الطلب بنجاح!',
    ],
    'order_success_subtitle': ['Thank you for your order', 'شكراً لطلبك'],
    'order_success_track': ['Track Order', 'تتبع الطلب'],
    'order_success_back_home': ['Back to Home', 'العودة للرئيسية'],

    // AppHeader
    'app_header_brand': ['Century Fries', 'سنشري فرايز'],

    // CartItemCard
    'cart_item_card_currency': ['SAR', 'ريال'],

    // ===== LoyaltyCard =====
    'loyalty_status': ['Loyalty Status', 'حالة الولاء'],
    'member': ['Member', 'عضو'],
    'points': ['Points', 'النقاط'],
    'orders': ['Orders', 'الطلبات'],
    'progress_to': ['Progress to', 'التقدم نحو'],
    'loyalty_completed': ['Loyalty Level Completed', 'تم إكمال مستوى الولاء'],

    // ===== MealHorizontalList =====
    'wagyu_burger': ['Wagyu Burger', 'برغر واغيو'],
    'lava_cake': ['Lava Cake', 'لافا كيك'],
    'wagyu_price': ['85 SAR', '85 ريال'],
    'lava_price': ['38 SAR', '38 ريال'],

    // ===== MealHorizontalListFromData =====
    'meal_list_error': ['Something went wrong', 'حدث خطأ ما'],
    'meal_list_empty': ['No items', 'لا توجد عناصر'],

    // ===== MealsSection =====
    'meals_section_error': [
      'Something went wrong.\nPlease try again later.',
      'حدث خطأ ما.\nيرجى المحاولة لاحقاً.',
    ],
    'meals_section_empty': ['No items', 'لا توجد عناصر'],

    'customize': ['Remove from meal', 'إزالة من الوجبة'],
    'best_seller': ['Best Seller', 'الأكثر مبيعًا'],

    // ===== OrderCard =====
    'order_card_default_title': ['Your order', 'طلبك'],
    'order_card_more_items': ['more items', 'عناصر أخرى'],
    'order_card_points_earned': ['points earned', 'نقاط مكتسبة'],
    'order_card_points_pending': ['Points pending', 'النقاط قيد المعالجة'],

    // ===== OrderSummaryCard =====
    'order_summary_subtotal': ['Subtotal', 'المجموع الفرعي'],
    'order_summary_delivery': ['Delivery', 'التوصيل'],
    'order_summary_total': ['Total', 'الإجمالي'],

    // ===== OrderTypeSelector =====
    'order_type_delivery': ['Delivery', 'توصيل'],
    'order_type_pickup': ['Pickup', 'استلام'],
    'order_type_dine_in': ['Dine-in', 'داخل المطعم'],

    // ===== ProfileContactMenu =====
    'profile_contact_title': [
      'Contact & Social',
      'التواصل والشبكات الاجتماعية',
    ],
    'profile_contact_whatsapp': ['WhatsApp', 'واتساب'],
    'profile_contact_whatsapp_sub': ['Chat with us', 'تواصل معنا'],
    'profile_contact_instagram': ['Instagram', 'إنستغرام'],

    // ================= RewardCard =================
    'reward_redeem': ['Redeem', 'استبدال'],
    'reward_redeemed_status': ['Redeemed', 'تم الاستبدال'],
    'reward_locked': ['Locked', 'مقفل'],
    'reward_done': ['Done', 'تم'],
    'reward_ready': ['Ready', 'جاهز'],
    'reward_more_points': ['more points needed', 'نقطة إضافية مطلوبة'],
    'reward_pts': ['pts', 'نقطة'],

    // ================= RewardProgressCard =================
    'reward_tier': ['Tier', 'الفئة'],
    'reward_points_away': ['points away from', 'نقطة متبقية للوصول إلى'],
    'reward_reached': ['You reached', 'وصلت إلى'],

    // ================= CART & ORDER =================
    'please_wait_order_processing': [
      'Please wait, your order is being processed',
      'يرجى الانتظار، يتم معالجة الطلب',
    ],

    // ================= ADDRESS =================
    'select_delivery_address': [
      'Please select a delivery address',
      'يرجى اختيار عنوان التوصيل',
    ],

    // ================= MARKETING CENTER =================
    'marketing': ['Marketing', 'التسويق'],
    'promotions': ['Promotions', 'العروض'],
    'coupons': ['Coupons', 'الكوبونات'],

    'no_promotions': ['No promotions found', 'لا توجد عروض'],
    'no_coupons': ['No coupons found', 'لا توجد كوبونات'],

    // ================= ADMIN CREATE EXTRA =================
    'admin_promotion_type': ['Promotion Type', 'نوع العرض'],

    'admin_promotion_info': ['Promotion Info', 'معلومات العرض'],

    'admin_discount_settings': ['Discount Settings', 'إعدادات الخصم'],

    'admin_big_order_condition': ['Big Order Condition', 'شرط الطلب الكبير'],

    'admin_active_dates': ['Active Dates', 'تواريخ التفعيل'],

    'admin_start_date': ['Start Date', 'تاريخ البداية'],

    'admin_end_date': ['End Date', 'تاريخ النهاية'],

    'admin_select_date': ['Select date', 'اختر التاريخ'],

    'admin_select_dates_first': [
      'Please select start and end dates first',
      'يرجى اختيار تاريخ البداية والنهاية أولاً',
    ],

    'admin_select_image': ['Tap to select image', 'اضغط لاختيار صورة'],

    'admin_select_image_first': [
      'Please select image first',
      'يرجى اختيار صورة أولاً',
    ],

    //================ Admin Order ==========
    'customer': ['Customer', 'العميل'],
    'status': ['Status', 'الحالة'],
    'change_status': ['Change Status', 'تغيير الحالة'],

    // ================= PROMOTION TYPES =================
    'promo_type_banner': ['Banner', 'بنر'],
    'promo_type_discount': ['Discount', 'خصم'],
    'promo_type_big_order': ['Big Order', 'طلب كبير'],
    'promo_type_coupon': ['Coupon', 'كوبون'],

    // ================= ADMIN PROMOTIONS =================
    'admin_promotions': ['Promotions', 'العروض'],
    'admin_banners': ['Banners', 'البنرات'],
    'admin_discounts': ['Discounts', 'الخصومات'],
    'admin_big_orders': ['Big Orders', 'الطلبات الكبيرة'],
    'admin_coupons': ['Coupons', 'الكوبونات'],

    'admin_create_promotion': ['Create Promotion', 'إنشاء عرض'],
    'admin_edit_promotion': ['Edit Promotion', 'تعديل العرض'],

    'admin_title_en': ['Title (English)', 'العنوان (إنجليزي)'],
    'admin_title_ar': ['Title (Arabic)', 'العنوان (عربي)'],
    'admin_desc_en': ['Description (English)', 'الوصف (إنجليزي)'],
    'admin_desc_ar': ['Description (Arabic)', 'الوصف (عربي)'],

    'admin_discount_value': ['Discount Value', 'قيمة الخصم'],
    'admin_discount_type': ['Discount Type', 'نوع الخصم'],
    'admin_percentage': ['Percentage', 'نسبة مئوية'],
    'admin_fixed_amount': ['Fixed Amount', 'مبلغ ثابت'],

    'admin_min_order': ['Minimum Order Amount', 'الحد الأدنى للطلب'],

    'admin_auto_apply': ['Auto Apply', 'تطبيق تلقائي'],
    'admin_override_loyalty': ['Override Loyalty', 'يلغي خصم الولاء'],

    'admin_save_promotion': ['Save Promotion', 'حفظ العرض'],
    'admin_coupon_code_hint': ['Example: SAVE20', 'مثال: SAVE20'],

    'admin_max_discount_hint': [
      'Leave empty for unlimited',
      'اتركه فارغاً بدون حد أقصى',
    ],

    'admin_usage_limit_hint': [
      'Leave empty for unlimited uses',
      'اتركه فارغاً لاستخدام غير محدود',
    ],

    // ===== ADMIN EMPTY STATES =====
    'admin_no_promotions': ['No promotions found', 'لا توجد عروض'],

    'admin_no_banners': ['No banners found', 'لا توجد بنرات'],
    'admin_no_discounts': ['No discounts found', 'لا توجد خصومات'],
    'admin_no_big_orders': ['No big order offers', 'لا توجد عروض طلبات كبيرة'],
    'admin_no_coupons': ['No coupons found', 'لا توجد كوبونات'],
    // ================= DELETE CONFIRM =================
    'delete_promo_title': ['Delete promotion?', 'حذف العرض؟'],
    'delete_promo_confirm': [
      'Are you sure you want to delete "{title}"? This cannot be undone.',
      'هل أنت متأكد أنك تريد حذف "{title}"؟ لا يمكن التراجع.',
    ],

    //===========Admin Customer=============
    'customers': ['Customers', 'العملاء'],
    'registered_customers': ['registered customers', 'عملاء مسجلين'],
    'search_customers': ['Search customers...', 'ابحث عن عميل...'],
    'bronze': ['Bronze', 'برونزي'],
    'silver': ['Silver', 'فضي'],
    'gold': ['Gold', 'ذهبي'],
    'diamond': ['Diamond', 'ماسي'],
    //===========
    'invalid_coupon': ['Invalid coupon code', 'كود الخصم غير صحيح'],

    'coupon_not_started': ['Coupon not started', 'لم يبدأ الكوبون بعد'],

    'coupon_expired': ['Coupon expired', 'انتهت صلاحية الكوبون'],

    'coupon_limit_reached': [
      'Coupon usage limit reached',
      'تم استهلاك الكوبون بالكامل',
    ],
    'loading': ['Loading...', 'جاري التحميل...'],

    //============= Admin rating===========
    'ratings_feedback': ['Ratings & Feedback', 'التقييمات والملاحظات'],
    'food_ratings': ['Food Ratings', 'تقييمات الطعام'],
    'driver_ratings': ['Driver Ratings', 'تقييمات السائقين'],
    'no_driver_reviews': ['No driver reviews yet', 'لا توجد تقييمات للسائقين'],
    'avg_food_rating': ['Avg Food Rating', 'متوسط تقييم الطعام'],
    'avg_driver_rating': ['Avg Driver Rating', 'متوسط تقييم السائق'],
    'positive_reviews': ['Positive Reviews', 'التقييمات الإيجابية'],
    'needs_attention': ['Needs Attention', 'بحاجة لمراجعة'],
    'write_reply': ['Write Reply', 'اكتب رد'],
    'enter_reply': ['Enter reply...', 'أدخل الرد...'],

    //=========== Admin Loyalty ============
    'points_settings': ['Points Settings', 'إعدادات النقاط'],
    'currency_step': ['Currency Step', 'قيمة الخطوة'],
    'base_points': ['Base Points', 'النقاط الأساسية'],
    'birthday_bonus_enabled': [
      'Birthday Bonus Enabled',
      'تفعيل نقاط عيد الميلاد',
    ],
    'save': ['Save', 'حفظ'],
    'loyalty': ['Loyalty', 'الولاء'],
    'total_members': ['Total Members', 'إجمالي الأعضاء'],
    'diamond_members': ['Diamond Members', 'أعضاء الماس'],
    'points_issued': ['Points Issued', 'النقاط الممنوحة'],
    'points_redeemed': ['Points Redeemed', 'النقاط المصروفة'],
    'membership_tiers': ['Membership Tiers', 'مستويات العضوية'],
    'error_loading_data': [
      'Error loading data',
      'حدث خطأ أثناء تحميل البيانات',
    ],

    'min_points': ['Min Points', 'الحد الأدنى للنقاط'],
    'free_delivery': ['Free Delivery', 'توصيل مجاني'],
    'priority_support': ['Priority Support', 'أولوية دعم'],

    //============ Admin Analytics =================
    'analytics': ['Analytics', 'التحليلات'],
    'today': ['Today', 'اليوم'],
    'week': ['This Week', 'هذا الأسبوع'],
    'month': ['This Month', 'هذا الشهر'],
    'total_revenue': ['Total Revenue', 'إجمالي الإيرادات'],
    'avg_order_value': ['Avg Order Value', 'متوسط قيمة الطلب'],
    'repeat_customers': ['Repeat Customers', 'العملاء المتكررون'],
    'revenue_overview': ['Revenue Overview', 'نظرة عامة على الإيرادات'],
    'top_meals': ['Top Meals', 'أكثر الوجبات مبيعاً'],
    'no_sales_data': [
      'No sales data for this period',
      'لا توجد بيانات مبيعات للفترة المحددة',
    ],

    //========= Admin Setting ===================
    'saved_successfully': ['Saved successfully', 'تم الحفظ بنجاح'],

    // ================= Restaurant Info =================
    'restaurant_information': ['Restaurant Information', 'معلومات المطعم'],
    'configure_restaurant_preferences': [
      'Configure restaurant preferences',
      'تخصيص إعدادات المطعم',
    ],
    'restaurant_name_en': ['Restaurant Name (English)', 'اسم المطعم (إنجليزي)'],
    'restaurant_name_ar': ['Restaurant Name (Arabic)', 'اسم المطعم (عربي)'],

    // ================= Working Hours =================
    'working_hours': ['Working Hours', 'ساعات العمل'],
    'set_operating_hours': ['Set operating hours', 'تحديد ساعات العمل'],
    'opening_time': ['Opening Time', 'وقت الافتتاح'],
    'closing_time': ['Closing Time', 'وقت الإغلاق'],
    'working_days': ['Working Days', 'أيام العمل'],
    'mon': ['Mon', 'الاثنين'],
    'tue': ['Tue', 'الثلاثاء'],
    'wed': ['Wed', 'الأربعاء'],
    'thu': ['Thu', 'الخميس'],
    'fri': ['Fri', 'الجمعة'],
    'sat': ['Sat', 'السبت'],
    'sun': ['Sun', 'الأحد'],

    // ================= Delivery =================
    'delivery_settings': ['Delivery Settings', 'إعدادات التوصيل'],
    'configure_delivery_areas': [
      'Configure delivery areas',
      'تحديد مناطق التوصيل',
    ],
    'delivery_radius_km': ['Delivery Radius (km)', 'نطاق التوصيل (كم)'],

    'min_order_amount': ['Minimum Order Amount', 'الحد الأدنى للطلب'],
    'free_delivery_minimum': [
      'Free Delivery Minimum',
      'الحد الأدنى للتوصيل المجاني',
    ],
    'delivery_fee_desc': [
      'This fee will be added to every delivery order',
      'سيتم إضافة هذه الرسوم على كل طلب توصيل',
    ],

    'delivery_rules_explained': [
      'Minimum order required for delivery and amount for free delivery',
      'الحد الأدنى للطلب للتوصيل والمبلغ الذي يصبح بعده التوصيل مجاني',
    ],
    'delivery_radius_title': ['Delivery Radius', 'نطاق التوصيل'],
    'delivery_radius_desc': [
      'Maximum distance (in KM) that orders can be delivered to.',
      'أقصى مسافة (بالكيلومتر) يمكن التوصيل إليها.',
    ],

    'delivery_fee_title': ['Delivery Fee', 'رسوم التوصيل'],

    'min_order_delivery_title': [
      'Minimum Order for Delivery',
      'الحد الأدنى لطلب التوصيل',
    ],
    'min_order_delivery_desc': [
      'Customer must order at least this amount to enable delivery.',
      'يجب أن يطلب العميل بهذا المبلغ كحد أدنى لتفعيل التوصيل.',
    ],

    'free_delivery_above_title': [
      'Free Delivery Above',
      'توصيل مجاني عند تجاوز',
    ],
    'free_delivery_above_desc': [
      'Delivery becomes free when order amount reaches this value.',
      'يصبح التوصيل مجانيًا عند وصول قيمة الطلب لهذا المبلغ.',
    ],

    'km': ['KM', 'كم'],
    'default_prep_time_title': [
      'Default Preparation Time',
      'مدة التحضير الافتراضية',
    ],
    'default_prep_time_desc': [
      'Estimated time (in minutes) required to prepare an order.',
      'الوقت المتوقع (بالدقائق) اللازم لتحضير الطلب.',
    ],
    'minutes': ['Minutes', 'دقيقة'],
    'min_order_not_met': [
      'Minimum order amount not reached',
      'لم يتم الوصول إلى الحد الأدنى للطلب',
    ],

    // ================= Orders =================
    'order_settings': ['Order Settings', 'إعدادات الطلبات'],
    'configure_order_handling': [
      'Configure order handling',
      'تخصيص معالجة الطلبات',
    ],
    'default_prep_time_min': [
      'Default Preparation Time (min)',
      'وقت التحضير الافتراضي (دقيقة)',
    ],
    'auto_accept_orders': ['Auto Accept Orders', 'قبول الطلبات تلقائيًا'],
    'auto_accept_orders_desc': [
      'Automatically accept incoming orders',
      'قبول الطلبات الجديدة تلقائيًا',
    ],

    'new': ['New', 'جديد'],
    'completed': ['Completed', 'مكتمل'],
    'view_order': ['View Order', 'عرض الطلب'],
    'no_orders_found': ['No orders found', 'لا توجد طلبات'],
    'currency_aed': ['AED', 'درهم'],
    //=========== Admin menu ============
    'add_new_addon': ['Add New Add-on', 'إضافة إضافة جديدة'],
    'edit_addon': ['Edit Add-on', 'تعديل الإضافة'],
    'name_english': ['Name (English)', 'الاسم (إنجليزي)'],
    'name_arabic': ['Name (Arabic)', 'الاسم (عربي)'],
    'price': ['Price', 'السعر'],
    'meal_name_en': ['Name (EN)', 'الاسم (إنجليزي)'],
    'meal_name_ar': ['Name (AR)', 'اسم الوجبة'],
    'meal_description_en': ['Description (EN)', 'الوصف (إنجليزي)'],
    'meal_description_ar': ['Description (AR)', 'الوصف'],
    'meal_base_price': ['Base price (SAR)', 'السعر الأساسي (ريال)'],
    'saving': ['Saving...', 'جاري الحفظ...'],
    'no_sizes_found': ['No sizes found', 'لا يوجد أحجام'],
    'price_label': ['Price', 'السعر'],
    'add_size': ['Add Size', 'إضافة حجم'],
    'meal_settings': ['Meal Settings', 'إعدادات الوجبة'],
    'delete_meal': ['Delete Meal', 'حذف الوجبة'],
    'delete_meal_confirm': [
      'Are you sure you want to delete this meal?\nThis action cannot be undone.',
      'هل أنت متأكد أنك تريد حذف هذه الوجبة؟\nلا يمكن التراجع عن هذا الإجراء.',
    ],
    'name_en': ['Name (EN)', 'الاسم (إنجليزي)'],
    'name_ar': ['Name (AR)', 'الاسم (عربي)'],
    'description_en': ['Description (EN)', 'الوصف (إنجليزي)'],
    'description_ar': ['Description (AR)', 'الوصف (عربي)'],
    'base_price': ['Base Price', 'السعر الأساسي'],
    'sizes': ['Sizes', 'الأحجام'],
    'add_ons': ['Add-ons', 'الإضافات'],
    'removal': ['Removal', 'إزالة'],
    'confirm': ['Confirm', 'تأكيد'],
    'confirm_disable_addon': [
      'Are you sure you want to disable this addon?',
      'هل أنت متأكد من تعطيل هذه الإضافة؟',
    ],

    'disable': ['Disable', 'تعطيل'],
    // ================= Payments =================
    'payment_methods': ['Payment Methods', 'طرق الدفع'],
    'enable_or_disable_payments': [
      'Enable or disable payment options',
      'تفعيل أو تعطيل وسائل الدفع',
    ],
    'visa_master': ['Visa / MasterCard', 'فيزا / ماستركارد'],
    'visa_master_desc': ['Enable card payments', 'تفعيل الدفع عبر البطاقات'],
    'apple_pay': ['Apple Pay', 'آبل باي'],
    'apple_pay_desc': ['Enable Apple Pay', 'تفعيل آبل باي'],
    'google_pay': ['Google Pay', 'جوجل باي'],
    'google_pay_desc': ['Enable Google Pay', 'تفعيل جوجل باي'],
    'cash_on_delivery': ['Cash on Delivery', 'الدفع عند الاستلام'],
    'cash_on_delivery_desc': [
      'Allow cash payment upon delivery',
      'السماح بالدفع نقدًا عند الاستلام',
    ],
    'big_order_discount': ['Big Order Discount', 'خصم الطلب الكبير'],

    //============= Admin Profile===========
    'administrator': ['Administrator', 'المسؤول'],
    'manage_account_settings': [
      'Manage your account settings',
      'إدارة إعدادات الحساب',
    ],
    'account_information': ['Account Information', 'معلومات الحساب'],

    'change_password': ['Change Password', 'تغيير كلمة المرور'],
    'preferences': ['Preferences', 'التفضيلات'],
    'language': ['Language', 'اللغة'],
    'theme': ['Theme', 'المظهر'],
    'password_reset_sent': [
      'Password reset link has been sent to your email',
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
    ],
    'dark': ['Dark', 'داكن'],
    'light': ['Light', 'فاتح'],
    'arabic': ['Arabic', 'العربية'],
    'english': ['English', 'الإنجليزية'],
    //========= Slidbar===============
    'dashboard': ['Dashboard', 'لوحة التحكم'],
    'admin_profile': ['Admin Profile', 'الملف الشخصي'],
    'drivers': ['Drivers', 'السائقين'],
    'ratings': ['Ratings', 'التقييمات'],

    //=============== Drivers =============
    'add_driver': ['Add Driver', 'إضافة سائق'],
    'search_driver': ['Search driver...', 'بحث عن سائق...'],
    'name': ['Name', 'الاسم'],
    'vehicle_type': ['Vehicle Type', 'نوع المركبة'],
    'plate_number': ['Plate Number', 'رقم اللوحة'],
    'online': ['Online', 'متصل'],
    'busy': ['Busy', 'مشغول'],
    'offline': ['Offline', 'غير متصل'],
    'rating': ['Rating', 'التقييم'],
    'active': ['Active', 'نشط'],
    'inactive': ['Inactive', 'غير نشط'],
    'no_drivers': ['No drivers found', 'لا يوجد سائقين'],
    'driver_added': ['Driver added successfully', 'تمت إضافة السائق بنجاح'],
    'edit_driver': ['Edit Driver', 'تعديل السائق'],
    'delete_driver': ['Delete Driver', 'حذف السائق'],
    'confirm_delete': [
      'Are you sure you want to delete this driver?',
      'هل أنت متأكد من حذف هذا السائق؟',
    ],
    'driver_updated': ['Driver updated successfully', 'تم تعديل السائق بنجاح'],
    'driver_deleted': ['Driver deleted successfully', 'تم حذف السائق بنجاح'],
    'assign_order': ['Assign Order', 'تعيين طلب'],
    'track_driver': ['Track Driver', 'تتبع السائق'],
    'driver_details': ['Driver Details', 'تفاصيل السائق'],
    'vehicle_details': ['Vehicle Details', 'تفاصيل المركبة'],
    'update_status': ['Update Status', 'تحديث الحالة'],
    'driver_not_found': ['Driver not found', 'السائق غير موجود'],
    'driver_profile': ['Driver Profile', 'ملف السائق'],
    'driver_location': ['Driver Location', 'موقع السائق'],
    'last_update': ['Last Update', 'آخر تحديث'],
    'orders_today': ['Orders Today', 'طلبات اليوم'],
    'total_orders': ['Total Orders', 'إجمالي الطلبات'],
    'average_rating': ['Average Rating', 'متوسط التقييم'],
    'deactivate_driver': ['Deactivate Driver', 'إيقاف السائق'],
    'activate_driver': ['Activate Driver', 'تفعيل السائق'],
    'driver_status_updated': ['Driver status updated', 'تم تحديث حالة السائق'],
    'no_orders_assigned': ['No orders assigned', 'لا يوجد طلبات معينة'],
    'select_status': ['Select Status', 'اختر الحالة'],
    'select_driver': ['Select Driver', 'اختر سائق'],
    'driver_information': ['Driver Information', 'معلومات السائق'],
    'driver_management': ['Driver Management', 'إدارة السائقين'],

    //================= Dashbaord =================
    'todays_orders': ['Today\'s Orders', 'طلبات اليوم'],
    'active_orders': ['Active Orders', 'الطلبات النشطة'],
    'completed_orders': ['Completed', 'المكتملة'],
    'cancelled_orders': ['Cancelled', 'الملغاة'],
    'revenue_this_month': ['Revenue (This Month)', 'الإيرادات (هذا الشهر)'],
    'drivers_online': ['Drivers Online', 'السائقون المتصلون'],
    'recent_orders': ['Recent Orders', 'الطلبات الأخيرة'],
    'no_recent_orders': ['No recent orders', 'لا توجد طلبات حديثة'],
    'pending': ['Pending', 'قيد الانتظار'],
    'confirmed': ['Confirmed', 'تم التأكيد'],
    'preparing': ['Preparing', 'قيد التحضير'],
    'out_for_delivery': ['Out for delivery', 'خرج للتوصيل'],
    'delivered': ['Delivered', 'تم التوصيل'],
    'cancelled': ['Cancelled', 'ملغي'],
    'just_now': ['Just now', 'الآن'],
    'min_ago': ['min ago', 'د قبل'],
    'h_ago': ['h ago', 'س قبل'],
    'd_ago': ['d ago', 'ي قبل'],
    //============= Driver ====================
    'hello': ['Hello', 'مرحباً'],
    'vehicle_motorcycle': ['Motorcycle', 'دراجة نارية'],
    'vehicle_car': ['Car', 'سيارة'],
    'vehicle_bicycle': ['Bicycle', 'دراجة هوائية'],

    'ready_for_orders': ['Ready for orders', 'جاهز لاستلام الطلبات'],
    'not_ready': ['Not ready', 'غير جاهز'],

    'new_orders': ['New Orders', 'طلبات جديدة'],

    'accept': ['Accept', 'قبول'],
    'decline': ['Decline', 'رفض'],

    'edit_name': ['Edit Name', 'تعديل الاسم'],
    'edit_email': ['Edit Email', 'تعديل البريد الإلكتروني'],
    'edit_phone': ['Edit Phone', 'تعديل رقم الهاتف'],

    'edit_vehicle': ['Edit Vehicle Type', 'تعديل نوع المركبة'],
    'edit_plate': ['Edit Plate Number', 'تعديل رقم اللوحة'],

    'logout': ['Logout', 'تسجيل الخروج'],

    'address_not_available': ['Address not available', 'العنوان غير متوفر'],

    'accepted': ['Accepted', 'تم القبول'],
    'picked_up': ['Picked Up', 'تم الاستلام'],
    'on_the_way': ['On the Way', 'في الطريق'],

    'pickup_from': ['Pickup From', 'الاستلام من'],
    'deliver_to': ['Deliver To', 'التوصيل إلى'],

    'call': ['Call', 'اتصال'],
    'navigate': ['Navigate', 'الانتقال'],
    'confirm_pickup': ['Confirm Pickup', 'تأكيد الاستلام'],
    'start_delivery': ['Start Delivery', 'بدء التوصيل'],
    'mark_delivered': ['Mark as Delivered', 'تم التوصيل'],
    'earnings': ['Earnings', 'الأرباح'],
    'whatsapp': ['WhatsApp', 'واتساب'],
    'visa_mastercard': ['Visa / MasterCard', 'فيزا / ماستركارد'],
  };

  /// ================= TRANSLATE =================
  static String t(String key, [Map<String, String>? vars]) {
    final value = _t[key];
    if (value == null) return key;

    String text = LanguageController.isArabic.value ? value[1] : value[0];

    if (vars != null) {
      vars.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }

    return text;
  }
}
