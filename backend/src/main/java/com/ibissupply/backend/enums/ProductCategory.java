package com.ibissupply.backend.enums;

public enum ProductCategory {
    FRUIT,      // Meyve
    VEGETABLE,  // Sebze
    GRAIN,      // Tahıl
    DAIRY,      // Süt ürünleri
    LEGUME,     // Baklagil
    HERB,       // Baharat / aromatik ot
    NUT,        // Kuruyemiş
    MEAT,       // Et (çiftlik hayvanları)
    OIL,        // Bitkisel yağ / zeytinyağı
    DEFAULT;    // Kategori belirtilmemiş

    public static boolean isValid(String value) {
        if (value == null) return false;
        for (ProductCategory c : values()) {
            if (c.name().equalsIgnoreCase(value)) return true;
        }
        return false;
    }
}
