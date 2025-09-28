import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class OtpGenerator {
  /// توليد رمز تأكيد من 6 أرقام بناءً على السيكريت كي والوقت الحالي
  /// 
  /// [secretKey] السيكريت كي بصيغة hex (مثل: "fd2e196070df55eddf5ef42ee39efd05")
  /// 
  /// Returns رمز التأكيد المكون من 6 أرقام
  static String generateVerificationCode(String secretKey) {
    // تحويل السيكريت كي من hex إلى bytes
    List<int> key = _hexToBytes(secretKey);
    
    // الحصول على الوقت الحالي بالثواني ثم تقسيمه على 60 للحصول على فترة الدقيقة  
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int timeCounter = currentTime ~/ 60; // كل دقيقة = فترة واحدة
    
    // تحويل time_counter إلى 8 bytes (big-endian)
    Uint8List timeBytes = Uint8List(8);
    ByteData.view(timeBytes.buffer).setUint64(0, timeCounter, Endian.big);
    
    // إنشاء HMAC-SHA1
    var hmacSha1 = Hmac(sha1, key);
    List<int> hmacHash = hmacSha1.convert(timeBytes).bytes;
    
    // Dynamic truncation
    int offset = hmacHash[hmacHash.length - 1] & 0xF;
    int binaryCode = ((hmacHash[offset] & 0x7F) << 24) |
                     ((hmacHash[offset + 1] & 0xFF) << 16) |
                     ((hmacHash[offset + 2] & 0xFF) << 8) |
                     (hmacHash[offset + 3] & 0xFF);
    
    // الحصول على 6 أرقام
    int otp = binaryCode % 1000000;
    
    // التأكد من أن الرقم مكون من 6 خانات (إضافة أصفار في البداية إذا لزم الأمر)
    return otp.toString().padLeft(6, '0');
  }

  /// تحويل النص hex إلى قائمة من الـ bytes
  static List<int> _hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      String hexByte = hex.substring(i, i + 2);
      int byte = int.parse(hexByte, radix: 16);
      bytes.add(byte);
    }
    return bytes;
  }

  /// السيكريت كي الافتراضي للتطبيق
  static const String defaultSecretKey = "fd2e196070df55eddf5ef42ee39efd05";

  /// إنشاء رمز التحقق باستخدام السيكريت كي الافتراضي
  static String generateCurrentCode() {
    return generateVerificationCode(defaultSecretKey);
  }

  /// التحقق من أن الرمز المُدخل صحيح
  static bool verifyCode(String inputCode) {
    String currentCode = generateCurrentCode();
    return inputCode == currentCode;
  }

  /// الحصول على الوقت المتبقي حتى تغيير الرمز (بالثواني)
  static int getSecondsUntilNextCode() {
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int secondsInCurrentMinute = currentTime % 60;
    return 60 - secondsInCurrentMinute;
  }
}