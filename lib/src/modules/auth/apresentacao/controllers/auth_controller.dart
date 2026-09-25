import 'dart:async';
import 'package:flutter/material.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_autenticacao.dart';
import '../../dominio/validador_senha.dart';
import '../../../../core/tema/paleta_sahara.dart';

/// Rota inicial de cada função, usada logo após o login e pelo AuthCheck
/// ao reabrir o app com uma sessão já existente.
String rotaInicialParaFuncao(String funcao) =>
    funcao == 'Funcionário' ? '/obras' : '/home';

class AuthController extends ChangeNotifier {
  final RepositorioAutenticacao _repositorio;
  StreamSubscription<Usuario?>? _usuarioSub;

  AuthController(this._repositorio) {
    // Mantém o usuário logado em cache, para checagem de permissão
    // síncrona (context.watch) em qualquer tela, sem precisar de
    // StreamBuilder espalhado pelo app.
    _usuarioSub = _repositorio.usuarioAtual.listen((usuario) {
      _usuarioLogado = usuario;
      notifyListeners();
    });
  }

  bool _carregando = false;
  bool get carregando => _carregando;

  // --- SESSÃO PERSISTENTE ---
  Stream<Usuario?> get usuarioAtual => _repositorio.usuarioAtual;

  Usuario? _usuarioLogado;
  Usuario? get usuarioLogado => _usuarioLogado;

  @override
  void dispose() {
    _usuarioSub?.cancel();
    super.dispose();
  }

  // RF001 - Realizar Login com Verificação de Primeiro Acesso
  Future<void> realizarLogin(BuildContext context, String cpf, String senha) async {
    if (cpf.isEmpty || senha.isEmpty) {
      _mostrarMensagem(context, "Preencha todos os campos.");
      return;
    }

    _carregando = true;
    notifyListeners();

    try {
      print("Tentando realizar login com CPF: $cpf");
      final usuario = await _repositorio.entrarComCpfESenha(cpf, senha);
      print("Resultado do login: $usuario");

      if (usuario != null && context.mounted) {
        // Todo usuário no primeiro acesso é obrigado a trocar a senha,
        // inclusive administrador (RF002 - sem isenção por função).
        if (usuario.primeiroAcesso) {
          print("Redirecionando para redefinir senha");
          Navigator.of(context).pushReplacementNamed('/redefinir-senha-obrigatoria');
        } else {
          print("Redirecionando para ${rotaInicialParaFuncao(usuario.funcao)}");
          Navigator.of(context).pushReplacementNamed(rotaInicialParaFuncao(usuario.funcao));
        }
      }
    } catch (e) {
      print("Erro no login recebido pelo controller: $e");
      if (context.mounted) {
        final mensagemErro = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', '');
        _mostrarMensagem(context, mensagemErro, isErro: true);
      }
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // === RF002 - RECUPERAÇÃO DE SENHA (fluxo de 3 passos) ===

  /// E-mail resolvido a partir do CPF/e-mail informado no passo 1.
  /// Pode ficar `null` se o login não existir — propositalmente não
  /// revelamos isso na UI, para não expor quais CPFs estão cadastrados.
  String? _emailRecuperacao;

  /// Passo 1: resolve o CPF/e-mail informado e dispara o código por e-mail.
  Future<void> solicitarCodigoRecuperacao(String cpfOuEmail) async {
    _carregando = true;
    notifyListeners();
    try {
      final email = await _repositorio.buscarEmailPorLogin(cpfOuEmail.trim());
      _emailRecuperacao = email;
      if (email != null) {
        await _repositorio.recuperarSenha(email);
      }
      // Se não encontrou, não fazemos nada aqui de propósito: a tela
      // sempre avança e mostra a mesma mensagem genérica, para não
      // revelar se o CPF/e-mail existe no sistema.
    } catch (_) {
      // Erro técnico de envio: também tratado em silêncio por segurança,
      // a tela segue com a mesma mensagem genérica.
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Passo 2: verifica o código recebido por e-mail.
  Future<bool> verificarCodigoRecuperacao(BuildContext context, String codigo) async {
    if (_emailRecuperacao == null) {
      // Login do passo 1 não existia: o código nunca vai ser válido.
      _mostrarMensagem(context, "Código inválido. Verifique e tente novamente.");
      return false;
    }

    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.verificarCodigoRecuperacao(_emailRecuperacao!, codigo.trim());
      return true;
    } catch (e) {
      if (context.mounted) _mostrarMensagem(context, e.toString());
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Passo 3 (RF002) e troca obrigatória do primeiro acesso: define a nova
  /// senha para o usuário já autenticado (por login normal ou pelo código
  /// de recuperação verificado no passo 2).
  Future<bool> definirNovaSenha(BuildContext context, String novaSenha, String confirmacao) async {
    _carregando = true;
    notifyListeners();
    try {
      final cpf = await _repositorio.buscarCpfUsuarioLogado();
      final erro = ValidadorSenha.validar(novaSenha, confirmacao, cpf: cpf);
      if (erro != null) {
        if (context.mounted) _mostrarMensagem(context, erro);
        return false;
      }

      await _repositorio.definirNovaSenha(novaSenha);
      _emailRecuperacao = null;
      return true;
    } catch (e) {
      if (context.mounted) _mostrarMensagem(context, e.toString(), isErro: true);
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // Logout do Sistema
  Future<void> sair() async {
    await _repositorio.sair();
    notifyListeners();
  }

  void _mostrarMensagem(BuildContext context, String mensagem, {bool isErro = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? Colors.red : PaletaSahara.onSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
