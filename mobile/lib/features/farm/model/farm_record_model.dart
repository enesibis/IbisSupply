class FarmRecordResponse {
  final String id;
  final String batchId;
  final String batchCode;
  final String productName;
  final String producerName;
  final String? fieldLocation;
  final String? plantingDate;
  final String? harvestDate;
  final String? irrigationType;
  final double? totalIrrigationHours;
  final String? pesticides;
  final String? fertilizers;
  final String? notes;
  final String? blockchainTxHash;
  final String createdAt;

  FarmRecordResponse({
    required this.id,
    required this.batchId,
    required this.batchCode,
    required this.productName,
    required this.producerName,
    this.fieldLocation,
    this.plantingDate,
    this.harvestDate,
    this.irrigationType,
    this.totalIrrigationHours,
    this.pesticides,
    this.fertilizers,
    this.notes,
    this.blockchainTxHash,
    required this.createdAt,
  });

  factory FarmRecordResponse.fromJson(Map<String, dynamic> json) =>
      FarmRecordResponse(
        id: json['id'] ?? '',
        batchId: json['batchId'] ?? '',
        batchCode: json['batchCode'] ?? '',
        productName: json['productName'] ?? '',
        producerName: json['producerName'] ?? '',
        fieldLocation: json['fieldLocation'],
        plantingDate: json['plantingDate'],
        harvestDate: json['harvestDate'],
        irrigationType: json['irrigationType'],
        totalIrrigationHours: json['totalIrrigationHours']?.toDouble(),
        pesticides: json['pesticides'],
        fertilizers: json['fertilizers'],
        notes: json['notes'],
        blockchainTxHash: json['blockchainTxHash'],
        createdAt: json['createdAt'] ?? '',
      );
}
