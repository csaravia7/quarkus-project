package com.example.api;

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
        return service.findAll();
    }

    @GET
    @Path("/{id}")
    public Product get(@PathParam("id") Long id) {
        return service.findById(id).orElseThrow(NotFoundException::new);
    }

    @POST
    public Response create(@Valid Product product) {
        Product saved = service.create(product);
        return Response.created(URI.create("/api/products/" + saved.id())).entity(saved).build();
    }

    @DELETE
    @Path("/{id}")
    public Response delete(@PathParam("id") Long id) {
        if (!service.delete(id)) {
            throw new NotFoundException();
        }
        return Response.noContent().build();
    }
}
