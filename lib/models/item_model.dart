class ItemModel {
  final String id;
  final String name;
  final int stock;
  final String category;

  ItemModel({required this.id, required this.name, required this.stock, required this.category});

  factory ItemModel.fromMap(Map<String, dynamic> data, String id) {
    return ItemModel(
      id: id,
      name: data['name'] ?? '',
      stock: data['stock'] ?? 0,
      category: data['category'] ?? '',
    );
  }
}