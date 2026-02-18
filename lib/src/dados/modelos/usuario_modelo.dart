import '../../dominio/entidades/usuario.dart';

class UsuarioModelo extends Usuario {
  UsuarioModelo({
    required super.id,
    required super.nome,
    required super.email,
    required super.cpf,
    required super.tipo,
    super.estaAtivo,
  });

  /// Converte um Documento do Firestore (Map) para o nosso UsuarioModelo.
  /// O [id] geralmente vem separado dos dados (mapa) no Firestore.
  factory UsuarioModelo.deMapa(Map<String, dynamic> mapa, String id) {
    return UsuarioModelo(
      id: id,
      nome: mapa['nome'] ?? '',
      email: mapa['email'] ?? '',
      cpf: mapa['cpf'] ?? '',
      // Converte a String do banco de volta para o Enum do domínio
      tipo: TipoUsuario.values.firstWhere(
        (e) => e.toString().split('.').last == mapa['tipo'],
        orElse: () => TipoUsuario.funcionario,
      ),
      estaAtivo: mapa['estaAtivo'] ?? true,
    );
  }

  /// Converte o nosso modelo para um Mapa para ser salvo no Firestore.
  Map<String, dynamic> paraMapa() {
    return {
      'nome': nome,
      'email': email,
      'cpf': cpf,
      // Salva apenas o nome do Enum (ex: 'administrador')
      'tipo': tipo.toString().split('.').last,
      'estaAtivo': estaAtivo,
    };
  }
}
