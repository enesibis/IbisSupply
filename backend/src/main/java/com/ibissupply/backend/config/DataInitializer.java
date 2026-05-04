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
            if (productRepository.count() == 0) {
                userRepository.findByEmail("producer@ibissupply.com").ifPresent(producer -> {
                    seedProducts(producer.getOrganization());
                });
            }
            return;
        }

        Organization org = organizationRepository.save(Organization.builder()
                .name("IbisSupply HQ")
                .type(UserRole.ADMIN)
                .address("Ankara, Turkey")
                .verified(true)
                .build());

        userRepository.save(User.builder()
                .email("admin@ibissupply.com")
                .passwordHash(passwordEncoder.encode("admin123"))
                .fullName("Admin User")
                .role(UserRole.ADMIN)
                .organization(org)
                .build());

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

        seedProducts(producerOrg);
        log.info("Test data created: users + products");
    }

    private void seedProducts(Organization org) {
        // FRUIT
        save(org, "Organik Çilek",  "FRUIT", "FRT-001", "Sertifikalı organik çilek",  "KG",  2.0, 8.0);
        save(org, "Elma",           "FRUIT", "FRT-002", "Amasya elması",               "KG",  2.0, 8.0);
        save(org, "Domates",        "FRUIT", "FRT-003", "Sera domatesi",               "KG",  8.0, 14.0);
        save(org, "Üzüm",           "FRUIT", "FRT-004", "Manisa Sultani üzüm",         "KG",  2.0, 8.0);
        save(org, "Kayısı",         "FRUIT", "FRT-005", "Malatya kayısı",              "KG",  2.0, 8.0);
        save(org, "Çilek",          "FRUIT", "FRT-006", "Taze çilek",                  "KG",  2.0, 6.0);

        // VEGETABLE
        save(org, "Biber",          "VEGETABLE", "VEG-001", "Kapya biber",             "KG",  8.0, 12.0);
        save(org, "Patates",        "VEGETABLE", "VEG-002", "Erzurum patates",         "KG",  4.0, 10.0);
        save(org, "Soğan",          "VEGETABLE", "VEG-003", "Kuru soğan",              "KG",  4.0, 10.0);
        save(org, "Ispanak",        "VEGETABLE", "VEG-004", "Taze ıspanak",            "KG",  2.0, 6.0);
        save(org, "Havuç",          "VEGETABLE", "VEG-005", "Beypazarı havuç",         "KG",  2.0, 8.0);

        // GRAIN
        save(org, "Buğday",         "GRAIN", "GRN-001", "Ekmeklik buğday",            "KG",  10.0, 25.0);
        save(org, "Mısır",          "GRAIN", "GRN-002", "Hibrit mısır",               "KG",  10.0, 25.0);
        save(org, "Arpa",           "GRAIN", "GRN-003", "Maltlık arpa",               "KG",  10.0, 25.0);

        // LEGUME
        save(org, "Nohut",          "LEGUME", "LGM-001", "Cihanbeyli nohut",          "KG",  10.0, 25.0);
        save(org, "Mercimek",       "LEGUME", "LGM-002", "Kırmızı mercimek",          "KG",  10.0, 25.0);
        save(org, "Fasulye",        "LEGUME", "LGM-003", "Taze fasulye",              "KG",  4.0, 10.0);

        // DAIRY
        save(org, "Süt",            "DAIRY", "DAI-001", "Tam yağlı taze süt",         "LITER", 2.0, 6.0);
        save(org, "Peynir",         "DAIRY", "DAI-002", "Beyaz peynir",               "KG",    2.0, 6.0);
        save(org, "Yoğurt",         "DAIRY", "DAI-003", "Tam yağlı yoğurt",           "KG",    2.0, 6.0);

        // NUT
        save(org, "Fındık",         "NUT", "NUT-001", "Giresun fındığı",              "KG",  10.0, 20.0);
        save(org, "Ceviz",          "NUT", "NUT-002", "Yenipazar cevizi",             "KG",  10.0, 20.0);
        save(org, "Badem",          "NUT", "NUT-003", "İsparta bademi",               "KG",  10.0, 20.0);

        // HERB
        save(org, "Kekik",          "HERB", "HRB-001", "Ege kekiği",                  "KG",  10.0, 25.0);
        save(org, "Nane",           "HERB", "HRB-002", "Taze nane",                   "KG",  4.0, 8.0);

        // OIL
        save(org, "Zeytinyağı",     "OIL", "OIL-001", "Erken hasat sızma zeytinyağı","LITER", 10.0, 22.0);
        save(org, "Zeytin",         "OIL", "OIL-002", "Gemlik zeytini",               "KG",   8.0, 14.0);

        // MEAT
        save(org, "Tavuk Göğsü",    "MEAT", "MET-001", "Taze tavuk göğüs eti",        "KG",  0.0, 4.0);
        save(org, "Kuzu Eti",       "MEAT", "MET-002", "Taze kuzu eti",               "KG",  0.0, 4.0);

        log.info("Seed: {} tarımsal ürün eklendi", productRepository.count());
    }

    private void save(Organization org, String name, String category, String sku,
                      String description, String unit, Double minTemp, Double maxTemp) {
        if (!productRepository.existsBySku(sku)) {
            productRepository.save(Product.builder()
                    .name(name).category(category).sku(sku)
                    .description(description).unit(unit)
                    .minSafeTemp(minTemp).maxSafeTemp(maxTemp)
                    .organization(org).build());
        }
    }
}
