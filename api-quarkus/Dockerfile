# syntax=docker/dockerfile:1.10
## Stage 1: compila el ejecutable nativo con GraalVM CE
FROM quay.io/quarkus/ubi9-quarkus-graalvmce-builder-image:jdk-21 AS build
# Si se define, el binario se compila con el módulo Dynatrace GraalVM Native Image
ARG DT_ENV_URL=""
COPY --chown=quarkus:quarkus --chmod=0755 mvnw /code/mvnw
COPY --chown=quarkus:quarkus .mvn /code/.mvn
COPY --chown=quarkus:quarkus pom.xml /code/
USER quarkus
WORKDIR /code
RUN ./mvnw -B org.apache.maven.plugins:maven-dependency-plugin:3.8.1:go-offline
COPY --chown=quarkus:quarkus src /code/src
# El token llega como secreto de BuildKit: no queda guardado en ninguna capa de la imagen
RUN --mount=type=secret,id=dt_api_token,env=DT_API_TOKEN \
    if [ -n "$DT_ENV_URL" ]; then DT_PROFILE="-Pdynatrace-native"; fi; \
    ./mvnw -B package -Dnative -DskipTests ${DT_PROFILE:-} \
    && mkdir -p target/dynatrace

## Stage 2: imagen runtime mínima, sin JVM
FROM quay.io/quarkus/ubi9-quarkus-micro-image:2.0
WORKDIR /work/
COPY --from=build --chown=1001:root --chmod=0755 /code/target/*-runner /work/application
# Módulo runtime de Dynatrace (vacío si se compiló sin DT_ENV_URL); debe estar junto al binario
COPY --from=build --chown=1001:root /code/target/dynatrace /work/dynatrace
RUN chown 1001:root /work && chmod "g+rwX" /work
EXPOSE 8080
USER 1001
ENTRYPOINT ["./application", "-Dquarkus.http.host=0.0.0.0"]
