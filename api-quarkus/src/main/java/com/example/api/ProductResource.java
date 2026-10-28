package com.example.api;

import io.quarkus.logging.Log;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.net.URI;
import java.util.List;

@Path("/api/products")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ProductResource {

    @Inject
    ProductService service;

    @GET
    public List<Product> list() {
        List<Product> products = service.findAll();
        Log.infof("Listing %d products", products.size());
        return products;
    }

    @GET
    @Path("/{id}")
    public Product get(@PathParam("id") Long id) {
        return service.findById(id).orElseThrow(() -> {
            Log.warnf("Product %d not found", id);
            return new NotFoundException();
        });
    }

    @POST
    public Response create(@Valid Product product) {
        Product saved = service.create(product);
        Log.infof("Created product id=%d name=%s", saved.id(), saved.name());
        return Response.created(URI.create("/api/products/" + saved.id())).entity(saved).build();
    }

    @DELETE
    @Path("/{id}")
    public Response delete(@PathParam("id") Long id) {
        if (!service.delete(id)) {
            Log.warnf("Delete failed, product %d not found", id);
            throw new NotFoundException();
        }
        Log.infof("Deleted product id=%d", id);
        return Response.noContent().build();
    }
}
