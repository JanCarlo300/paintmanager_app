import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/cliente.dart';

class ClienteModelo extends Cliente {
  ClienteModelo({
    super.id,
    required super.nome,
    required super.email,
    required super.telefone,
    required super.endereco,
    required super.cpfOuCnpj,
    required super.criadoEm,
    super.ativo = true,
  });

  factory ClienteModelo.deMapa(Map<String, dynamic> mapa, String id) {
    return ClienteModelo(
      id: id,
      nome: mapa['nome'] ?? '',
      email: mapa['email'] ?? '',
      telefone: mapa['telefone'] ?? '',
      endereco: mapa['endereco'] ?? '',
      cpfOuCnpj: mapa['cpfOuCnpj'] ?? '',
      criadoEm: (mapa['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ativo: mapa['ativo'] ?? true,
    );
  }

  Map<String, dynamic> paraMapa() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'endereco': endereco,
      'cpfOuCnpj': cpfOuCnpj,
      'criadoEm': Timestamp.fromDate(criadoEm),
      'ativo': ativo,
    };
  }
}