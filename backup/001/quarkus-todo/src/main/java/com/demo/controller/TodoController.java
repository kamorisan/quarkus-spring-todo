package com.demo.controller;

import com.demo.dto.CreateTodoRequest;
import com.demo.dto.PatchTodoRequest;
import com.demo.dto.TodoResponse;
import com.demo.dto.UpdateTodoRequest;
import com.demo.service.TodoService;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;
import java.util.UUID;

@Path("/api/todos")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Todo", description = "Todo CRUD operations")
public class TodoController {

    @Inject
    TodoService todoService;

    @POST
    @Operation(summary = "Create a new todo")
    public Response create(@Valid CreateTodoRequest request) {
        TodoResponse response = todoService.create(request);
        return Response.status(Response.Status.CREATED).entity(response).build();
    }

    @GET
    @Operation(summary = "Get all todos")
    public List<TodoResponse> getAll(
            @QueryParam("completed") Boolean completed,
            @QueryParam("q") String query,
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("20") int size,
            @QueryParam("sort") @DefaultValue("updatedAt,desc") String sort) {
        return todoService.findAll(completed, query, page, size, sort);
    }

    @GET
    @Path("/{id}")
    @Operation(summary = "Get a todo by ID")
    public TodoResponse getById(@PathParam("id") UUID id) {
        return todoService.findById(id);
    }

    @PUT
    @Path("/{id}")
    @Operation(summary = "Update a todo")
    public TodoResponse update(@PathParam("id") UUID id, @Valid UpdateTodoRequest request) {
        return todoService.update(id, request);
    }

    @PATCH
    @Path("/{id}")
    @Operation(summary = "Partially update a todo")
    public TodoResponse patch(@PathParam("id") UUID id, @Valid PatchTodoRequest request) {
        return todoService.patch(id, request);
    }

    @DELETE
    @Path("/{id}")
    @Operation(summary = "Delete a todo")
    public Response delete(@PathParam("id") UUID id) {
        todoService.delete(id);
        return Response.noContent().build();
    }
}
