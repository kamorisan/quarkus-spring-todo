package com.demo.controller;

import com.demo.dto.CreateTodoRequest;
import com.demo.dto.PatchTodoRequest;
import com.demo.dto.TodoResponse;
import com.demo.dto.UpdateTodoRequest;
import com.demo.service.TodoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/todos")
@Tag(name = "Todo", description = "Todo CRUD operations")
public class TodoController {

    private final TodoService todoService;

    public TodoController(TodoService todoService) {
        this.todoService = todoService;
    }

    @PostMapping
    @Operation(summary = "Create a new todo")
    public ResponseEntity<TodoResponse> create(@Valid @RequestBody CreateTodoRequest request) {
        TodoResponse response = todoService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    @Operation(summary = "Get all todos")
    public ResponseEntity<List<TodoResponse>> getAll(
            @RequestParam(required = false) Boolean completed,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "updatedAt,desc") String sort) {
        List<TodoResponse> todos = todoService.findAll(completed, q, page, size, sort);
        return ResponseEntity.ok(todos);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a todo by ID")
    public ResponseEntity<TodoResponse> getById(@PathVariable UUID id) {
        TodoResponse response = todoService.findById(id);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a todo")
    public ResponseEntity<TodoResponse> update(@PathVariable UUID id, @Valid @RequestBody UpdateTodoRequest request) {
        TodoResponse response = todoService.update(id, request);
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/{id}")
    @Operation(summary = "Partially update a todo")
    public ResponseEntity<TodoResponse> patch(@PathVariable UUID id, @Valid @RequestBody PatchTodoRequest request) {
        TodoResponse response = todoService.patch(id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a todo")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        todoService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
