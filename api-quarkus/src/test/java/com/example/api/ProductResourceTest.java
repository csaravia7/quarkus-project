package com.example.api;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;

@QuarkusTest
class ProductResourceTest {

    @Test
    void listProducts() {
        given().when().get("/api/products")
                .then().statusCode(200)
                .body("size()", greaterThanOrEqualTo(2));
    }

    @Test
    void createProduct() {
        given().contentType(ContentType.JSON)
                .body("{\"name\":\"Teclado\",\"price\":45.0}")
                .when().post("/api/products")
                .then().statusCode(201)
                .body("id", notNullValue())
                .body("name", is("Teclado"));
    }

    @Test
    void rejectsInvalidProduct() {
        given().contentType(ContentType.JSON)
                .body("{\"name\":\"\",\"price\":-1}")
                .when().post("/api/products")
                .then().statusCode(400);
    }

    @Test
    void health() {
        given().when().get("/q/health/ready").then().statusCode(200);
    }
}
