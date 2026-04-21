package com.ibissupply.backend.service;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.RawTransaction;
import org.web3j.crypto.TransactionEncoder;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.response.EthGetTransactionCount;
import org.web3j.protocol.core.methods.response.EthSendTransaction;
import org.web3j.protocol.http.HttpService;
import org.web3j.abi.FunctionEncoder;
import org.web3j.abi.datatypes.Function;
import org.web3j.abi.datatypes.Utf8String;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.generated.Bytes32;
import org.web3j.abi.datatypes.generated.Uint8;
import org.web3j.utils.Numeric;

import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
public class BlockchainService {

    @Value("${blockchain.enabled:false}")
    private boolean enabled;

    @Value("${blockchain.rpc-url:http://localhost:8545}")
    private String rpcUrl;

    @Value("${blockchain.chain-id:31337}")
    private long chainId;

    @Value("${blockchain.private-key:}")
    private String privateKey;

    @Value("${blockchain.addresses.batch-registry:}")
    private String batchRegistryAddress;

    @Value("${blockchain.addresses.shipment-registry:}")
    private String shipmentRegistryAddress;

    @Value("${blockchain.addresses.quality-registry:}")
    private String qualityRegistryAddress;

    @Value("${blockchain.addresses.farm-registry:}")
    private String farmRegistryAddress;

    @Value("${blockchain.addresses.certificate-nft:}")
    private String certificateNftAddress;

    private Web3j web3j;
    private Credentials credentials;

    @PostConstruct
    public void init() {
        if (!enabled) {
            log.info("Blockchain bridge devre disi. Etkinlestirmek icin blockchain.enabled=true yap.");
            return;
        }
        try {
            web3j = Web3j.build(new HttpService(rpcUrl));
            credentials = Credentials.create(privateKey);
            log.info("Blockchain bridge baglandi: {} / Adres: {}", rpcUrl, credentials.getAddress());
        } catch (Exception e) {
            log.error("Blockchain baglantisi kurulamadi: {}", e.getMessage());
        }
    }

    /**
     * BatchRegistry.createBatch(batchCode, dataHash)
     * Batch oluşturulduğunda çağrılır.
     */
    public Optional<String> registerBatch(String batchCode, String producerEmail, String productName) {
        if (!isReady(batchRegistryAddress)) return Optional.empty();
        try {
            byte[] dataHash = sha256(batchCode + producerEmail + productName);
            Function function = new Function(
                    "createBatch",
                    List.of(new Utf8String(batchCode), new Bytes32(dataHash)),
                    Collections.emptyList()
            );
            return sendTx(batchRegistryAddress, function);
        } catch (Exception e) {
            log.warn("[Blockchain] createBatch hata: {}", e.getMessage());
            return Optional.empty();
        }
    }

    /**
     * ShipmentRegistry.createShipment(shipmentCode, batchCode, routeHash)
     * Sevkiyat oluşturulduğunda çağrılır.
     */
    public Optional<String> registerShipment(String shipmentCode, String batchCode,
                                              String fromLocation, String toLocation) {
        if (!isReady(shipmentRegistryAddress)) return Optional.empty();
        try {
            byte[] routeHash = sha256(fromLocation + "|" + toLocation);
            Function function = new Function(
                    "createShipment",
                    List.of(new Utf8String(shipmentCode), new Utf8String(batchCode), new Bytes32(routeHash)),
                    Collections.emptyList()
            );
            return sendTx(shipmentRegistryAddress, function);
        } catch (Exception e) {
            log.warn("[Blockchain] createShipment hata: {}", e.getMessage());
            return Optional.empty();
        }
    }

    /**
     * ShipmentRegistry.receiveShipment(shipmentCode)
     * Sevkiyat teslim alındığında çağrılır.
     */
    public Optional<String> deliverShipment(String shipmentCode) {
        if (!isReady(shipmentRegistryAddress)) return Optional.empty();
        try {
            Function function = new Function(
                    "receiveShipment",
                    List.of(new Utf8String(shipmentCode)),
                    Collections.emptyList()
            );
            return sendTx(shipmentRegistryAddress, function);
        } catch (Exception e) {
            log.warn("[Blockchain] receiveShipment hata: {}", e.getMessage());
            return Optional.empty();
        }
    }

    /**
     * QualityRegistry.addQualityCheck(batchCode, dataHash, result)
     * Kalite kontrol kaydedildiğinde çağrılır.
     * Solidity enum: PENDING=0, PASSED=1, FAILED=2, MARGINAL=3
     */
    public Optional<String> registerQualityCheck(String batchCode, String result, String notes) {
        if (!isReady(qualityRegistryAddress)) return Optional.empty();
        try {
            String notesSafe = notes != null ? notes : "";
            byte[] dataHash = sha256(batchCode + result + notesSafe);
            BigInteger resultEnum = mapQualityResult(result);
            Function function = new Function(
                    "addQualityCheck",
                    List.of(new Utf8String(batchCode), new Bytes32(dataHash), new Uint8(resultEnum)),
                    Collections.emptyList()
            );
            return sendTx(qualityRegistryAddress, function);
        } catch (Exception e) {
            log.warn("[Blockchain] addQualityCheck hata: {}", e.getMessage());
            return Optional.empty();
        }
    }

    /**
     * CertificateNFT.mintCertificate(to, batchCode, productName, certType)
     * Kalite kontrolden PASSED geçen batch için NFT sertifikası mint eder.
     */
    public Optional<String> mintCertificateNFT(String batchCode, String productName) {
        if (!isReady(certificateNftAddress)) return Optional.empty();
        try {
            Function function = new Function(
                    "mintCertificate",
                    List.of(
                            new Address(credentials.getAddress()),
                            new Utf8String(batchCode),
                            new Utf8String(productName),
                            new Utf8String("QUALITY_PASS")
                    ),
                    Collections.emptyList()
            );
            return sendTx(certificateNftAddress, function);
        } catch (Exception e) {
            log.warn("[Blockchain] mintCertificate hata: {}", e.getMessage());
            return Optional.empty();
        }
    }

