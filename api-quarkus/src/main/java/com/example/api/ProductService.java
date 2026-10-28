package com.example.api;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

public class ProductService {

    private final Map<Long, Product> store = new ConcurrentHashMap<>();
    private final AtomicLong sequence = new AtomicLong();

    public ProductService() {
        create(new Product(null, "Laptop", 1200.0));
        create(new Product(null, "Mouse", 25.5));
    }

    public List<Product> findAll() {
        return store.values().stream().sorted(Comparator.comparing(Product::id)).toList();
    }

    public Optional<Product> findById(Long id) {
        return Optional.ofNullable(store.get(id));
    }

    public Product create(Product product) {
        Product saved = product.withId(sequence.incrementAndGet());
        store.put(saved.id(), saved);
        return saved;
    }

    public Optional<Product> update(Long id, Product product) {
        return Optional.ofNullable(
            store.computeIfPresent(id, (existingId, current) -> product.withId(existingId)));
    }

    public boolean delete(Long id) {
        return store.remove(id) != null;
    }
}
