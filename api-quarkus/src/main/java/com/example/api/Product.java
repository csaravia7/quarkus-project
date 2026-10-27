package com.example.api;

import io.quarkus.runtime.annotations.RegisterForReflection;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;

@RegisterForReflection
public record Product(Long id, @NotBlank String name, @PositiveOrZero double price) {

    public Product withId(Long newId) {
        return new Product(newId, name, price);
    }
}
