import '../../dominio/entidades/cliente.dart';

class ClienteModel extends Cliente {
  ClienteModel({
    super.id,
    required super.nome,
    required super.telefone,
    super.email,
    super.endereco,
  });

  // Converte Map do Firestore para o Modelo
  factory ClienteModel.fromMap(Map<String, dynamic> mapa, String id) {
    return ClienteModel(
      id: id,
      nome: mapa['nome'] ?? '',
      telefone: mapa['telefone'] ?? '',
      email: mapa['email'],
      endereco: mapa['endereco'],
    );
  }

  // Converte o Modelo para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
    };
  }
}
