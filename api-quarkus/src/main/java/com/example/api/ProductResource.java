package com.example.api;

import io.quarkus.vertx.web.Route;
import io.vertx.core.json.Json;
import io.vertx.ext.web.RoutingContext;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

public class ProductResource {

    private static final Logger LOG = LogManager.getLogger(ProductResource.class);

    private final ProductService service;

    ProductResource() {
        service = new ProductService();
        String mode = System.getProperty("org.graalvm.nativeimage.imagecode") != null ? "native" : "jvm";
        LOG.info("Runtime mode: {}", mode);
        LOG.info("Dynatrace OneAgent loaded in process: {}", oneAgentLoaded());
        LOG.info("LD_PRELOAD={}", System.getenv().getOrDefault("LD_PRELOAD", "<not set>"));
    }

    @Route(path = "/api/products", methods = Route.HttpMethod.GET)
    void list(RoutingContext context) {
        List<Product> products = service.findAll();
        LOG.info("Listing {} products", products.size());
        respond(context, 200, products);
    }

    @Route(path = "/api/products/:id", methods = Route.HttpMethod.GET)
    void get(RoutingContext context) {
        Long id = parseId(context);
        if (id == null) {
            context.response().setStatusCode(400).end();
            return;
        }

        Product product = service.findById(id).orElse(null);
        if (product == null) {
            LOG.warn("Product {} not found", id);
            context.response().setStatusCode(404).end();
            return;
        }

        respond(context, 200, product);
    }

    @Route(path = "/api/products", methods = Route.HttpMethod.POST)
    void create(RoutingContext context) {
        Product product = readProduct(context);
        if (!isValid(product)) {
            context.response().setStatusCode(400).end();
            return;
        }

        Product saved = service.create(product);
        LOG.info("Created product id={} name={}", saved.id(), saved.name());
        context.response()
                .setStatusCode(201)
                .putHeader("Location", "/api/products/" + saved.id())
                .putHeader("Content-Type", "application/json")
                .end(Json.encode(saved));
    }

    @Route(path = "/api/products/:id", methods = Route.HttpMethod.PUT)
    void update(RoutingContext context) {
        Long id = parseId(context);
        Product product = readProduct(context);
        if (id == null || !isValid(product)) {
            context.response().setStatusCode(400).end();
            return;
        }

        Product updated = service.update(id, product).orElse(null);
        if (updated == null) {
            LOG.warn("Update failed, product {} not found", id);
            context.response().setStatusCode(404).end();
            return;
        }

        LOG.info("Updated product id={} name={}", updated.id(), updated.name());
        respond(context, 200, updated);
    }

    @Route(path = "/api/products/:id", methods = Route.HttpMethod.DELETE)
    void delete(RoutingContext context) {
        Long id = parseId(context);
        if (id == null) {
            context.response().setStatusCode(400).end();
            return;
        }

        if (!service.delete(id)) {
            LOG.warn("Delete failed, product {} not found", id);
            context.response().setStatusCode(404).end();
            return;
        }

        LOG.info("Deleted product id={}", id);
        context.response().setStatusCode(204).end();
    }

    private static Long parseId(RoutingContext context) {
        try {
            return Long.parseLong(context.pathParam("id"));
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    private static Product readProduct(RoutingContext context) {
        try {
            String body = context.body().asString();
            return body == null || body.isBlank() ? null : Json.decodeValue(body, Product.class);
        } catch (RuntimeException exception) {
            return null;
        }
    }

    private static boolean isValid(Product product) {
        return product != null
                && product.name() != null
                && !product.name().isBlank()
                && Double.isFinite(product.price())
                && product.price() >= 0;
    }

    private static void respond(RoutingContext context, int status, Object body) {
        context.response()
                .setStatusCode(status)
                .putHeader("Content-Type", "application/json")
                .end(Json.encode(body));
    }

    private static boolean oneAgentLoaded() {
        try {
            return Files.readString(Path.of("/proc/self/maps")).contains("oneagent");
        } catch (IOException exception) {
            return false;
        }
    }
}
