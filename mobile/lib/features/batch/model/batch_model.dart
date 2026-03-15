class BatchResponse {
  final String id;
  final String batchCode;
  final String qrCode;
  final String productId;
  final String productName;
  final String productCategory;
  final String producerName;
  final String organizationName;
  final double quantity;
  final String unit;
  final String productionDate;
  final String expiryDate;
  final String? originLocation;
  final String status;
  final String? blockchainTxHash;
  final String createdAt;

  BatchResponse({
    required this.id,
    required this.batchCode,
    required this.qrCode,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.producerName,
    required this.organizationName,
    required this.quantity,
    required this.unit,
    required this.productionDate,
    required this.expiryDate,
    this.originLocation,
    required this.status,
    this.blockchainTxHash,
    required this.createdAt,
  });

  factory BatchResponse.fromJson(Map<String, dynamic> j) => BatchResponse(
        id: j['id'],
        batchCode: j['batchCode'],
        qrCode: j['qrCode'],
        productId: j['productId'],
        productName: j['productName'],
        productCategory: j['productCategory'] ?? '',
        producerName: j['producerName'] ?? '',
        organizationName: j['organizationName'] ?? '',
        quantity: (j['quantity'] as num).toDouble(),
        unit: j['unit'],
        productionDate: j['productionDate'],
        expiryDate: j['expiryDate'],
        originLocation: j['originLocation'],
        status: j['status'],
        blockchainTxHash: j['blockchainTxHash'],
        createdAt: j['createdAt'],
      );
}

class ProductItem {
  final String id;
  final String name;
  final String category;
  final String sku;
  final String unit;

  ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.unit,
  });

  factory ProductItem.fromJson(Map<String, dynamic> j) => ProductItem(
        id: j['id'],
        name: j['name'],
        category: j['category'] ?? '',
        sku: j['sku'] ?? '',
        unit: j['unit'] ?? 'KG',
      );
}
