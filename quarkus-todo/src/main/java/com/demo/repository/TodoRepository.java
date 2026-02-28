package com.demo.repository;

import com.demo.entity.Todo;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import jakarta.transaction.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class TodoRepository {

    @PersistenceContext
    EntityManager em;

    @Transactional
    public Todo save(Todo todo) {
        if (todo.getId() == null) {
            em.persist(todo);
            return todo;
        } else {
            return em.merge(todo);
        }
    }

    public Optional<Todo> findById(UUID id) {
        Todo todo = em.find(Todo.class, id);
        return Optional.ofNullable(todo);
    }

    public List<Todo> findAll(Boolean completed, String query, int page, int size, String sort) {
        CriteriaBuilder cb = em.getCriteriaBuilder();
        CriteriaQuery<Todo> cq = cb.createQuery(Todo.class);
        Root<Todo> root = cq.from(Todo.class);

        List<Predicate> predicates = new ArrayList<>();

        if (completed != null) {
            predicates.add(cb.equal(root.get("completed"), completed));
        }

        if (query != null && !query.trim().isEmpty()) {
            predicates.add(cb.like(cb.lower(root.get("title")), "%" + query.toLowerCase() + "%"));
        }

        if (!predicates.isEmpty()) {
            cq.where(predicates.toArray(new Predicate[0]));
        }

        // Simple sorting (default: updatedAt desc)
        if (sort != null && sort.contains("updatedAt")) {
            if (sort.contains("asc")) {
                cq.orderBy(cb.asc(root.get("updatedAt")));
            } else {
                cq.orderBy(cb.desc(root.get("updatedAt")));
            }
        } else {
            cq.orderBy(cb.desc(root.get("updatedAt")));
        }

        return em.createQuery(cq)
                .setFirstResult(page * size)
                .setMaxResults(size)
                .getResultList();
    }

    @Transactional
    public void delete(Todo todo) {
        em.remove(em.contains(todo) ? todo : em.merge(todo));
    }
}
