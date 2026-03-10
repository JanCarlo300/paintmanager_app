import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/usuario.dart';

class UsuarioModelo extends Usuario {
  UsuarioModelo({
    super.id,
    required super.nome,
    required super.email,
    required super.cpf,
    required super.telefone,
    required super.funcao,
    super.status,
    required super.senha,
    super.primeiroAcesso, // null = primeiro acesso
    required super.criadoEm,
  });

  factory UsuarioModelo.deMapa(Map<String, dynamic> mapa, String id) {
    return UsuarioModelo(
      id: id,
      nome: mapa['nome'] ?? '',
      email: mapa['email'] ?? '',
      cpf: mapa['cpf'] ?? '',
      telefone: mapa['telefone'] ?? '',
      funcao: mapa['funcao'] ?? 'Funcionário',
      status: mapa['status'] ?? true,
      senha: mapa['senha'] ?? '',
      primeiroAcesso: mapa['primeiroAcesso'], // mantém null se não existir no Firestore
      criadoEm: (mapa['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // REMOVIDO @override: A entidade 'Usuario' em dominio não possui este método
  Map<String, dynamic> paraMapa() {
    return {
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
      'funcao': funcao,
      'status': status,
      'senha': senha,
      'primeiroAcesso': primeiroAcesso,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }
}