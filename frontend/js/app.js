const API = "http://localhost:8080";
let token = localStorage.getItem("token") || null;

async function login() {
    const email = document.getElementById("email").value;
    const senha = document.getElementById("senha").value;

    const res = await fetch(`${API}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, senha })
    });

    const result = await res.json();
    console.log("RESPOSTA LOGIN:", result);

    if (!res.ok) {
        alert(result.erro || "Erro no login");
        return;
    }

    token = result.token; 
    console.log("TOKEN SALVO:", token);
    localStorage.setItem("token", token);

    document.getElementById("login").style.display = "none";
    document.getElementById("app").style.display = "block";
    loadTasks();
}

async function logout() {
    await fetch(`${API}/auth/logout`, {
        method: "POST",
        headers: { "X-Auth-Token": token }
    });

    token = null;
    localStorage.removeItem("token");
    document.getElementById("login").style.display = "block";
    document.getElementById("app").style.display = "none";
}

async function loadTasks() {
    try {
        console.log("TOKEN ENVIADO:", token);

        const res = await fetch(`${API}/api/tarefas`, {
            method: "GET",
            headers: {
                "Accept": "application/json",
                "X-Auth-Token": token
            }
        });

        console.log("RESPOSTA STATUS:", res.status);
        if (!res.ok) {
            const text = await res.text();
            console.error("RESPOSTA DO BACKEND:", text);
            return;
        }

        const data = await res.json();
        const tarefas = Array.isArray(data) ? data : data.content;

        const ul = document.getElementById("lista");
        ul.innerHTML = "";

        tarefas.forEach(t => {
            const li = document.createElement("li");
            li.innerHTML = `
                <div class="task-info">
                    <strong>${t.titulo}</strong> - <span class="status">${t.status}</span> - <span class="priority">${t.prioridade}</span>
                    <div class="description">${t.descricao || 'Sem descrição'}</div>
                </div>
                <div class="task-buttons">
                    <button onclick="editTask('${t.idTarefa}')">Editar</button>
                    <button onclick="deleteTask('${t.idTarefa}')" class="delete">Excluir</button>
                </div>
            `;
            ul.appendChild(li);
        });

    } catch (error) {
        console.error("Erro ao carregar tarefas:", error);
    }
}

async function createTask() {
    const titulo = document.getElementById("titulo").value;
    const descricao = document.getElementById("descricao").value;
    const prioridade = document.getElementById("prioridade").value;

    await fetch(`${API}/api/tarefas`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "X-Auth-Token": token
        },
        body: JSON.stringify({ titulo, descricao, prioridade })
    });

    document.getElementById("titulo").value = "";
    document.getElementById("descricao").value = "";
    loadTasks();
}

async function editTask(id) {
    const novoTitulo = prompt("Novo título:");
    if (novoTitulo === null) return; // Se cancelar no primeiro prompt, sai

    const novaDescricao = prompt("Nova descrição:");
    if (novaDescricao === null) return; // Se cancelar, sai

    const novaPrioridade = prompt("Prioridade (BAIXA, MEDIA, ALTA):", "MEDIA");
    if (novaPrioridade === null) return; // Se cancelar, sai

    const novoStatus = prompt("Status (PENDENTE, EM_ANDAMENTO, CONCLUIDA):", "PENDENTE");
    if (novoStatus === null) return; // Se cancelar, sai


    const res = await fetch(`${API}/api/tarefas/${id}`, {
        method: "PUT",
        headers: {
            "Content-Type": "application/json",
            "X-Auth-Token": token
        },
        body: JSON.stringify({
            titulo: novoTitulo,
            descricao: novaDescricao,
            // CORREÇÃO 3: Enviando ENUMs em MAIÚSCULAS
            prioridade: novaPrioridade.toUpperCase(), 
            status: novoStatus.toUpperCase()
        })
    });

    if (!res.ok) {
        const result = await res.json().catch(() => ({erro: "Erro desconhecido ao editar."}));
        console.error("ERRO AO EDITAR TAREFA:", result);
        alert(result.erro || "Falha ao atualizar a tarefa. Verifique o console.");
        return; // Sai da função após o erro
    }

    loadTasks();
}

async function deleteTask(id) {
    if (!confirm("Deseja realmente excluir esta tarefa?")) return;

    await fetch(`${API}/api/tarefas/${id}`, {
        method: "DELETE",
        headers: { "X-Auth-Token": token }
    });

    loadTasks();
}

if (token) {
    document.getElementById("login").style.display = "none";
    document.getElementById("app").style.display = "block";
    loadTasks();
}
