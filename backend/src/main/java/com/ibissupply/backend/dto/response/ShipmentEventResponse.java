package com.ibissupply.backend.dto.response;

import com.ibissupply.backend.entity.ShipmentEvent;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
public class ShipmentEventResponse {
    private UUID id;
    private String eventType;
    private String locationAddress;
    private Double latitude;
    private Double longitude;
    private Double temperature;
    private Double humidity;
    private String notes;
    private String recordedByName;
    private LocalDateTime eventTime;
    private String blockchainTxHash;

    public static ShipmentEventResponse from(ShipmentEvent e) {
        ShipmentEventResponse r = new ShipmentEventResponse();
        r.setId(e.getId());
        r.setEventType(e.getEventType());
        r.setLocationAddress(e.getLocationAddress());
        r.setLatitude(e.getLatitude());
        r.setLongitude(e.getLongitude());
        r.setTemperature(e.getTemperature());
        r.setHumidity(e.getHumidity());
        r.setNotes(e.getNotes());
        r.setRecordedByName(e.getRecordedBy() != null ? e.getRecordedBy().getFullName() : null);
        r.setEventTime(e.getEventTime());
        r.setBlockchainTxHash(e.getBlockchainTxHash());
        return r;
    }
}
