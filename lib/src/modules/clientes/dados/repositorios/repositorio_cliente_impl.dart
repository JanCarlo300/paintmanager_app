import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../dominio/entidades/cliente.dart';
import '../../dominio/repositorios/repositorio_cliente.dart';
import '../modelos/cliente_modelo.dart';

/// Implementação do repositório de Clientes usando Supabase (PostgreSQL).
/// Todas as operações usam métodos nativos do SupabaseClient.
class RepositorioClienteImpl implements RepositorioCliente {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<List<Cliente>> listarClientes() async {
    try {
      final resultado = await _supabase
          .from('cliente')
          .select()
          .order('nome', ascending: true);

      final List<Cliente> clientes = [];
      for (var mapa in (resultado as List)) {
        try {
          clientes.add(ClienteModelo.deMapa(mapa));
        } catch (e, stackTrace) {
          // Captura a falha silenciosa: imprime exatamente qual registro falhou na conversão
          print('=====================================');
          print('ERRO FATAL DE PARSING NO CLIENTE:');
          print('Payload: $mapa');
          print('Exceção: $e');
          print('Stack: $stackTrace');
          print('=====================================');
        }
      }
      return clientes;
    } catch (e, stackTrace) {
      print('Erro de rede ou query listarClientes: $e\\n$stackTrace');
      throw 'Erro ao listar clientes: $e';
    }
  }

  @override
  Future<void> salvarCliente(Cliente cliente) async {
    try {
      final modelo = ClienteModelo(
        id: cliente.id,
        nome: cliente.nome,
        email: cliente.email,
        telefone: cliente.telefone,
        endereco: cliente.endereco,
        cpfOuCnpj: cliente.cpfOuCnpj,
        ativo: cliente.ativo,
        criadoEm: cliente.criadoEm,
      );

      if (cliente.id == null) {
        // INSERT — novo cliente
        await _supabase.from('cliente').insert(modelo.paraMapa());
      } else {
        // UPDATE — cliente existente
        await _supabase
            .from('cliente')
            .update(modelo.paraMapa())
            .eq('id_cliente', cliente.id!);
      }
    } catch (e) {
      throw 'Erro ao salvar cliente: $e';
    }
  }

  @override
  Future<void> excluirCliente(int id) async {
    try {
      await _supabase.from('cliente').delete().eq('id_cliente', id);
    } catch (e) {
      throw 'Erro ao excluir cliente: $e';
    }
  }

  @override
  Future<void> atualizarStatus(int id, bool ativo) async {
    try {
      await _supabase
          .from('cliente')
          .update({'status': ativo})
          .eq('id_cliente', id);
    } catch (e) {
      throw 'Erro ao atualizar status do cliente: $e';
    }
  }
}
