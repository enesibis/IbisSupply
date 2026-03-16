package com.ibissupply.backend.dto.response;

import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.Shipment;
import com.ibissupply.backend.entity.ShipmentEvent;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Data
@Builder
public class TraceResponse {

    private BatchInfo batch;
    private List<ShipmentInfo> shipments;

    @Data
    @Builder
    public static class BatchInfo {
        private String batchCode;
        private String qrCode;
        private String productName;
        private String productCategory;
        private String productSku;
        private String producerName;
        private String organizationName;
        private Double quantity;
        private String unit;
        private LocalDate productionDate;
        private LocalDate expiryDate;
        private String originLocation;
        private String status;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    public static class ShipmentInfo {
        private String shipmentCode;
        private String fromLocation;
        private String toLocation;
        private String carrierName;
        private String vehiclePlate;
        private String status;
        private LocalDateTime departureTime;
        private LocalDateTime arrivalTime;
        private LocalDateTime createdAt;
        private List<EventInfo> events;
    }

    @Data
    @Builder
    public static class EventInfo {
        private String eventType;
        private String locationAddress;
        private Double latitude;
        private Double longitude;
        private Double temperature;
        private Double humidity;
        private String notes;
        private String recordedBy;
        private LocalDateTime eventTime;
    }

    public static TraceResponse from(ProductBatch batch, List<Shipment> shipments,
                                     java.util.function.Function<Shipment, List<ShipmentEvent>> eventLoader) {
        BatchInfo batchInfo = BatchInfo.builder()
                .batchCode(batch.getBatchCode())
                .qrCode(batch.getQrCode())
                .productName(batch.getProduct() != null ? batch.getProduct().getName() : "")
                .productCategory(batch.getProduct() != null ? batch.getProduct().getCategory() : "")
                .productSku(batch.getProduct() != null ? batch.getProduct().getSku() : "")
                .producerName(batch.getProducer() != null ? batch.getProducer().getFullName() : "")
                .organizationName(batch.getOrganization() != null ? batch.getOrganization().getName() : "")
                .quantity(batch.getQuantity())
                .unit(batch.getUnit())
                .productionDate(batch.getProductionDate())
                .expiryDate(batch.getExpiryDate())
                .originLocation(batch.getOriginLocation())
                .status(batch.getStatus() != null ? batch.getStatus().name() : "")
                .createdAt(batch.getCreatedAt())
                .build();

        List<ShipmentInfo> shipmentInfos = shipments.stream().map(s -> {
            List<ShipmentEvent> events = eventLoader.apply(s);
            List<EventInfo> eventInfos = events.stream().map(e -> EventInfo.builder()
                    .eventType(e.getEventType())
                    .locationAddress(e.getLocationAddress())
                    .latitude(e.getLatitude())
                    .longitude(e.getLongitude())
                    .temperature(e.getTemperature())
                    .humidity(e.getHumidity())
                    .notes(e.getNotes())
                    .recordedBy(e.getRecordedBy() != null ? e.getRecordedBy().getFullName() : "Sistem")
                    .eventTime(e.getEventTime())
                    .build()).collect(Collectors.toList());

            return ShipmentInfo.builder()
                    .shipmentCode(s.getShipmentCode())
                    .fromLocation(s.getFromLocation())
                    .toLocation(s.getToLocation())
                    .carrierName(s.getCarrier() != null ? s.getCarrier().getFullName() : "")
                    .vehiclePlate(s.getVehiclePlate())
                    .status(s.getStatus() != null ? s.getStatus().name() : "")
                    .departureTime(s.getDepartureTime())
                    .arrivalTime(s.getArrivalTime())
                    .createdAt(s.getCreatedAt())
                    .events(eventInfos)
                    .build();
        }).collect(Collectors.toList());

        return TraceResponse.builder()
                .batch(batchInfo)
                .shipments(shipmentInfos)
                .build();
    }
}
