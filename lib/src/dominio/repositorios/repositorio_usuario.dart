import '../entidades/usuario.dart';

abstract class RepositorioUsuario {
  Future<void> salvarUsuario(Usuario usuario);
  Stream<List<Usuario>> listarUsuarios();
}