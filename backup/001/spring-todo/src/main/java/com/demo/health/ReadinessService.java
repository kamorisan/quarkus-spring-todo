package com.demo.health;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

@Service
public class ReadinessService {

    private static final Logger LOG = LoggerFactory.getLogger(ReadinessService.class);

    @PersistenceContext
    private EntityManager em;

    private volatile boolean ready = false;
    private long startTime;
    private long readyTime;

    public ReadinessService() {
        this.startTime = System.currentTimeMillis();
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        LOG.info("Application ready event received");

        try {
            // DB接続確認
            em.createNativeQuery("SELECT 1").getSingleResult();
            ready = true;
            readyTime = System.currentTimeMillis();
            long duration = readyTime - startTime;
            LOG.info("APP_READY_MS={}", duration);
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
