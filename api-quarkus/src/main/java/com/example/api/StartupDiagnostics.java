package com.example.api;

import io.quarkus.logging.Log;
import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@ApplicationScoped
public class StartupDiagnostics {

    void onStart(@Observes StartupEvent event) {
        String mode = System.getProperty("org.graalvm.nativeimage.imagecode") != null ? "native" : "jvm";
        Log.infof("Runtime mode: %s", mode);
        Log.infof("Dynatrace OneAgent loaded in process: %s", oneAgentLoaded());
        Log.infof("LD_PRELOAD=%s", System.getenv().getOrDefault("LD_PRELOAD", "<not set>"));
    }

    // Las librerías de OneAgent inyectadas aparecen en el mapa de memoria del proceso
    private boolean oneAgentLoaded() {
        try {
            return Files.readString(Path.of("/proc/self/maps")).contains("oneagent");
        } catch (IOException e) {
            return false;
        }
    }
}
