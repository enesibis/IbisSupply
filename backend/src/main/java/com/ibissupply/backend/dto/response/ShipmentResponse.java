package com.ibissupply.backend.dto.response;

import com.ibissupply.backend.entity.Shipment;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
public class ShipmentResponse {
    private UUID id;
    private String shipmentCode;
    private UUID batchId;
    private String batchCode;
    private String productName;
    private String fromLocation;
    private String toLocation;
    private String carrierName;
    private String vehiclePlate;
    private String status;
    private LocalDateTime departureTime;
    private LocalDateTime arrivalTime;
    private LocalDateTime createdAt;
    private String blockchainTxHash;
    private List<ShipmentEventResponse> events;

    public static ShipmentResponse from(Shipment s) {
        ShipmentResponse r = new ShipmentResponse();
        r.setId(s.getId());
        r.setShipmentCode(s.getShipmentCode());
        r.setBatchId(s.getBatch().getId());
        r.setBatchCode(s.getBatch().getBatchCode());
        r.setProductName(s.getBatch().getProduct() != null ? s.getBatch().getProduct().getName() : "");
        r.setFromLocation(s.getFromLocation());
        r.setToLocation(s.getToLocation());
        r.setCarrierName(s.getCarrier().getFullName());
        r.setVehiclePlate(s.getVehiclePlate());
        r.setStatus(s.getStatus().name());
        r.setDepartureTime(s.getDepartureTime());
        r.setArrivalTime(s.getArrivalTime());
        r.setCreatedAt(s.getCreatedAt());
        r.setBlockchainTxHash(s.getBlockchainTxHash());
        return r;
    }
}
