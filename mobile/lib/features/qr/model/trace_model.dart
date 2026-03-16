class TraceResponse {
  final BatchInfo batch;
  final List<ShipmentInfo> shipments;

  TraceResponse({required this.batch, required this.shipments});

  factory TraceResponse.fromJson(Map<String, dynamic> json) => TraceResponse(
        batch: BatchInfo.fromJson(json['batch']),
        shipments: (json['shipments'] as List? ?? [])
            .map((s) => ShipmentInfo.fromJson(s))
            .toList(),
      );
}

class BatchInfo {
  final String batchCode;
  final String? qrCode;
  final String productName;
  final String productCategory;
  final String productSku;
  final String producerName;
  final String organizationName;
  final double quantity;
  final String unit;
  final String productionDate;
  final String expiryDate;
  final String? originLocation;
  final String status;
  final String createdAt;

  BatchInfo({
    required this.batchCode,
    this.qrCode,
    required this.productName,
    required this.productCategory,
    required this.productSku,
    required this.producerName,
    required this.organizationName,
    required this.quantity,
    required this.unit,
    required this.productionDate,
    required this.expiryDate,
    this.originLocation,
    required this.status,
    required this.createdAt,
  });

  factory BatchInfo.fromJson(Map<String, dynamic> json) => BatchInfo(
        batchCode: json['batchCode'] ?? '',
        qrCode: json['qrCode'],
        productName: json['productName'] ?? '',
        productCategory: json['productCategory'] ?? '',
        productSku: json['productSku'] ?? '',
        producerName: json['producerName'] ?? '',
        organizationName: json['organizationName'] ?? '',
        quantity: (json['quantity'] ?? 0).toDouble(),
        unit: json['unit'] ?? '',
        productionDate: json['productionDate'] ?? '',
        expiryDate: json['expiryDate'] ?? '',
        originLocation: json['originLocation'],
        status: json['status'] ?? '',
        createdAt: json['createdAt'] ?? '',
      );
}

class ShipmentInfo {
  final String shipmentCode;
  final String fromLocation;
  final String toLocation;
  final String carrierName;
  final String? vehiclePlate;
  final String status;
  final String? departureTime;
  final String? arrivalTime;
  final List<EventInfo> events;

  ShipmentInfo({
    required this.shipmentCode,
    required this.fromLocation,
    required this.toLocation,
    required this.carrierName,
    this.vehiclePlate,
    required this.status,
    this.departureTime,
    this.arrivalTime,
    required this.events,
  });

  factory ShipmentInfo.fromJson(Map<String, dynamic> json) => ShipmentInfo(
        shipmentCode: json['shipmentCode'] ?? '',
        fromLocation: json['fromLocation'] ?? '',
        toLocation: json['toLocation'] ?? '',
        carrierName: json['carrierName'] ?? '',
        vehiclePlate: json['vehiclePlate'],
        status: json['status'] ?? '',
        departureTime: json['departureTime'],
        arrivalTime: json['arrivalTime'],
        events: (json['events'] as List? ?? [])
            .map((e) => EventInfo.fromJson(e))
            .toList(),
      );
}

class EventInfo {
  final String eventType;
  final String? locationAddress;
  final double? temperature;
  final double? humidity;
  final String? notes;
  final String recordedBy;
  final String eventTime;

  EventInfo({
    required this.eventType,
    this.locationAddress,
    this.temperature,
    this.humidity,
    this.notes,
    required this.recordedBy,
    required this.eventTime,
  });

  factory EventInfo.fromJson(Map<String, dynamic> json) => EventInfo(
        eventType: json['eventType'] ?? '',
        locationAddress: json['locationAddress'],
        temperature: json['temperature']?.toDouble(),
        humidity: json['humidity']?.toDouble(),
        notes: json['notes'],
        recordedBy: json['recordedBy'] ?? 'Sistem',
        eventTime: json['eventTime'] ?? '',
      );
}
