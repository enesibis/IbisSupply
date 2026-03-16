package com.ibissupply.backend.service;

import com.ibissupply.backend.dto.response.TraceResponse;
import com.ibissupply.backend.entity.ProductBatch;
import com.ibissupply.backend.entity.Shipment;
import com.ibissupply.backend.repository.BatchRepository;
import com.ibissupply.backend.repository.ShipmentEventRepository;
import com.ibissupply.backend.repository.ShipmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TraceService {

    private final BatchRepository batchRepository;
    private final ShipmentRepository shipmentRepository;
    private final ShipmentEventRepository shipmentEventRepository;

    public TraceResponse traceByBatchCode(String batchCode) {
        ProductBatch batch = batchRepository.findByBatchCode(batchCode)
                .orElseThrow(() -> new RuntimeException("Batch bulunamadı: " + batchCode));

        List<Shipment> shipments = shipmentRepository.findByBatchIdOrderByCreatedAtDesc(batch.getId());

        return TraceResponse.from(batch, shipments,
                shipment -> shipmentEventRepository.findByShipmentIdOrderByEventTimeAsc(shipment.getId()));
    }

    public TraceResponse traceByQrCode(String qrCode) {
        ProductBatch batch = batchRepository.findByQrCode(qrCode)
                .orElseThrow(() -> new RuntimeException("QR koda ait ürün bulunamadı"));

        List<Shipment> shipments = shipmentRepository.findByBatchIdOrderByCreatedAtDesc(batch.getId());

        return TraceResponse.from(batch, shipments,
                shipment -> shipmentEventRepository.findByShipmentIdOrderByEventTimeAsc(shipment.getId()));
    }
}
