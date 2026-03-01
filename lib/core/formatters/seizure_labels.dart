String seizureTypeLabel(String code) {
  switch (code.trim().toUpperCase()) {
    case 'TONIC_CLONIC':
      return 'Tónico-clónica';
    case 'FOCAL':
      return 'Focal';
    case 'ABSENCE':
      return 'Ausencia';
    case 'MYOCLONIC':
      return 'Mioclónica';
    default:
      if (code.trim().isEmpty) {
        return 'Sin tipo';
      }
      return code;
  }
}
