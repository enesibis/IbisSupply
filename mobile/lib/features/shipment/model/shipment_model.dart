class ShipmentEvent {
  final String id;
  final String eventType;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final double? temperature;
  final double? humidity;
  final String? notes;
  final String? recordedByName;
  final String eventTime;
  final String? blockchainTxHash;

  const ShipmentEvent({
    required this.id,
    required this.eventType,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.temperature,
    this.humidity,
    this.notes,
    this.recordedByName,
    required this.eventTime,
    this.blockchainTxHash,
  });

  factory ShipmentEvent.fromJson(Map<String, dynamic> json) => ShipmentEvent(
        id: json['id'] ?? '',
        eventType: json['eventType'] ?? '',
        locationAddress: json['locationAddress'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        temperature: (json['temperature'] as num?)?.toDouble(),
        humidity: (json['humidity'] as num?)?.toDouble(),
        notes: json['notes'],
        recordedByName: json['recordedByName'],
        eventTime: json['eventTime'] ?? '',
        blockchainTxHash: json['blockchainTxHash'],
      );
}

class ShipmentResponse {
  final String id;
  final String shipmentCode;
  final String batchId;
  final String batchCode;
  final String productName;
  final String fromLocation;
  final String toLocation;
  final String carrierName;
  final String? vehiclePlate;
  final String status;
  final String? departureTime;
  final String? arrivalTime;
  final String? createdAt;
  final String? blockchainTxHash;
  final List<ShipmentEvent> events;

  const ShipmentResponse({
    required this.id,
    required this.shipmentCode,
    required this.batchId,
    required this.batchCode,
    required this.productName,
    required this.fromLocation,
    required this.toLocation,
    required this.carrierName,
    this.vehiclePlate,
    required this.status,
    this.departureTime,
    this.arrivalTime,
    this.createdAt,
    this.blockchainTxHash,
    this.events = const [],
  });

  factory ShipmentResponse.fromJson(Map<String, dynamic> json) => ShipmentResponse(
        id: json['id'] ?? '',
        shipmentCode: json['shipmentCode'] ?? '',
        batchId: json['batchId'] ?? '',
        batchCode: json['batchCode'] ?? '',
        productName: json['productName'] ?? '',
        fromLocation: json['fromLocation'] ?? '',
        toLocation: json['toLocation'] ?? '',
        carrierName: json['carrierName'] ?? '',
        vehiclePlate: json['vehiclePlate'],
        status: json['status'] ?? 'PENDING',
        departureTime: json['departureTime'],
        arrivalTime: json['arrivalTime'],
        createdAt: json['createdAt'],
        blockchainTxHash: json['blockchainTxHash'],
        events: (json['events'] as List<dynamic>? ?? [])
            .map((e) => ShipmentEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
