package br.ucb.labbd.ToDoList.controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import br.ucb.labbd.ToDoList.services.UsuarioService;
import java.util.Map;

@RestController
@RequestMapping("/auth" )
@CrossOrigin(origins = "*")
public class AuthController {

    private final UsuarioService usuarioService;

    public AuthController(UsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {

        String token = usuarioService.login(req.getEmail(), req.getSenha());

        if (token == null) {
            return ResponseEntity
                .status(401)
                .body(Map.of("erro", "Login inválido"));
        }

        return ResponseEntity.ok(Map.of("token", token));
    }
    
    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestHeader(name = "X-Auth-Token", required = false) String token) {
    // Apenas retorna sucesso 204 para confirmar ao frontend
    return ResponseEntity.noContent().build();
}
}

class LoginRequest {
    private String email;
    private String senha;

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getSenha() { return senha; }
    public void setSenha(String senha) { this.senha = senha; }
}

