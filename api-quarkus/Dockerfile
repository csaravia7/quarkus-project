## Stage 1: compila el ejecutable nativo con Mandrel (GraalVM)
FROM quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-21 AS build
COPY --chown=quarkus:quarkus --chmod=0755 mvnw /code/mvnw
COPY --chown=quarkus:quarkus .mvn /code/.mvn
COPY --chown=quarkus:quarkus pom.xml /code/
USER quarkus
WORKDIR /code
RUN ./mvnw -B org.apache.maven.plugins:maven-dependency-plugin:3.8.1:go-offline
COPY --chown=quarkus:quarkus src /code/src
RUN ./mvnw -B package -Dnative -DskipTests

## Stage 2: imagen runtime mínima, sin JVM
FROM quay.io/quarkus/ubi9-quarkus-micro-image:2.0
WORKDIR /work/
COPY --from=build --chown=1001:root --chmod=0755 /code/target/*-runner /work/application
RUN chown 1001:root /work && chmod "g+rwX" /work
EXPOSE 8080
USER 1001
ENTRYPOINT ["./application", "-Dquarkus.http.host=0.0.0.0"]
