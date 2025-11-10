DROP DATABASE IF EXISTS ToDoList;
CREATE DATABASE ToDoList;
USE ToDoList;

CREATE TABLE grupos_usuarios (
	id_grupo VARCHAR(20) PRIMARY KEY,
	nome VARCHAR(50) NOT NULL UNIQUE,
    descricao VARCHAR(255)
);

CREATE TABLE usuarios (
	id_usuario VARCHAR(20) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    id_grupo VARCHAR(20) NOT NULL,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_usuarios_grupo
    FOREIGN KEY (id_grupo) REFERENCES grupos_usuarios(id_grupo)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);

CREATE INDEX index_usuario_email ON usuarios(email);

CREATE TABLE tarefas (
	id_tarefa VARCHAR(15) PRIMARY KEY,
    id_usuario VARCHAR(20) NOT NULL, 
    titulo VARCHAR(150) NOT NULL,
    descricao TEXT,
    prioridade ENUM('Baixa', 'Média', 'Alta') DEFAULT 'Média',
    status ENUM('Pendente', 'Em Andamento', 'Concluída') DEFAULT 'Pendente',
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_vencimento DATETIME NULL,
    data_conclusao DATETIME NULL,
    CONSTRAINT fk_tarefas_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE INDEX index_tarefa_usuario_status ON tarefas(id_usuario, status);
CREATE INDEX index_tarefa_vencimento ON tarefas(data_vencimento);

CREATE TABLE tags (
	id_tag VARCHAR(10) PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE tarefas_tags (
    id_tarefa VARCHAR(10) NOT NULL,
    id_tag VARCHAR(10) NOT NULL,
    PRIMARY KEY (id_tarefa, id_tag),
    FOREIGN KEY (id_tarefa) REFERENCES tarefas(id_tarefa)
	ON DELETE CASCADE,
	FOREIGN KEY (id_tag) REFERENCES tags(id_tag)
	ON DELETE RESTRICT
);

CREATE TABLE subtarefas (
	id_subtarefa VARCHAR(15) PRIMARY KEY,	
    id_tarefa VARCHAR(15) NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    status ENUM('Pendente', 'Concluída') DEFAULT 'Pendente',
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_conclusao DATETIME NULL,
    CONSTRAINT fk_subtarefa_tarefa
    FOREIGN KEY (id_tarefa) REFERENCES tarefas(id_tarefa)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE INDEX index_subtarefa_tarefa ON subtarefas(id_tarefa);

CREATE TABLE auditoria (
	id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario VARCHAR(20) NULL,
    acao VARCHAR(255) NOT NULL,
    detalhes TEXT NULL,
    data_log DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auditoria_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

CREATE INDEX index_auditoria_data ON auditoria(data_log);

DELIMITER //
CREATE FUNCTION gerar_id_unico(prefixo VARCHAR(10), tabela_nome VARCHAR(64))
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE novo_id VARCHAR(20);
    DECLARE ultimo_numero INT;

	IF tabela_nome = 'tarefas' THEN
		SELECT COALESCE(MAX(CAST(SUBSTRING(id_tarefa, LENGTH(prefixo) + 2) AS UNSIGNED)), 0)
    	INTO ultimo_numero
    	FROM tarefas;
	ELSEIF tabela_nome = 'usuarios' THEN
		SELECT COALESCE(MAX(CAST(SUBSTRING(id_usuario, LENGTH(prefixo) + 2) AS UNSIGNED)), 0)
    	INTO ultimo_numero
    	FROM usuarios;
	ELSEIF tabela_nome = 'tags' THEN
		SELECT COALESCE(MAX(CAST(SUBSTRING(id_tag, LENGTH(prefixo) + 2) AS UNSIGNED)), 0)
    	INTO ultimo_numero
    	FROM tags;
	ELSEIF tabela_nome = 'grupos_usuarios' THEN
		SELECT COALESCE(MAX(CAST(SUBSTRING(id_grupo, LENGTH(prefixo) + 2) AS UNSIGNED)), 0)
    	INTO ultimo_numero
    	FROM grupos_usuarios;
	ELSEIF tabela_nome = 'subtarefas' THEN
		SELECT COALESCE(MAX(CAST(SUBSTRING(id_subtarefa, LENGTH(prefixo) + 2) AS UNSIGNED)), 0)
    	INTO ultimo_numero
    	FROM subtarefas;
	ELSE
		SET ultimo_numero = 0;
	END IF;
    
    SET novo_id = CONCAT(prefixo, '-', LPAD(ultimo_numero + 1, 5, '0'));
    RETURN novo_id;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE sp_criar_tarefa (
	IN p_id_usuario VARCHAR(20),
    IN p_titulo VARCHAR(150),
    IN p_descricao TEXT,
    IN p_prioridade ENUM('Baixa', 'Média', 'Alta')
)
BEGIN
	INSERT INTO tarefas (id_tarefa, id_usuario, titulo, descricao, prioridade)
    VALUES (gerar_id_unico('TAR', 'tarefas'), p_id_usuario, p_titulo, p_descricao, p_prioridade);
END //
DELIMITER ;


CREATE VIEW view_tarefas_pendentes AS
SELECT
	t.id_tarefa,
    t.titulo,
    t.prioridade,
    t.status,
    t.data_vencimento,
    u.nome AS usuario_responsavel
FROM tarefas t
JOIN usuarios u ON u.id_usuario = t.id_usuario
WHERE t.status <> 'Concluída';


CREATE VIEW view_subtarefas_pendentes AS
SELECT
	t.titulo AS Tarefa_Principal,
    s.titulo AS Subtarefa,
    u.nome AS Usuario_Responsavel
FROM subtarefas s
JOIN tarefas t ON t.id_tarefa = s.id_tarefa
JOIN usuarios u ON u.id_usuario = t.id_usuario
WHERE s.status = 'Pendente';


DELIMITER //
CREATE TRIGGER trg_tarefa_concluida
BEFORE UPDATE ON tarefas
FOR EACH ROW
BEGIN
	IF NEW.status = 'Concluída' AND OLD.status <> 'Concluída' THEN
		SET NEW.data_conclusao = NOW();
	END IF;
END //
DELIMITER ;


DELIMITER //
DROP TRIGGER IF EXISTS trg_subtarefa_concluida //
CREATE TRIGGER trg_subtarefa_concluida
AFTER UPDATE ON subtarefas
FOR EACH ROW
BEGIN
	DECLARE total INT;
    DECLARE concluidas INT;
    
    SELECT COUNT(*) INTO total FROM subtarefas WHERE id_tarefa = NEW.id_tarefa;
    SELECT COUNT(*) INTO concluidas FROM subtarefas WHERE id_tarefa = NEW.id_tarefa AND status = 'Concluída';
    
    IF total = concluidas THEN
		UPDATE tarefas SET status = 'Concluída', data_conclusao = NOW()
    	WHERE id_tarefa = NEW.id_tarefa;
	END IF;
END //
DELIMITER ;


ALTER TABLE subtarefas MODIFY COLUMN status VARCHAR(255) NOT NULL;

ALTER TABLE tarefas
MODIFY prioridade ENUM('BAIXA', 'MEDIA', 'ALTA') DEFAULT 'MEDIA';

ALTER TABLE tarefas
MODIFY status ENUM('PENDENTE', 'EM_ANDAMENTO', 'CONCLUIDA') DEFAULT 'PENDENTE';

ALTER TABLE usuarios ADD COLUMN data_nasc DATE NULL;

INSERT INTO grupos_usuarios (id_grupo, nome, descricao)
VALUES(gerar_id_unico('GRP','grupos_usuarios'),'Administrador','Acesso total'),
(gerar_id_unico('GRP','grupos_usuarios'),'Comum','Acesso limitado');

-- USUÁRIO DE TESTE 
-- Email: teste.sucesso@ucb.br 
-- Senha: minhasenha
INSERT INTO usuarios (id_usuario, id_grupo, nome, email, senha_hash)
VALUES(gerar_id_unico('USR','usuarios'), 'GRP-00002', 'Usuário de Teste', 'teste.sucesso@ucb.br', '$2a$10$ddnjrWaQHW1xB6sM2.NIM.ApoxwEnCpfRr/DPPTc3leXrD5PAnwlW');

-- Criação de usuário de acesso, sem ser root
CREATE USER IF NOT EXISTS 'daphne_admin'@'localhost' IDENTIFIED BY 'senha123';
GRANT SELECT, INSERT, UPDATE, DELETE ON ToDoList.* TO 'daphne_admin'@'localhost';
FLUSH PRIVILEGES;