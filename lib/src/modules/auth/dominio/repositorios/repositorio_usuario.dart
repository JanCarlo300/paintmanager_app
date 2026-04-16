import '../entidades/usuario.dart';

abstract class RepositorioUsuario {
  Future<void> salvarUsuario(Usuario usuario);
  Future<List<Usuario>> listarUsuarios();
}