    /**
     * FarmRegistry.recordFarmData(batchCode, dataHash)
     * Tarımsal kayıt oluşturulduğunda çağrılır.
     */
    public Optional<String> registerFarmRecord(String batchCode, String fieldLocation,
                                               String irrigationType, String pesticides) {
        if (!isReady(farmRegistryAddress)) return Optional.empty();
        try {
            String pesticidesSafe = pesticides != null ? pesticides : "";
            String fieldSafe = fieldLocation != null ? fieldLocation : "";
            String irrigationSafe = irrigationType != null ? irrigationType : "";
            byte[] dataHash = sha256(batchCode + fieldSafe + irrigationSafe + pesticidesSafe);
            Function function = new Function(
                    "recordFarmData",
                    List.of(new Utf8String(batchCode), new Bytes32(dataHash)),
                    Collections.emptyList()
            );
            return sendTx(farmRegistryAddress, function);
        } catch (Exception e) {
            log.warn("[Blockchain] recordFarmData hata: {}", e.getMessage());
            return Optional.empty();
        }
    }

    /**
     * CertificateNFT.getCertByBatch(batchCode) — on-chain sertifika bilgisini okur.
     * Sertifika varsa Map döner, yoksa boş Optional.
     */
    public Optional<java.util.Map<String, Object>> getCertificateByBatch(String batchCode) {
        if (!isReady(certificateNftAddress)) return Optional.empty();
        try {
            Function function = new Function(
                    "getCertByBatch",
                    List.of(new Utf8String(batchCode)),
                    List.of(
                            new org.web3j.abi.TypeReference<org.web3j.abi.datatypes.generated.Uint256>() {},
                            new org.web3j.abi.TypeReference<org.web3j.abi.datatypes.DynamicStruct>() {},
                            new org.web3j.abi.TypeReference<org.web3j.abi.datatypes.Bool>() {}
                    )
            );
            String encoded = FunctionEncoder.encode(function);
            org.web3j.protocol.core.methods.request.Transaction callTx =
                    org.web3j.protocol.core.methods.request.Transaction.createEthCallTransaction(
                            credentials.getAddress(), certificateNftAddress, encoded);
            String result = web3j.ethCall(callTx, DefaultBlockParameterName.LATEST).send().getValue();

            if (result == null || result.equals("0x")) return Optional.empty();

            java.util.List<org.web3j.abi.datatypes.Type> decoded =
                    org.web3j.abi.FunctionReturnDecoder.decode(result, function.getOutputParameters());

            if (decoded.isEmpty()) return Optional.empty();

            boolean exists = decoded.size() >= 3 && ((org.web3j.abi.datatypes.Bool) decoded.get(2)).getValue();
            if (!exists) return Optional.empty();

            BigInteger tokenId = ((org.web3j.abi.datatypes.generated.Uint256) decoded.get(0)).getValue();

            java.util.Map<String, Object> info = new java.util.HashMap<>();
            info.put("tokenId", tokenId.toString());
            info.put("batchCode", batchCode);
            info.put("certType", "QUALITY_PASS");
            info.put("exists", true);

            return Optional.of(info);
        } catch (Exception e) {
            log.warn("[Blockchain] getCertByBatch hata: {}", e.getMessage());
            return Optional.empty();
        }
    }

    // ─── Yardımcı Metodlar ────────────────────────────────────────────────────

    private boolean isReady(String contractAddress) {
        if (!enabled || web3j == null || credentials == null) return false;
        if (contractAddress == null || contractAddress.isBlank()) {
            log.debug("[Blockchain] Kontrat adresi tanimlanmamis, atlaniyor.");
            return false;
        }
        return true;
    }

    private Optional<String> sendTx(String contractAddress, Function function) throws Exception {
        String encoded = FunctionEncoder.encode(function);

        EthGetTransactionCount txCountResponse = web3j
                .ethGetTransactionCount(credentials.getAddress(), DefaultBlockParameterName.LATEST)
                .send();
        BigInteger nonce = txCountResponse.getTransactionCount();
        BigInteger gasPrice = web3j.ethGasPrice().send().getGasPrice();
        BigInteger gasLimit = BigInteger.valueOf(300_000);

        RawTransaction rawTx = RawTransaction.createTransaction(
                nonce, gasPrice, gasLimit, contractAddress, encoded);

        byte[] signedMsg = TransactionEncoder.signMessage(rawTx, chainId, credentials);
        String hexValue = Numeric.toHexString(signedMsg);

        EthSendTransaction ethSend = web3j.ethSendRawTransaction(hexValue).send();

        if (ethSend.hasError()) {
            log.warn("[Blockchain] TX hatasi: {}", ethSend.getError().getMessage());
            return Optional.empty();
        }

        String txHash = ethSend.getTransactionHash();
        log.info("[Blockchain] TX gonderildi: {}", txHash);
        return Optional.ofNullable(txHash);
    }

    private byte[] sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return digest.digest(input.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new RuntimeException("SHA-256 hatasi", e);
        }
    }

    private BigInteger mapQualityResult(String result) {
        return switch (result) {
            case "PASSED"       -> BigInteger.ONE;
            case "FAILED"       -> BigInteger.TWO;
            case "NEEDS_REVIEW" -> BigInteger.valueOf(3);
            default             -> BigInteger.ZERO;
        };
    }
}
