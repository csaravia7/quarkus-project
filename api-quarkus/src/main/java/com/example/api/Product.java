package com.example.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;

public record Product(Long id, @NotBlank String name, @PositiveOrZero double price) {

    public Product withId(Long newId) {
        return new Product(newId, name, price);
    }
}
