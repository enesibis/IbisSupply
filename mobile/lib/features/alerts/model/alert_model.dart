class AlertModel {
  final String id;
  final String type;
  final String severity;
  final String message;
  final bool resolved;
  final String? batchCode;
  final String? shipmentCode;
  final String createdAt;

  AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.resolved,
    this.batchCode,
    this.shipmentCode,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
        id: json['id'] ?? '',
        type: json['type'] ?? '',
        severity: json['severity'] ?? 'LOW',
        message: json['message'] ?? '',
        resolved: json['resolved'] ?? false,
        batchCode: json['batchCode'],
        shipmentCode: json['shipmentCode'],
        createdAt: json['createdAt'] ?? '',
      );
}
