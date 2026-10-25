class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  final bool hasNextPage;

  PaginatedResponse({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonItem,
  ) {
    final list = (json['data'] as List)
        .map((e) => fromJsonItem(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] ?? {};
    return PaginatedResponse(
      items: list,
      page: meta['page'] ?? 1,
      totalPages: meta['totalPages'] ?? 1,
      hasNextPage: meta['hasNextPage'] ?? false,
    );
  }
}
