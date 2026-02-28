package com.example.todoui.resource;

import com.example.todoui.client.TodoClient;
import com.example.todoui.model.Todo;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.rest.client.inject.RestClient;

import java.util.List;

@Path("/api/todos")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class TodoUIResource {

    @Inject
    @RestClient
    TodoClient todoClient;

    @GET
    public List<Todo> getAllTodos() {
        return todoClient.getAllTodos();
    }

    @GET
    @Path("/{id}")
    public Todo getTodoById(@PathParam("id") Long id) {
        return todoClient.getTodoById(id);
    }

    @POST
    public Response createTodo(Todo todo) {
        Todo created = todoClient.createTodo(todo);
        return Response.status(Response.Status.CREATED).entity(created).build();
    }

    @PUT
    @Path("/{id}")
    public Todo updateTodo(@PathParam("id") Long id, Todo todo) {
        return todoClient.updateTodo(id, todo);
    }

    @DELETE
    @Path("/{id}")
    public Response deleteTodo(@PathParam("id") Long id) {
        todoClient.deleteTodo(id);
        return Response.status(Response.Status.NO_CONTENT).build();
    }
}
