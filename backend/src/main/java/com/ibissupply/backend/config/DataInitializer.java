package com.ibissupply.backend.config;

import com.ibissupply.backend.entity.Organization;
import com.ibissupply.backend.entity.Product;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.enums.UserRole;
import com.ibissupply.backend.repository.OrganizationRepository;
import com.ibissupply.backend.repository.ProductRepository;
import com.ibissupply.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final OrganizationRepository organizationRepository;
    private final ProductRepository productRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (userRepository.existsByEmail("admin@ibissupply.com")) {
            // Kullanıcılar var ama ürünler yoksa ekle
            if (productRepository.count() == 0) {
                userRepository.findByEmail("producer@ibissupply.com").ifPresent(producer -> {
                    Organization producerOrg = producer.getOrganization();
                    productRepository.save(Product.builder()
                            .name("Domates").category("VEGETABLE").sku("VEG-001")
                            .description("Organik domates").unit("KG")
                            .minSafeTemp(4.0).maxSafeTemp(10.0)
                            .organization(producerOrg).build());
                    productRepository.save(Product.builder()
                            .name("Elma").category("FRUIT").sku("FRT-001")
                            .description("Amasya elması").unit("KG")
                            .minSafeTemp(2.0).maxSafeTemp(8.0)
                            .organization(producerOrg).build());
                    productRepository.save(Product.builder()
                            .name("Süt").category("DAIRY").sku("DAI-001")
                            .description("Tam yağlı süt").unit("LITER")
                            .minSafeTemp(2.0).maxSafeTemp(6.0)
                            .organization(producerOrg).build());
                    log.info("Test products created");
                });
            }
            return;
        }

        // Create test organization
        Organization org = organizationRepository.save(Organization.builder()
                .name("IbisSupply HQ")
                .type(UserRole.ADMIN)
                .address("Ankara, Turkey")
                .verified(true)
                .build());

        // Create admin user
        userRepository.save(User.builder()
                .email("admin@ibissupply.com")
                .passwordHash(passwordEncoder.encode("admin123"))
                .fullName("Admin User")
                .role(UserRole.ADMIN)
                .organization(org)
                .build());

        // Create producer user
        Organization producerOrg = organizationRepository.save(Organization.builder()
                .name("Örnek Tarım A.Ş.")
                .type(UserRole.PRODUCER)
                .address("İzmir, Turkey")
                .verified(true)
                .build());

        userRepository.save(User.builder()
                .email("producer@ibissupply.com")
                .passwordHash(passwordEncoder.encode("producer123"))
                .fullName("Producer User")
                .role(UserRole.PRODUCER)
                .organization(producerOrg)
                .build());

        // Create logistics user
        Organization logisticsOrg = organizationRepository.save(Organization.builder()
                .name("Hızlı Lojistik Ltd.")
                .type(UserRole.LOGISTICS)
                .address("İstanbul, Turkey")
                .verified(true)
                .build());

        userRepository.save(User.builder()
                .email("logistics@ibissupply.com")
                .passwordHash(passwordEncoder.encode("logistics123"))
                .fullName("Logistics User")
                .role(UserRole.LOGISTICS)
                .organization(logisticsOrg)
                .build());

        // Test ürünler (producer org'a bağlı)
        productRepository.save(Product.builder()
                .name("Domates").category("VEGETABLE").sku("VEG-001")
                .description("Organik domates").unit("KG")
                .minSafeTemp(4.0).maxSafeTemp(10.0)
                .organization(producerOrg).build());

        productRepository.save(Product.builder()
                .name("Elma").category("FRUIT").sku("FRT-001")
                .description("Amasya elması").unit("KG")
                .minSafeTemp(2.0).maxSafeTemp(8.0)
                .organization(producerOrg).build());

        productRepository.save(Product.builder()
                .name("Süt").category("DAIRY").sku("DAI-001")
                .description("Tam yağlı süt").unit("LITER")
                .minSafeTemp(2.0).maxSafeTemp(6.0)
                .organization(producerOrg).build());

        log.info("Test data created: users + products");
    }
}
