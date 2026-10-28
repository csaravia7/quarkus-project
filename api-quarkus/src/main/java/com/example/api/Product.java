package com.example.api;

import io.quarkus.runtime.annotations.RegisterForReflection;

@RegisterForReflection
public record Product(Long id, String name, double price) {

    public Product withId(Long newId) {
        return new Product(newId, name, price);
    }
}
