package com.ibissupply.backend.config;

import com.ibissupply.backend.entity.Organization;
import com.ibissupply.backend.entity.User;
import com.ibissupply.backend.enums.UserRole;
import com.ibissupply.backend.repository.OrganizationRepository;
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
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (userRepository.existsByEmail("admin@ibissupply.com")) {
            return; // already initialized
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

        log.info("Test users created: admin@ibissupply.com / admin123");
    }
}
