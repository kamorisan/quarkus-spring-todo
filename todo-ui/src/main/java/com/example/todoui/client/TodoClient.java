package com.example.todoui.client;

import com.example.todoui.model.Todo;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import java.util.List;

@Path("/api/todos")
@RegisterRestClient(configKey = "com.example.todoui.client.TodoClient")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public interface TodoClient {

    @GET
    List<Todo> getAllTodos();

    @GET
    @Path("/{id}")
    Todo getTodoById(@PathParam("id") Long id);

    @POST
    Todo createTodo(Todo todo);

    @PUT
    @Path("/{id}")
    Todo updateTodo(@PathParam("id") Long id, Todo todo);

    @DELETE
    @Path("/{id}")
    void deleteTodo(@PathParam("id") Long id);
}
