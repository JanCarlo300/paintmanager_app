import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:paintmanager_app/src/core/pdf/pdf_service.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/entidades/item_material.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/entidades/obra.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/pdf_lista_materiais.dart';

Obra _obra(List<ItemMaterial> materiais) => Obra(
      idCliente: 1,
      clienteNome: 'José da Conceição',
      tituloDaObra: 'Pintura Externa — Casa Centro',
      endereco: 'Rua das Flores, 123 - Liberdade',
      dataInicio: DateTime(2026, 10, 15),
      dataPrevisaoTermino: DateTime(2026, 10, 30),
      etapasServico: const [],
      listaMateriais: materiais,
    );

void main() {
  // A fonte do PDF vem dos assets (rootBundle), que precisam do binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('gerarPdfListaMateriais', () {
    test('gera um PDF válido, com acentos e observação', () async {
      final bytes = await gerarPdfListaMateriais(
        _obra(const [
          ItemMaterial(descricao: 'Tinta acrílica fosca Coral', quantidade: 3, unidade: 'lata 18 L'),
          ItemMaterial(descricao: 'Lixa 180', quantidade: 2.5),
          ItemMaterial(descricao: 'Fita crepe'),
        ]),
        clienteTelefone: '(64) 99995-3540',
        observacao: 'Entregar até sexta, às 8h.',
        geradoEm: DateTime(2026, 10, 15, 20, 38),
      );

      expect(bytes.length, greaterThan(1000));
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('lista vazia também gera PDF (sem quebrar)', () async {
      final bytes = await gerarPdfListaMateriais(_obra(const []));
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('PdfService.nomeSeguro', () {
    test('tira acentos, espaços e símbolos do nome do arquivo', () {
      expect(PdfService.nomeSeguro('Pintura Externa — Casa Centro!'), 'pintura-externa-casa-centro');
      expect(PdfService.nomeSeguro('Ação Çé'), 'acao-ce');
      expect(PdfService.nomeSeguro('***'), 'documento');
    });
  });
}
