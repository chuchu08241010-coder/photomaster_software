import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../profile/data/profile.dart';

/// 通过公开接口获取当前网络的「IP 属地」（省级），每天最多更新一次写入个人资料。
/// 需要联网；失败时静默返回，不影响主流程。
class IpLocationService {
  static const _dateKey = 'ip_loc_date';

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// 每天首次启动时更新一次自己的 IP 属地。
  static Future<void> refreshDaily() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_dateKey) == _today()) return;
      final province = await _lookupProvince();
      if (province == null || province.isEmpty) return;
      await ProfileRepository().upsert(ipLocation: province);
      await prefs.setString(_dateKey, _today());
    } catch (_) {
      // 忽略
    }
  }

  /// 查询省级属地。CSDN 公开接口返回 UTF-8 中文，形如「广东省 深圳市 电信」。
  static Future<String?> _lookupProvince() async {
    try {
      final resp = await http
          .get(Uri.parse('https://searchplugin.csdn.net/api/v1/ip/get?ip='))
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      final address = (json['data']?['address'] as String?)?.trim();
      if (address == null || address.isEmpty) return null;
      // 取第一段作为省/直辖市，去掉「省」后缀更简洁。
      var province = address.split(RegExp(r'\s+')).first;
      province = province.replaceAll(RegExp(r'(省|市|自治区)$'), '');
      return province.isEmpty ? null : province;
    } catch (_) {
      return null;
    }
  }
}
