package com.demo.service;

import com.demo.dto.CreateTodoRequest;
import com.demo.dto.PatchTodoRequest;
import com.demo.dto.TodoResponse;
import com.demo.dto.UpdateTodoRequest;
import com.demo.entity.Todo;
import com.demo.repository.TodoRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotFoundException;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
public class TodoService {

    @Inject
    TodoRepository todoRepository;

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

    public List<TodoResponse> findAll(Boolean completed, String query, int page, int size, String sort) {
        return todoRepository.findAll(completed, query, page, size, sort)
                .stream()
                .map(TodoResponse::new)
                .collect(Collectors.toList());
    }

    public TodoResponse findById(UUID id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Todo not found with id: " + id));
        return new TodoResponse(todo);
    }

    @Transactional
    public TodoResponse update(UUID id, UpdateTodoRequest request) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Todo not found with id: " + id));

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
                .orElseThrow(() -> new NotFoundException("Todo not found with id: " + id));

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
                .orElseThrow(() -> new NotFoundException("Todo not found with id: " + id));
        todoRepository.delete(todo);
    }
}
