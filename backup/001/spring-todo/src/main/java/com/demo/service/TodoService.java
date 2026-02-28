package com.demo.service;

import com.demo.dto.CreateTodoRequest;
import com.demo.dto.PatchTodoRequest;
import com.demo.dto.TodoResponse;
import com.demo.dto.UpdateTodoRequest;
import com.demo.entity.Todo;
import com.demo.repository.TodoRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TodoService {

    private final TodoRepository todoRepository;

    public TodoService(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    @Transactional
    public TodoResponse create(CreateTodoRequest request) {
        Todo todo = new Todo();
        todo.setTitle(request.getTitle());
        todo.setDescription(request.getDescription());
        todo.setCompleted(request.getCompleted() != null ? request.getCompleted() : false);
        todo.setDueDate(request.getDueDate());

        todo = todoRepository.save(todo);
        return new TodoResponse(todo);
    }

    @Transactional(readOnly = true)
    public List<TodoResponse> findAll(Boolean completed, String query, int page, int size, String sort) {
        Specification<Todo> spec = Specification.where(null);

        if (completed != null) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.equal(root.get("completed"), completed));
        }

        if (query != null && !query.trim().isEmpty()) {
            spec = spec.and((root, criteriaQuery, cb) ->
                    cb.like(cb.lower(root.get("title")), "%" + query.toLowerCase() + "%"));
        }

        // Parse sort parameter (default: updatedAt,desc)
        Sort sortObj;
        if (sort != null && sort.contains("updatedAt")) {
            if (sort.contains("asc")) {
                sortObj = Sort.by(Sort.Direction.ASC, "updatedAt");
            } else {
                sortObj = Sort.by(Sort.Direction.DESC, "updatedAt");
            }
        } else {
            sortObj = Sort.by(Sort.Direction.DESC, "updatedAt");
        }

        Pageable pageable = PageRequest.of(page, size, sortObj);

        return todoRepository.findAll(spec, pageable)
                .stream()
                .map(TodoResponse::new)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public TodoResponse findById(UUID id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Todo not found with id: " + id));
        return new TodoResponse(todo);
    }

    @Transactional
    public TodoResponse update(UUID id, UpdateTodoRequest request) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Todo not found with id: " + id));

        todo.setTitle(request.getTitle());
        todo.setDescription(request.getDescription());
        todo.setCompleted(request.getCompleted());
        todo.setDueDate(request.getDueDate());

        todo = todoRepository.save(todo);
        return new TodoResponse(todo);
    }

    @Transactional
    public TodoResponse patch(UUID id, PatchTodoRequest request) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Todo not found with id: " + id));

        if (request.getTitle() != null) {
            todo.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            todo.setDescription(request.getDescription());
        }
        if (request.getCompleted() != null) {
            todo.setCompleted(request.getCompleted());
        }
        if (request.getDueDate() != null) {
            todo.setDueDate(request.getDueDate());
        }

        todo = todoRepository.save(todo);
        return new TodoResponse(todo);
    }

    @Transactional
    public void delete(UUID id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Todo not found with id: " + id));
        todoRepository.delete(todo);
    }
}
