class QualityCheckResponse {
  final String id;
  final String batchId;
  final String batchCode;
  final String productName;
  final String inspectorName;
  final String result;
  final double? temperature;
  final double? humidity;
  final bool? contaminationDetected;
  final String? notes;
  final String checkedAt;

  QualityCheckResponse({
    required this.id,
    required this.batchId,
    required this.batchCode,
    required this.productName,
    required this.inspectorName,
    required this.result,
    this.temperature,
    this.humidity,
    this.contaminationDetected,
    this.notes,
    required this.checkedAt,
  });

  factory QualityCheckResponse.fromJson(Map<String, dynamic> json) =>
      QualityCheckResponse(
        id: json['id'] ?? '',
        batchId: json['batchId'] ?? '',
        batchCode: json['batchCode'] ?? '',
        productName: json['productName'] ?? '',
        inspectorName: json['inspectorName'] ?? '',
        result: json['result'] ?? '',
        temperature: json['temperature']?.toDouble(),
        humidity: json['humidity']?.toDouble(),
        contaminationDetected: json['contaminationDetected'],
        notes: json['notes'],
        checkedAt: json['checkedAt'] ?? '',
      );
}
