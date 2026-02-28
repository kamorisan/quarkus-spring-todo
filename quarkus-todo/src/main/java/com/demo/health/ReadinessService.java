package com.demo.health;

import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import org.jboss.logging.Logger;

@ApplicationScoped
public class ReadinessService {

    private static final Logger LOG = Logger.getLogger(ReadinessService.class);

    @Inject
    EntityManager em;

    private volatile boolean ready = false;
    private long startTime;
    private long readyTime;

    void onStart(@Observes StartupEvent ev) {
        startTime = System.currentTimeMillis();
        LOG.info("Application starting...");

        try {
            // DB接続確認
            em.createNativeQuery("SELECT 1").getSingleResult();
            ready = true;
            readyTime = System.currentTimeMillis();
            long duration = readyTime - startTime;
            LOG.infof("APP_READY_MS=%d", duration);
        } catch (Exception e) {
            LOG.error("Failed to connect to database", e);
            ready = false;
        }
    }

    public boolean isReady() {
        return ready;
    }

    public long getStartupTimeMs() {
        return ready ? (readyTime - startTime) : -1;
    }
}
