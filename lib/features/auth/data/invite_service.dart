import '../../../core/supabase/supabase_client.dart';

/// 邀请码兑换（调用后端 security definer 函数，保证一码一用、防并发）。
class InviteService {
  Future<bool> redeem(String code) async {
    final res = await supabase.rpc(
      'redeem_invite',
      params: {'p_code': code.trim()},
    );
    return res == true;
  }
}
