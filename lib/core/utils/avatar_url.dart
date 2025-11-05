const String _supabaseMediaBaseUrl =
    'https://oomglkpxogeiwrrfphon.supabase.co/storage/v1/object/public/media/';

String buildMediaUrl(String relativePath) {
  return '$_supabaseMediaBaseUrl$relativePath';
}

String? buildAvatarUrl(String? rawProfileUrl) {
  if (rawProfileUrl == null || rawProfileUrl.isEmpty) {
    return null;
  }
  if (rawProfileUrl.startsWith('http')) {
    return rawProfileUrl;
  }

  final normalizedPath = rawProfileUrl.contains('/')
      ? rawProfileUrl
      : 'avatars/$rawProfileUrl';

  return buildMediaUrl(normalizedPath);
}
