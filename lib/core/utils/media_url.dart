import 'package:supabase_flutter/supabase_flutter.dart';

String? buildMediaPublicUrl(String? storagePath) {
  if (storagePath == null || storagePath.isEmpty) return null;
  if (storagePath.startsWith('http://') || storagePath.startsWith('https://')) {
    return storagePath;
  }
  final normalized = storagePath.startsWith('/')
      ? storagePath.substring(1)
      : storagePath;
  return Supabase.instance.client.storage
      .from('media')
      .getPublicUrl(normalized);
}
