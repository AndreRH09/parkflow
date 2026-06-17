class SearchFilter {
  final double? lat;
  final double? lng;
  final int radiusM;
  final String? query;

  const SearchFilter({
    this.lat,
    this.lng,
    this.radiusM = 800,
    this.query,
  });

  SearchFilter copyWith({
    double? lat,
    double? lng,
    int? radiusM,
    String? query,
  }) {
    return SearchFilter(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusM: radiusM ?? this.radiusM,
      query: query ?? this.query,
    );
  }
}
