package br.ucb.labbd.ToDoList.dao;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients; 
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import org.bson.Document;

import java.time.LocalDateTime;

public class AuditoriaMongo {
    private static final String HOST = "localhost";
    private static final int PORT = 27017;
    private static final String DATABASE = "logs_tarefas";

    public static void registrarAcao(String usuario, String acao, String detalhe) {
        // CORREÇÃO: Usar o método estático 'create' do MongoClients (API moderna)
        try (MongoClient mongoClient = MongoClients.create("mongodb://" + HOST + ":" + PORT)) {
            MongoDatabase db = mongoClient.getDatabase(DATABASE);
            MongoCollection<Document> collection = db.getCollection("auditoria");

            Document log = new Document("usuario", usuario)
                    .append("acao", acao)
                    .append("detalhe", detalhe)
                    .append("data", LocalDateTime.now().toString());

            collection.insertOne(log);
            System.out.println("Log inserido no MongoDB!");
        } catch (Exception e) {
            System.err.println("Erro ao conectar ou registrar no MongoDB: " + e.getMessage());
        }
    }
}
