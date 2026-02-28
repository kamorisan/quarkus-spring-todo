// State
let editingTodoId = null;
let backendType = 'quarkus';

// API Base URL
const API_BASE = '/api';

// DOM Elements
const todoForm = document.getElementById('todo-form');
const todoList = document.getElementById('todo-list');
const loadingEl = document.getElementById('loading');
const errorMessageEl = document.getElementById('error-message');
const emptyStateEl = document.getElementById('empty-state');
const formTitle = document.getElementById('form-title');
const submitBtn = document.getElementById('submit-btn');
const cancelBtn = document.getElementById('cancel-btn');
const refreshBtn = document.getElementById('refresh-btn');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadBackendInfo();
    loadTodos();

    todoForm.addEventListener('submit', handleSubmit);
    cancelBtn.addEventListener('click', cancelEdit);
    refreshBtn.addEventListener('click', loadTodos);
});

// Load backend information
async function loadBackendInfo() {
    try {
        const response = await fetch(`${API_BASE}/backend/info`);
        const data = await response.json();
        backendType = data.type;

        const backendTypeBadge = document.getElementById('backend-type-badge');
        backendTypeBadge.textContent = `Backend: ${data.type.toUpperCase()}`;
        backendTypeBadge.classList.add(`badge-${data.type}`);

        // Check health
        checkBackendHealth();
    } catch (error) {
        console.error('Failed to load backend info:', error);
    }
}

// Check backend health
async function checkBackendHealth() {
    try {
        const response = await fetch(`${API_BASE}/backend/health`);
        const statusBadge = document.getElementById('backend-status-badge');

        if (response.ok) {
            statusBadge.textContent = 'Status: UP';
            statusBadge.classList.remove('badge-secondary', 'badge-danger');
            statusBadge.classList.add('badge-success');
        } else {
            statusBadge.textContent = 'Status: DOWN';
            statusBadge.classList.remove('badge-secondary', 'badge-success');
            statusBadge.classList.add('badge-danger');
        }
    } catch (error) {
        const statusBadge = document.getElementById('backend-status-badge');
        statusBadge.textContent = 'Status: ERROR';
        statusBadge.classList.remove('badge-secondary', 'badge-success');
        statusBadge.classList.add('badge-danger');
    }
}

// Load todos
async function loadTodos() {
    try {
        showLoading(true);
        hideError();

        const response = await fetch(`${API_BASE}/todos`);

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const todos = await response.json();
        renderTodos(todos);
    } catch (error) {
        showError(`Failed to load todos: ${error.message}`);
    } finally {
        showLoading(false);
    }
}

// Render todos
function renderTodos(todos) {
    todoList.innerHTML = '';

    if (todos.length === 0) {
        emptyStateEl.style.display = 'block';
        return;
    }

    emptyStateEl.style.display = 'none';

    todos.forEach(todo => {
        const todoItem = createTodoElement(todo);
        todoList.appendChild(todoItem);
    });
}

// Create todo element
function createTodoElement(todo) {
    const div = document.createElement('div');
    div.className = `todo-item ${todo.completed ? 'completed' : ''}`;

    div.innerHTML = `
        <div class="todo-header">
            <div class="todo-title">${escapeHtml(todo.title)}</div>
            <span class="todo-status ${todo.completed ? 'status-completed' : 'status-pending'}">
                ${todo.completed ? '✓ Completed' : 'Pending'}
            </span>
        </div>
        ${todo.description ? `<div class="todo-description">${escapeHtml(todo.description)}</div>` : ''}
        <div class="todo-actions">
            <button class="btn btn-edit" onclick="editTodo(${todo.id})">Edit</button>
            <button class="btn btn-danger" onclick="deleteTodo(${todo.id})">Delete</button>
        </div>
    `;

    return div;
}

// Handle form submit
async function handleSubmit(e) {
    e.preventDefault();

    const title = document.getElementById('todo-title').value.trim();
    const description = document.getElementById('todo-description').value.trim();
    const completed = document.getElementById('todo-completed').checked;

    if (!title) {
        showError('Title is required');
        return;
    }

    const todo = {
        title,
        description: description || null,
        completed
    };

    try {
        hideError();

        if (editingTodoId) {
            await updateTodo(editingTodoId, todo);
        } else {
            await createTodo(todo);
        }

        resetForm();
        loadTodos();
    } catch (error) {
        showError(`Failed to save todo: ${error.message}`);
    }
}

// Create todo
async function createTodo(todo) {
    const response = await fetch(`${API_BASE}/todos`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(todo)
    });

    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }

    return response.json();
}

// Update todo
async function updateTodo(id, todo) {
    const response = await fetch(`${API_BASE}/todos/${id}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(todo)
    });

    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }

    return response.json();
}

// Edit todo
async function editTodo(id) {
    try {
        const response = await fetch(`${API_BASE}/todos/${id}`);

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const todo = await response.json();

        editingTodoId = id;
        document.getElementById('todo-id').value = id;
        document.getElementById('todo-title').value = todo.title;
        document.getElementById('todo-description').value = todo.description || '';
        document.getElementById('todo-completed').checked = todo.completed;

        formTitle.textContent = 'Edit Todo';
        submitBtn.textContent = 'Update Todo';
        cancelBtn.style.display = 'inline-block';

        // Scroll to form
        document.querySelector('.form-section').scrollIntoView({ behavior: 'smooth' });
    } catch (error) {
        showError(`Failed to load todo: ${error.message}`);
    }
}

// Delete todo
async function deleteTodo(id) {
    if (!confirm('Are you sure you want to delete this todo?')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/todos/${id}`, {
            method: 'DELETE'
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        loadTodos();
    } catch (error) {
        showError(`Failed to delete todo: ${error.message}`);
    }
}

// Cancel edit
function cancelEdit() {
    resetForm();
}

// Reset form
function resetForm() {
    editingTodoId = null;
    todoForm.reset();
    document.getElementById('todo-id').value = '';
    formTitle.textContent = 'Create New Todo';
    submitBtn.textContent = 'Create Todo';
    cancelBtn.style.display = 'none';
}

// Show/hide loading
function showLoading(show) {
    loadingEl.style.display = show ? 'block' : 'none';
    todoList.style.display = show ? 'none' : 'block';
}

// Show error
function showError(message) {
    errorMessageEl.textContent = message;
    errorMessageEl.style.display = 'block';
}

// Hide error
function hideError() {
    errorMessageEl.style.display = 'none';
}

// Escape HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
