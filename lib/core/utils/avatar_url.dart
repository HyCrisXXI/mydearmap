const String _supabaseMediaBaseUrl =
    'https://oomglkpxogeiwrrfphon.supabase.co/storage/v1/object/public/media/';

String buildMediaUrl(String relativePath) {
  return '$_supabaseMediaBaseUrl$relativePath';
}

String? buildAvatarUrl(String? rawProfileUrl) {
  if (rawProfileUrl == null || rawProfileUrl.isEmpty) {
    return null;
  }
  // Aqui antes había comprobacion de si empezaba con http, para aceptar enlaces directos
  // ahora no, ya que la app no lo hace ni lo hará en un futuro cercano

  final trimmed = rawProfileUrl.trim();
  return buildMediaUrl('avatars/$trimmed');
}

String? buildGroupPhotoUrl(String? rawFileName) {
  if (rawFileName == null || rawFileName.isEmpty) {
    return null;
  }
  final trimmed = rawFileName.trim();
  return buildMediaUrl('groups/$trimmed');
}
