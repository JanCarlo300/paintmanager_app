import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/pdf_lista_materiais.dart';
import '../../../clientes/apresentacao/controllers/cliente_controller.dart';
import '../../../../core/pdf/pdf_service.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';

/// Etapa 6b — pergunta a observação (opcional), gera o PDF da Lista de
/// Materiais e abre o "compartilhar" do celular. Usado nos detalhes da obra
/// e logo depois de salvar uma obra com materiais.
/// Retorna true se o PDF foi gerado.
Future<bool> gerarECompartilharPdfListaMateriais(
  BuildContext context,
  Obra obra, {
  String titulo = 'PDF da Lista de Materiais',
  String rotuloCancelar = 'Cancelar',
}) async {
  final observacao = await showDialog<String>(
    context: context,
    builder: (_) => _DialogoObservacao(titulo: titulo, rotuloCancelar: rotuloCancelar),
  );
  if (observacao == null || !context.mounted) return false;

  final mensageiro = ScaffoldMessenger.of(context);
  final cores = context.cores;
  try {
    final cliente = obra.idCliente > 0
        ? await context.read<ClienteController>().buscarPorId(obra.idCliente)
        : null;
    final bytes = await gerarPdfListaMateriais(
      obra,
      clienteTelefone: cliente?.telefone ?? '',
      observacao: observacao,
    );
    await PdfService.compartilhar(
      bytes,
      'lista-materiais-${PdfService.nomeSeguro(obra.tituloDaObra)}.pdf',
    );
    return true;
  } catch (e) {
    mensageiro.showSnackBar(
      SnackBar(
        content: Text('Não foi possível gerar o PDF: $e', style: TextStyle(color: cores.onError)),
        backgroundColor: cores.error,
      ),
    );
    return false;
  }
}

class _DialogoObservacao extends StatefulWidget {
  const _DialogoObservacao({required this.titulo, required this.rotuloCancelar});
  final String titulo;
  final String rotuloCancelar;

  @override
  State<_DialogoObservacao> createState() => _DialogoObservacaoState();
}

class _DialogoObservacaoState extends State<_DialogoObservacao> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Observação (opcional)',
          hintText: 'Ex.: entregar até sexta',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.rotuloCancelar),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _controller.text),
          icon: const Icon(Symbols.picture_as_pdf_rounded, size: TamanhoIcone.pequeno),
          label: const Text('Gerar PDF'),
        ),
      ],
    );
  }
}
